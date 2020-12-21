//
//  WADeviceManager.m
//  weapps
//
//  Created by tommywwang on 2020/8/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WADeviceManager.h"
#import "EventListenerList.h"
#import "WKWebViewHelper.h"
#import "WACallbackModel.h"

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@interface WADeviceModel : WACallbackModel

@property (nonatomic, strong) NSMutableDictionary *callbackDict;


- (void)webView:(WebView *)webView onCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCallback:(NSString *)callback;

@end

@implementation WADeviceModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _callbackDict = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)webView:(WebView *)webView onCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:_callbackDict callback:callback];
}

- (void)webView:(WebView *)webView offCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:_callbackDict callback:callback];
}

@end

@interface WAAccelerometerModel : WADeviceModel

@property (nonatomic, strong, readonly) CMMotionManager *manager;

- (void)startAccelerometerWithInterval:(CGFloat)interval
                     completionHandler:(nonnull void (^)(BOOL, NSError * _Nonnull))complationHandler;
@end

@implementation WAAccelerometerModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CMMotionManager alloc] init];
    }
    return self;
}


- (void)startAccelerometerWithInterval:(CGFloat)interval
                     completionHandler:(nonnull void (^)(BOOL, NSError *))complationHandler
{
    if (![self.manager isAccelerometerAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startAccelerometer" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Accelerometer is not available"
            }]);
        }
        return;
    }
    if ([self.manager isAccelerometerActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startAccelerometer" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Accelerometer is active"
            }]);
        }
        return;
    }
    self.manager.accelerometerUpdateInterval = interval;
    @weakify(self)
    [self.manager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
                                       withHandler:^(CMAccelerometerData * _Nullable data,
                                                     NSError * _Nullable error) {
        @strongify(self)
        if (error) {
            [self.manager stopAccelerometerUpdates];
        } else {
            NSDictionary *result = @{
                @"x": @(data.acceleration.x),
                @"y": @(data.acceleration.y),
                @"z": @(data.acceleration.z),
            };
            [self doCallbackInCallbackDict:self.callbackDict andResult:result];
        }
    }];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

- (void)stopAccelerometerWithCompletionHandler:(nonnull void (^)(BOOL, NSError *))complationHandler
{
    if (![self.manager isAccelerometerAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopAccelerometer" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Accelerometer is not available"
            }]);
        }
        return;
    }
    if (![self.manager isAccelerometerActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopAccelerometer" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Accelerometer is inactive"
            }]);
        }
        return;
    }
    [self.manager stopAccelerometerUpdates];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

@end

@interface WADeviceMotionModel : WADeviceModel

@property (nonatomic, strong, readonly) CMMotionManager *manager;

- (void)startDeviceMotionListeningWithInterval:(CGFloat)interval
                             completionHandler:(void(^)(BOOL success,
                                                        NSError *error))complationHandler;

- (void)stopDeviceMotionListeningWithCompletionHandler:(void(^)(BOOL success,
                                                                NSError *error))complationHandler;

@end

@implementation WADeviceMotionModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void)startDeviceMotionListeningWithInterval:(CGFloat)interval
                             completionHandler:(void(^)(BOOL success,
                                                        NSError *error))complationHandler
{
    if (![self.manager isDeviceMotionAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startDeviceMotion" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"DeviceMotion is not available"
            }]);
        }
        return;
    }
    if ([self.manager isDeviceMotionActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startDeviceMotion" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"DeviceMotion is active"
            }]);
        }
        return;
    }
    self.manager.deviceMotionUpdateInterval = interval;
    @weakify(self)
    [self.manager startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
                                      withHandler:^(CMDeviceMotion * _Nullable motion,
                                                    NSError * _Nullable error) {
        @strongify(self)
        if (error) {
            [self.manager stopDeviceMotionUpdates];
        } else {
            CMAttitude *attitude = motion.attitude;
            CGFloat alpha = attitude.yaw * 180.0/M_PI;
            CGFloat beta  = attitude.pitch * 180.0/M_PI;
            CGFloat gamma = attitude.roll * 180.0/M_PI;
            NSDictionary *result = @{
                                  @"alpha":@(alpha),
                                  @"beta" :@(beta),
                                  @"gamma":@(gamma),
                                  };
            [self doCallbackInCallbackDict:self.callbackDict andResult:result];
        }
    }];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

