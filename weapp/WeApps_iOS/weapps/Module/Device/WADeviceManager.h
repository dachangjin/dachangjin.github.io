//
//  WADeviceManager.h
//  weapps
//
//  Created by tommywwang on 2020/8/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebView.h"

NS_ASSUME_NONNULL_BEGIN

@interface WADeviceManager : NSObject 
//**********************Accelerometer******************
- (void)startAccelerometerWithInterval:(CGFloat)interval
                     completionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopAccelerometerWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)webView:(WebView *)webView onAccelerometerChangeCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offAccelerometerChangeCallback:(NSString *)callback;

//************************Compass*******************
- (void)startCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopCompassWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)webView:(WebView *)webView onCompassChangeCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCompassChangeCallback:(NSString *)callback;

//**************************DeviceMotion*****************
- (void)startDeviceMotionListeningWithInterval:(CGFloat)interval
                             completionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopDeviceMotionListeningWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)webView:(WebView *)webView onDeviceMotionChangeCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offDeviceMotionChangeCallback:(NSString *)callback;

//************************Gyroscope*******************
- (void)startGyroscopeWithInterval:(CGFloat)interval
                  completionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)stopGyroscopeWithCompletionHandler:(void(^)(BOOL success, NSError *error))complationHandler;

- (void)webView:(WebView *)webView onGyroscopeChangeCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offGyroscopeChangeCallback:(NSString *)callback;

//************************MemoryWarning*******************
- (void)onReceiveMemoryWarning;

- (void)webView:(WebView *)webView onMemoryWarningCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offMemoryWarningCallback:(NSString *)callback;

@end


NS_ASSUME_NONNULL_END
