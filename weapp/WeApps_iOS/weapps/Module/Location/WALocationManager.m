//
//  WALocationManager.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALocationManager.h"
#import "AuthorizationCheck.h"
#import "WAWeakProxy.h"
#import "LocationCoordinate2DExchanger.h"
#import "EventListenerList.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CLBeacon (Object)

- (NSDictionary *)toDict;

@end

@implementation CLBeacon (Object)

- (NSDictionary *)toDict
{
    NSString *uuidString = nil;
    if (@available(iOS 13.0, *)) {
        uuidString = [self.UUID UUIDString];
    } else {
        uuidString = [self.proximityUUID UUIDString];
    }
    NSDictionary *dic = @{
        @"uuid"     : uuidString ?: @"",
        @"major"    : self.major ?: @(0),
        @"minor"    : self.minor ?: @(0),
        @"proximity": @(self.proximity),
        @"accuracy" : @(self.accuracy),
        @"rssi"     : @(self.rssi)
    };
    return dic;
}

@end


@implementation WALocationModel

- (void)setLocation:(CLLocation *)location
{
    _location = location;
    _marsCoordinate = [LocationCoordinate2DExchanger WGSToGCJ:location.coordinate];
}


@end

@class LocationInfoItem;

@protocol LocationInfoItemCountDownProtocol <NSObject>

- (void)locationInfoItemDidEndCountDown:(LocationInfoItem *)item;

@end

@interface LocationInfoItem : NSObject

/// 回调
@property (nonatomic, copy) void(^callback)(WALocationModel *location, NSError *error);

/// 是否开启高精度
@property (nonatomic, assign) BOOL isHighAccuracy;

/// 位置类型  wgs84 | gcj02
@property (nonatomic, copy) NSString *type;

/// 超时时间（毫秒）
@property (nonatomic, assign) NSUInteger highAccuracyExpireTime;

/// 最高进度位置
@property (nonatomic, strong) CLLocation *bestLocation;

@property (nonatomic, weak) id<LocationInfoItemCountDownProtocol> delegate;


/// 开启倒计时
- (void)startCountDown;


/// 更新位置信息，取精度较高的为准
/// @param location 位置
- (void)updateLocation:(CLLocation *)location;


/// 完成回调
- (void)doCallback;

@end

@implementation LocationInfoItem

- (void)startCountDown
{
    //若非高精度定位，则获取到一次位置后就WALocationManager结束
    if (!_isHighAccuracy) {
        return;
    }
    //高精度定位，时间结束后通知delegate，由delegate结束
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, _highAccuracyExpireTime * NSEC_PER_MSEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if ([self.delegate respondsToSelector:@selector(locationInfoItemDidEndCountDown:)]) {
            [self.delegate locationInfoItemDidEndCountDown:self];
        }
    });
}

- (void)updateLocation:(CLLocation *)location
{
    if (!self.bestLocation) {
        self.bestLocation = location;
    } else {
        if (self.bestLocation.horizontalAccuracy > location.horizontalAccuracy) {
            self.bestLocation = location;
        }
    }
}

- (void)doCallback
{
    if (!self.callback) {
        return;
    }
    if (!self.bestLocation) {
        self.callback(nil, [NSError errorWithDomain:@"getLocation" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"get location timeout"}]);
    } else {
        WALocationModel *model = [[WALocationModel alloc] init];
        model.location = self.bestLocation;
        self.callback(model, nil);
    }
    
}

@end


@interface WALocationManager () <CLLocationManagerDelegate,CBCentralManagerDelegate , LocationInfoItemCountDownProtocol>

@property (nonatomic, strong) EventListenerList *listeners;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isUpdateLocation;
@property (nonatomic, strong) NSMutableArray <LocationInfoItem *>* items;