- (void)stopDeviceMotionListeningWithCompletionHandler:(void(^)(BOOL success,
                                                                NSError *error))complationHandler
{
    if (![self.manager isDeviceMotionAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopDeviceMotion" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"DeviceMotionAvailable is not available"
            }]);
        }
        return;
    }
    if (![self.manager isDeviceMotionActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopDeviceMotion" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"DeviceMotionActive is inactive"
            }]);
        }
        return;
    }
    [self.manager stopDeviceMotionUpdates];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

@end


@interface WAGyroscopeModel : WADeviceModel

@property (nonatomic, strong) CMMotionManager *manager;

- (void)startGyroscopeWithInterval:(CGFloat)interval
                  completionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopGyroscopeWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;
@end

@implementation WAGyroscopeModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CMMotionManager alloc] init];
    }
    return self;
}

- (void)startGyroscopeWithInterval:(CGFloat)interval
                  completionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    if (![self.manager isGyroAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startGyroscope" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Gyro is not available"
            }]);
        }
        return;
    }
    if ([self.manager isGyroActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startGyroscope" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Gyro is active"
            }]);
        }
        return;
    }
    self.manager.gyroUpdateInterval = interval;
    @weakify(self)
    [self.manager startGyroUpdatesToQueue:[[NSOperationQueue alloc] init]
                              withHandler:^(CMGyroData * _Nullable gyroData, NSError * _Nullable error) {
        @strongify(self)
        if (error) {
            [self.manager stopGyroUpdates];
        } else {
            NSDictionary *result = @{
                @"x": @(gyroData.rotationRate.x),
                @"y": @(gyroData.rotationRate.y),
                @"z": @(gyroData.rotationRate.z),
            };
            [self doCallbackInCallbackDict:self.callbackDict andResult:result];
        }
    }];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

- (void)stopGyroscopeWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    if (![self.manager isGyroAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopGyroscope" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Gyroscope is not available"
            }]);
        }
        return;
    }
    if (![self.manager isGyroActive]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopGyroscope" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Gyroscope is inactive"
            }]);
        }
        return;
    }
    [self.manager stopGyroUpdates];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}
@end


@interface WACompassModel : WADeviceModel <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *manager;

- (void)startCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

@end

@implementation WACompassModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [[CLLocationManager alloc] init];
        _manager.delegate = self;
    }
    return self;
}

- (void)startCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    if (![CLLocationManager headingAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"startCompass" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Compass not available"
            }]);
        }
        return;
    }
    [_manager startUpdatingHeading];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

- (void)stopCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    if (![CLLocationManager headingAvailable]) {
        if (complationHandler) {
            complationHandler(NO, [NSError errorWithDomain:@"stopCompass" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"Compass not available"
            }]);
        }
        return;
    }
    [_manager stopUpdatingHeading];
    if (complationHandler) {
        complationHandler(YES, nil);
    }
}

//CLLocationManager的heading改变后的回调
- (void)locationManager:(CLLocationManager *)manager
       didUpdateHeading:(CLHeading *)newHeading
{
    NSDictionary *result = @{
                           @"direction": @(newHeading.trueHeading),
                           @"accuracy": @(newHeading.headingAccuracy),
                           
                           };
    [self doCallbackInCallbackDict:self.callbackDict andResult:result];
}

@end

@interface WAMemoryWarningModel : WADeviceModel

@end

@implementation WAMemoryWarningModel


@end

@interface WADeviceManager ()
@property (nonatomic, strong) WAAccelerometerModel *accelerometerModel;
@property (nonatomic, strong) WADeviceMotionModel *deviceMotionModel;
@property (nonatomic, strong) WAGyroscopeModel *gyroscopeModel;
@property (nonatomic, strong) WACompassModel *compassModel;
@property (nonatomic, strong) WAMemoryWarningModel *memoryWarningModel;
@end

@implementation WADeviceManager

- (WAAccelerometerModel *)accelerometerModel
{
    if (!_accelerometerModel) {
        _accelerometerModel = [[WAAccelerometerModel alloc] init];
    }
    return _accelerometerModel;
}

- (WADeviceMotionModel *)deviceMotionModel
{
    if (!_deviceMotionModel) {
        _deviceMotionModel = [[WADeviceMotionModel alloc] init];
    }
    return _deviceMotionModel;
}

