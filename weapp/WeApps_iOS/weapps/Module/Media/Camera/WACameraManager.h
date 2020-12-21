//
//  WACameraManager.h
//  weapps
//
//  Created by tommywwang on 2020/7/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebView.h"


NS_ASSUME_NONNULL_BEGIN

@class Weapps;
@interface WACameraManager : NSObject

- (id)initWithWeapps:(Weapps *)app;


/// 创建camera插入webView节点中
/// @param webview webView
/// @param position 位置信息
/// @param state 参数
/// @param block 完成回调
- (void)createCameraViewWithWebView:(WebView *)webview
                                 position:(NSDictionary *)position
                                    state:(NSDictionary *)state
                          completionBlock:(void(^)(BOOL success, NSError *error))block;

- (void)setCameraState:(NSDictionary *)state;

/// 设置相机缩放级别
/// @param zoom 缩放级别，范围[1, maxZoom]。zoom 可取小数，精确到小数后一位。maxZoom 可在 bindinitdone 返回值中获取。
/// @param completionHandler 完成回调
- (void)setCameraZoom:(CGFloat)zoom
    completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 设置相机闪光灯
/// @param flash auto | on | off
/// @param completionHandler 完成回调
- (void)setCameraFlash:(NSString *)flash
     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 设置相机摄像头位置
/// @param devicePosition front | back
/// @param completionHandler 完成回调
- (void)setCameraDevicePosition:(NSString *)devicePosition
              completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 拍照
/// @param quality 质量
/// @param completionHandler 完成回调
- (void)takePhotoWithQuality:(NSString *)quality
            completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 开始摄像
/// @param timeoutCallback 拍摄超时回调
/// @param completionHandler 完成回调
- (void)startRecordWithTimeoutCallback:(NSString *)timeoutCallback
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 停止摄像
/// @param compressed 是否压缩
/// @param completionHandler 完成回调
- (void)stopRecordWithCompressed:(BOOL)compressed
               completionHandler:(void (^)(BOOL, NSDictionary * , NSError * ))completionHandler;


/// 开始监听相机帧数据
/// @param completionHandler 完成回调
- (void)startListeningCameraFrameWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 停止监听相机帧数据
/// @param completionHandler 完成回调
- (void)stopListeningCameraFrameWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 添加onCameraFrame回调
/// @param callback 回调
/// @param completionHandler 完成回调
- (void)onCameraFrame:(NSString *)callback
    completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
