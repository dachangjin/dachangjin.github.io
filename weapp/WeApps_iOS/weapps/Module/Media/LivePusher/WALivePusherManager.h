//
//  WALivePusherManager.h
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WALivePusherManager : NSObject

- (void)createLivePusherInWebView:(WKWebView *)webView
                     withPosition:(NSDictionary *)position
                            state:(NSDictionary *)state
                completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//开启摄像头渲染
- (void)startPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//关闭摄像头渲染
- (void)stopPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//开始推流
- (void)startPushwithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//加入背景音乐
- (void)playBGM:(NSString *)url withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//停止推流
- (void)stopPushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//暂停推流
- (void)pausePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//暂停背景音乐
- (void)pauseBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//停止背景音
- (void)stopBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//恢复推流
- (void)resumePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//恢复背景音乐
- (void)resumeBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//设置背景音量
- (void)setBGMVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//设置麦克风音量
- (void)setMicVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


//截图，quality：raw|compressed
- (void)snapshot:(NSString *)quality withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//切换手电筒
- (void)toggleTorchWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//切换摄像头
- (void)switchCameraWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//设置属性
- (void)setLivePusherContextState:(NSDictionary *)state;

@end

NS_ASSUME_NONNULL_END