- (WAGyroscopeModel *)gyroscopeModel
{
    if (!_gyroscopeModel) {
        _gyroscopeModel = [[WAGyroscopeModel alloc] init];
    }
    return _gyroscopeModel;
}

- (WACompassModel *)compassModel
{
    if (!_compassModel) {
        _compassModel = [[WACompassModel alloc] init];
    }
    return _compassModel;
}

- (WAMemoryWarningModel *)memoryWarningModel
{
    if (!_memoryWarningModel) {
        _memoryWarningModel = [[WAMemoryWarningModel alloc] init];
    }
    return _memoryWarningModel;
}

#pragma mark - ************************Accelerometer*********************

- (void)startAccelerometerWithInterval:(CGFloat)interval
                     completionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    [self.accelerometerModel startAccelerometerWithInterval:interval
                                          completionHandler:complationHandler];
}

- (void)stopAccelerometerWithCompletionHandler:(void(^)(BOOL success,
                                                        NSError *error))complationHandler
{
    [self.accelerometerModel stopAccelerometerWithCompletionHandler:complationHandler];
}

- (void)webView:(WebView *)webView onAccelerometerChangeCallback:(NSString *)callback
{
    [self.accelerometerModel webView:webView onCallback:callback];
}

- (void)webView:(WebView *)webView offAccelerometerChangeCallback:(NSString *)callback
{
    [self.accelerometerModel webView:webView offCallback:callback];
}

#pragma mark - ***************************DeviceMotion************************
- (void)startDeviceMotionListeningWithInterval:(CGFloat)interval
                             completionHandler:(void(^)(BOOL success,
                                                        NSError *error))complationHandler
{
    [self.deviceMotionModel startDeviceMotionListeningWithInterval:interval
                                                 completionHandler:complationHandler];
}

- (void)stopDeviceMotionListeningWithCompletionHandler:(void(^)(BOOL success,
                                                                NSError *error))complationHandler
{
    [self.deviceMotionModel stopDeviceMotionListeningWithCompletionHandler:complationHandler];
}

- (void)webView:(WebView *)webView onDeviceMotionChangeCallback:(NSString *)callback
{
    [self.deviceMotionModel webView:webView onCallback:callback];
}

- (void)webView:(WebView *)webView offDeviceMotionChangeCallback:(NSString *)callback
{
    [self.deviceMotionModel webView:webView offCallback:callback];
}


#pragma mark - ***********************Gyroscope********************
- (void)startGyroscopeWithInterval:(CGFloat)interval
                  completionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    [self.gyroscopeModel startGyroscopeWithInterval:interval completionHandler:complationHandler];
}

- (void)stopGyroscopeWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    [self.gyroscopeModel stopGyroscopeWithCompletionHandler:complationHandler];
}

- (void)webView:(WebView *)webView onGyroscopeChangeCallback:(NSString *)callback
{
    [self.gyroscopeModel webView:webView onCallback:callback];
}

- (void)webView:(WebView *)webView offGyroscopeChangeCallback:(NSString *)callback
{
    [self.gyroscopeModel webView:webView offCallback:callback];
}


#pragma mark - ***********************compass*************************
- (void)startCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    [self.compassModel startCompassWithCompletionHandler:complationHandler];
}

- (void)stopCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler
{
    [self.compassModel stopCompassWithCompletionHandler:complationHandler];
}

- (void)webView:(WebView *)webView onCompassChangeCallback:(NSString *)callback
{
    [self.compassModel webView:webView onCallback:callback];
}

- (void)webView:(WebView *)webView offCompassChangeCallback:(NSString *)callback
{
    [self.compassModel webView:webView offCallback:callback];
}

#pragma mark - ************************MemoryWarning*******************
- (void)onReceiveMemoryWarning
{
    [self.memoryWarningModel doCallbackInCallbackDict:self.memoryWarningModel.callbackDict
                                            andResult:nil];
}

- (void)webView:(WebView *)webView onMemoryWarningCallback:(NSString *)callback
{
    [self.memoryWarningModel webView:webView
                     onEventWithDict:self.memoryWarningModel.callbackDict
                            callback:callback];
}

- (void)webView:(WebView *)webView offMemoryWarningCallback:(NSString *)callback
{
    [self.memoryWarningModel webView:webView
                    offEventWithDict:self.memoryWarningModel.callbackDict
                            callback:callback];
}
@end