//******************iBeacon*********************
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, copy) void(^startDiscoveryBlock)(BOOL success, NSError *error);
@property (nonatomic, strong) NSArray <NSUUID *>*startDiscoveryDeviceUUIDS;
@property (nonatomic, strong) NSArray <CLBeaconRegion *> *regions;
@property (nonatomic, strong) NSArray *constraints;
@property (nonatomic, strong) NSMutableDictionary *beacons;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong) NSMutableDictionary *beaconServiceChangeDict;
@property (nonatomic, strong) NSMutableDictionary *beaconUpdateDict;

@end

@implementation WALocationManager

#pragma mark - Life Cycle
+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static WALocationManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initInPrivate];
    });
    return instance;
}


- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.pausesLocationUpdatesAutomatically = YES;
        [_locationManager requestAlwaysAuthorization];
    }
    return _locationManager;;
}

- (instancetype)initInPrivate {
    self = [super init];
    if (self) {
        _isUpdateLocation = NO;
        _listeners = [[EventListenerList alloc] init];
        _items = [NSMutableArray array];
        _beacons = [NSMutableDictionary dictionary];
        _beaconUpdateDict = [NSMutableDictionary dictionary];
        _beaconServiceChangeDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)startLocationUpdateWithCompletion:(void(^)(BOOL success, NSError *error))completion
{
    if (![AuthorizationCheck locationAuthorizationCheck]) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"startLocationUpdate" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"location permission deny"}]);
        }
    }
    [self.lock lock];
    [self.locationManager startUpdatingLocation];
    _isUpdateLocation = YES;
    [self.lock unlock];
    if (completion) {
        completion(YES, nil);
    }
}

- (void)stopLocationUpdate
{
    [self.lock lock];
    if (_items.count == 0) {
        [self.locationManager stopUpdatingLocation];
    }
    _isUpdateLocation = NO;
    [self.lock unlock];
}

- (void)getLocationWithType:(NSString *)type
             isHighAccuracy:(BOOL)isHighAccuracy
     highAccuracyExpireTime:(NSTimeInterval)highAccuracyExpireTime
                 completion:(void(^)(WALocationModel *location, NSError *error))completion
{
    [self.lock lock];
    LocationInfoItem *item = [[LocationInfoItem alloc] init];
    item.isHighAccuracy = isHighAccuracy;
    item.highAccuracyExpireTime = highAccuracyExpireTime;
    item.callback = completion;
    item.type = type;
    item.delegate = self;
    [item startCountDown];
    //开启高精度定位
    [self.locationManager stopUpdatingLocation];
    if (isHighAccuracy) {

        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        WALOG(@"开启高精度定位")
    }
    [self.locationManager startUpdatingLocation];
    [_items addObject:item];
    [self.lock unlock];
    
}

- (void)addLocationListener:(id<WALocationManagerProtocol>)listener
{
    [_listeners addListener:listener];
}

- (void)removeLocationListener:(id<WALocationManagerProtocol>)listener
{
    [_listeners removeListener:listener];
}


#pragma mark LocationInfoItemCountDownProtocol
- (void)locationInfoItemDidEndCountDown:(LocationInfoItem *)item
{
    //高精度item超时后回调callback，并被删除
    [self.lock lock];
    [item doCallback];
    [_items removeObject:item];
    
    if (!_isUpdateLocation && _items.count == 0) {
        //无定位要求，关闭定位
        [self.locationManager stopUpdatingLocation];
        WALOG(@"无定位要求，关闭定位")
    } else if ((!_isUpdateLocation && _items.count != 0) || _isUpdateLocation){
        //若无高精度需求，改为一般精度
          BOOL containHighAccuracy = NO;
          for (LocationInfoItem *lcItem in _items) {
              if (lcItem.isHighAccuracy) {
                  containHighAccuracy = YES;
                  break;
              }
          }
          if (containHighAccuracy == 0) {
              [self.locationManager stopUpdatingLocation];
              self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
              [self.locationManager startUpdatingLocation];
              WALOG(@"无高精度需求，改为一般精度")
          }
    }
    
    [self.lock unlock];
}

