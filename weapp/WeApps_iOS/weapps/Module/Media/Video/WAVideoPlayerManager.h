//
//  WAVideoManager.h
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "WAVideoPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WAVideoPlayerManager : NSObject

- (void)createVideoPlayer:(NSString *)playerId
                inWebView:(WKWebView *)webView
             withPosition:(NSDictionary *)position
         childrenPosition:(NSDictionary *)childrenPosition
                    state:(NSDictionary *)state
        completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 设置相关属性
/// @param playerId playerId
/// @param state 属性字典
- (void)videoPlayer:(NSString *)playerId setState:(NSDictionary *)state;

/// 退出全屏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId exitFullScreenWithCompletionHandler:(void(^)(BOOL success,
                                                                                     NSDictionary *result,
                                                                                     NSError *error))completionHandler;

/// 退出画中画
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success,
                                                                                           NSDictionary *result,
                                                                                           NSError *error))completionHandler;

/// 显示状态栏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId showStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler;

/// 影藏状态栏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId hideStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler;

/// 暂停
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId pauseWithCompletionHandler:(void(^)(BOOL success,
                                                                             NSDictionary *result,
                                                                             NSError *error))completionHandler;

/// 播放
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId playWithCompletionHandler:(void(^)(BOOL success,
                                                                            NSDictionary *result,
                                                                            NSError *error))completionHandler;

/// 设置播放速率
/// @param playerId playerId
/// @param rate 速率
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
    setPlaybackRate:(CGFloat)rate
playWithCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler;

/// 请求全屏
/// @param playerId playerId
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
requestFullScreenWithDirection:(NSNumber *)direction
  completionHandler:(void(^)(BOOL success,
                             NSDictionary *result,
                             NSError *error))completionHandler;


/// 跳转到指定位置
/// @param playerId playerId
/// @param position 位置
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
               seek:(CGFloat)position
  completionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler;

/// 发送弹幕
/// @param playerId playerId
/// @param danmu 弹幕
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
          sendDanmu:(WADanmu *)danmu
  completionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler;

/// 停止
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId stopWithCompletionHandler:(void(^)(BOOL success,
                                                                            NSDictionary *result,
                                                                            NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
