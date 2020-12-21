//
//  WALocationManager.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "WACallbackModel.h"

typedef NS_ENUM(NSUInteger, IBeaconError) {
    IBeaconErrorNode = 0,
    IBeaconErrorUnsupport = 11000,
    IBeaconErrorBlueToothServiceUnavailable = 11001,
    IBeaconErrorLocationServiceUnavailable = 11002,
    IBeaconErrorAlreadyStart = 11003,
    IBeaconErrorNotStartBeaconDiscovery = 11004,
    IBeaconErrorSystemError = 11005,
    IBeaconErrorInvalidData = 11006
};

NS_ASSUME_NONNULL_BEGIN

@interface WALocationModel :  NSObject

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, assign) CLLocationCoordinate2D marsCoordinate;

@end

@protocol WALocationManagerProtocol <NSObject>

- (void)onLocationChanged:(WALocationModel *)location;

@end

/// 定位相关
@interface WALocationManager : WACallbackModel

/**
 *  严格单例，唯一获得实例的方法.
 *
 *  @return 实例对象.
 */
+ (instancetype)sharedManager;


/// 开启定位
/// @param completion 完成回调
- (void)startLocationUpdateWithCompletion:(void(^)(BOOL success, NSError *error))completion;

/// 关闭定位
- (void)stopLocationUpdate;

/// 获取位置
/// @param type 位置类型  wgs84 | gcj02
/// @param isHighAccuracy 是否高精度定位
/// @param highAccuracyExpireTime 高精度定位超时时间(ms) 指定时间内返回最高精度，该值3000ms以上高精度定位才有效果
/// @param completion 完成回调
- (void)getLocationWithType:(NSString *)type
             isHighAccuracy:(BOOL)isHighAccuracy
     highAccuracyExpireTime:(NSTimeInterval)highAccuracyExpireTime
                 completion:(void(^)(WALocationModel *location, NSError *errpr))completion;

/// 添加位置监听者
/// @param listener 监听者
- (void)addLocationListener:(id<WALocationManagerProtocol>)listener;


/// 移除位置监听者
/// @param listener 监听者
- (void)removeLocationListener:(id<WALocationManagerProtocol>)listener;

#pragma mark - iBeacon

/// 开始搜索附近iBeacon设备
/// @param uuids 设备uuid
/// @param ignoreBluetoothAvailable 忽略校验蓝牙
/// @param completionHandler 完成回调
- (void)startBeaconDiscoveryWithUUIDS:(NSArray<NSUUID *>*)uuids
             ignoreBluetoothAvailable:(BOOL)ignoreBluetoothAvailable
                    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;


/// 停止搜索设备
/// @param completionHandler 完成回调
- (void)stopBeaconDiscoveryWithcompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)getBeaconsWithcompletionHandler:(void(^)(BOOL success,NSDictionary *result ,NSError *error))completionHandler;

- (void)webView:(WebView *)webView onBeaconUpdate:(NSString *)callback;

- (void)webView:(WebView *)webView offBeaconUpdate:(NSString *)callback;

- (void)webView:(WebView *)webView onBeaconServiceChange:(NSString *)callback;

- (void)webView:(WebView *)webView offBeaconServiceChange:(NSString *)callback;

@end

NS_ASSUME_NONNULL_END