#pragma mark CLLocationManagerDelegate
-(void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation* bestLocation;
    for(int i=0; i<locations.count; i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 60.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation != nil && theAccuracy > 0 && theAccuracy < 3000
           && (!(theLocation.latitude == 0.0 && theLocation.longitude == 0.0))){
            if(bestLocation == nil) {
                bestLocation = newLocation;
                continue;
            }
            if(theAccuracy < bestLocation.horizontalAccuracy) {
                bestLocation = newLocation;
            }
        }
    }
    if (bestLocation) {
        [self.lock lock];
        //非高精度的item首次获取位置后回调并被删除
        NSMutableArray *lowAccuracyItems = [NSMutableArray array];
        for (LocationInfoItem *item in _items) {
            [item updateLocation:bestLocation];
            if (!item.isHighAccuracy) {
                [item doCallback];
                [lowAccuracyItems addObject:item];
            }
        }
        [_items removeObjectsInArray:lowAccuracyItems];
        WALOG(@" %lu个非高精度的item首次获取位置后回调并被删除，还剩下%lu个高精度定位",(unsigned long)lowAccuracyItems.count,(unsigned long)_items.count);
        //判断是否还需定位
        if (!_isUpdateLocation && _items.count == 0) {
            [self.locationManager stopUpdatingLocation];
            WALOG(@"获取位置结束，停止定位")
        }
        
        //通知监听者
        WALOG(@"获取位置回调")
        [_listeners fireListeners:^(id  _Nonnull listener) {
            if ([listener respondsToSelector:@selector(onLocationChanged:)]) {
                WALocationModel *model = [[WALocationModel alloc] init];
                model.location = bestLocation;
                [listener onLocationChanged:model];
            }
        }];
        [self.lock unlock];
           
    }
}


#pragma mark - iBeacon
/// 开始搜索附近iBeacon设备
/// @param uuids 设备uuid
/// @param completionHandler 完成回调
- (void)startBeaconDiscoveryWithUUIDS:(NSArray<NSUUID *>*)uuids
             ignoreBluetoothAvailable:(BOOL)ignoreBluetoothAvailable
                    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (_isMonitoring) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"startBeaconDiscovery" code:IBeaconErrorAlreadyStart userInfo:@{
                NSLocalizedDescriptionKey: @"already start"
                
            }]);
        }
    }
    BOOL availableMonitor = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
    if (!availableMonitor) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"startBeaconDiscovery" code:IBeaconErrorUnsupport userInfo:@{
                NSLocalizedDescriptionKey   : @"unsupport"
            }]);
        }
    }
    if (![AuthorizationCheck locationAuthorizationCheck]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"startBeaconDiscovery" code:IBeaconErrorLocationServiceUnavailable userInfo:@{
                NSLocalizedDescriptionKey: @"location service unavailable"
                
            }]);
        }
    }
    //初次创建centralManager，需要用回调判断蓝牙状态。
    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{
            CBCentralManagerOptionShowPowerAlertKey: @NO
        }];
        _startDiscoveryBlock = completionHandler;
        _startDiscoveryDeviceUUIDS = uuids;
        return;
    }
    if (@available(iOS 10.0, *)) {
        if (_centralManager.state != CBManagerStatePoweredOn) {
            if (completionHandler) {
                completionHandler(NO, [NSError errorWithDomain:@"startBeaconDiscovery" code:IBeaconErrorBlueToothServiceUnavailable userInfo:@{
                    NSLocalizedDescriptionKey: @"bluetooth service unavailable"
                }]);
            }
        }
    } else {
        if (_centralManager.state != CBCentralManagerStatePoweredOn) {
            if (completionHandler) {
                completionHandler(NO, [NSError errorWithDomain:@"startBeaconDiscovery" code:IBeaconErrorBlueToothServiceUnavailable userInfo:@{
                    NSLocalizedDescriptionKey: @"bluetooth service unavailable"
                }]);
            }
        }
    }
    [self startRangingForRegionsWithUUIDS:uuids
                        completionHandler:completionHandler];
    return;
}


/// 停止搜索设备
/// @param completionHandler 完成回调
- (void)stopBeaconDiscoveryWithcompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (!_isMonitoring) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"stopBeaconDiscovery" code:IBeaconErrorNotStartBeaconDiscovery userInfo:@{
                NSLocalizedDescriptionKey: @"not startBeaconDiscovery"
            }]);
        }
    }
    BOOL availableMonitor = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
    if (!availableMonitor) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"stopBeaconDiscovery" code:IBeaconErrorUnsupport userInfo:@{
                NSLocalizedDescriptionKey   : @"unsupport"
            }]);
        }
    }
    if (![AuthorizationCheck locationAuthorizationCheck]) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"stopBeaconDiscovery" code:IBeaconErrorLocationServiceUnavailable userInfo:@{
                NSLocalizedDescriptionKey: @"location service unavailable"
                
            }]);
        }
    }
    if (@available(iOS 13.0, *)) {
        for (CLBeaconIdentityConstraint *constraint in _constraints) {
            [self.locationManager stopRangingBeaconsSatisfyingConstraint:constraint];
        }
    } else {
        for (CLBeaconRegion *region in _regions) {
            [self.locationManager stopRangingBeaconsInRegion:region];
        }
    }
    if (completionHandler) {
        completionHandler(YES, nil);
    }
    [_beacons removeAllObjects];
    _isMonitoring = NO;
    _regions = nil;
    _constraints = nil;
}

- (void)getBeaconsWithcompletionHandler:(void(^)(BOOL success,NSDictionary *result ,NSError *error))completionHandler
{
    if (!_isMonitoring) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBeacons" code:IBeaconErrorNotStartBeaconDiscovery userInfo:@{
                NSLocalizedDescriptionKey: @"not startBeaconDiscovery"
            }]);
        }
    }
    BOOL availableMonitor = [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]];
    if (!availableMonitor) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBeacons" code:IBeaconErrorUnsupport userInfo:@{
                NSLocalizedDescriptionKey   : @"unsupport"
            }]);
        }
    }
    if (![AuthorizationCheck locationAuthorizationCheck]) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getBeacons" code:IBeaconErrorLocationServiceUnavailable userInfo:@{
                NSLocalizedDescriptionKey: @"location service unavailable"
                
            }]);
        }
    }
    if (completionHandler) {
        NSMutableArray *beacons = [NSMutableArray array];
        for (CLBeacon *beacon in [_beacons allValues]) {
            [beacons addObject:[beacon toDict]];
        }
        completionHandler(YES, @{
            @"beacons": beacons
                               }, nil);
    }
}

- (void)webView:(WebView *)webView onBeaconUpdate:(NSString *)callback
{
    //仅能注册一个监听，此方法和CBCentralManagerDelegate方法都在主线程执行，此处可不用考虑加锁
    NSString *key = [self getKeyByWebView:webView];
    NSMutableArray *callbacks = self.beaconUpdateDict[key];
    if (callbacks) {
        [callbacks removeAllObjects];
    }
    [self webView:webView
  onEventWithDict:self.beaconUpdateDict
         callback:callback];
}

- (void)webView:(WebView *)webView offBeaconUpdate:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.beaconUpdateDict
         callback:callback];
}

- (void)webView:(WebView *)webView onBeaconServiceChange:(NSString *)callback
{
    //仅能注册一个监听，此方法和CBCentralManagerDelegate方法都在主线程执行，此处可不用考虑加锁
    NSString *key = [self getKeyByWebView:webView];
    NSMutableArray *callbacks = self.beaconUpdateDict[key];
    if (callbacks) {
        [callbacks removeAllObjects];
    }
    [self webView:webView
  onEventWithDict:self.beaconServiceChangeDict
         callback:callback];
}

- (void)webView:(WebView *)webView offBeaconServiceChange:(NSString *)callback
{
    [self webView:webView
 offEventWithDict:self.beaconServiceChangeDict
         callback:callback];
}

#pragma mark -CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(nonnull CBCentralManager *)central {
    if (@available(iOS 10.0, *)) {
        if (central.state != CBManagerStatePoweredOn) {
            return;
        }
    } else {
        if (central.state != CBCentralManagerStatePoweredOn) {
            return;
        }
        // Fallback on earlier versions
    }
    if (_startDiscoveryBlock && _startDiscoveryDeviceUUIDS) {
        [self startRangingForRegionsWithUUIDS:_startDiscoveryDeviceUUIDS
                            completionHandler:_startDiscoveryBlock];
        _startDiscoveryBlock = nil;
        _startDiscoveryDeviceUUIDS = nil;
    }
}

/// 检测到区域内的iBeacons
  - (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons inRegion:(CLBeaconRegion *)region
{
    [self doUpdateBeacons:beacons];
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray<CLBeacon *> *)beacons satisfyingConstraint:(CLBeaconIdentityConstraint *)beaconConstraint
API_AVAILABLE(ios(13.0))
{
    [self doUpdateBeacons:beacons];

}
//  /// 有错误产生时的回调
//  - (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
//{
//
//}
//
//- (void)locationManager:(CLLocationManager *)manager didFailRangingBeaconsForConstraint:(CLBeaconIdentityConstraint *)beaconConstraint error:(NSError *)error
//API_AVAILABLE(ios(13.0))
//{
//
//}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self doUpdateService:YES isDiscovering:_isMonitoring];
    } else {
        [self doUpdateService:NO isDiscovering:NO];
    }
}


- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
API_AVAILABLE(ios(14.0))
{
    if (@available(iOS 14.0, *)) {
        CLAuthorizationStatus status = manager.authorizationStatus;
        if (status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [self doUpdateService:YES isDiscovering:_isMonitoring];
        } else {
            [self doUpdateService:NO isDiscovering:NO];
        }
    }
}

#pragma mark - private

- (void)startRangingForRegionsWithUUIDS:(NSArray<NSUUID *>*)uuids
                         completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    _isMonitoring = YES;
    NSMutableArray *regions = [NSMutableArray array];
    NSMutableArray *constraints = [NSMutableArray array];
    for (NSUUID *uuid in uuids) {
        if (@available(iOS 13.0, *)) {
            CLBeaconIdentityConstraint * constraint = [[CLBeaconIdentityConstraint alloc] initWithUUID:uuid];
            [self.locationManager startRangingBeaconsSatisfyingConstraint:constraint];
            [constraints addObject:constraint];
        } else {
            // Fallback on earlier versions
            CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@""];
            [self.locationManager startRangingBeaconsInRegion:region];
            [regions addObject:region];
        }
    }
    _regions = [regions copy];
    _constraints = [constraints copy];
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}


- (void)doUpdateBeacons:(NSArray <CLBeacon *>*)beacons
{
    NSMutableArray *array = [NSMutableArray array];
    for (CLBeacon *beacon in beacons) {
        [array addObject:[beacon toDict]];
        if (@available(iOS 13.0, *)) {
            _beacons[[NSString stringWithFormat:@"__%@__%@__%@",beacon.UUID, beacon.major, beacon.minor]] = beacon;
        } else {
            // Fallback on earlier versions
            _beacons[[NSString stringWithFormat:@"__%@__%@__%@",beacon.proximityUUID, beacon.major, beacon.minor]] = beacon;
        }
    }
    [self doCallbackInCallbackDict:self.beaconUpdateDict andResult:@{
        @"beacons": array
    }];
}

- (void)doUpdateService:(BOOL)available isDiscovering:(BOOL)discovering
{
    [self doCallbackInCallbackDict:self.beaconUpdateDict andResult:@{
        @"available"    : @(available),
        @"discovering"  : @(discovering)
    }];
}
@end
