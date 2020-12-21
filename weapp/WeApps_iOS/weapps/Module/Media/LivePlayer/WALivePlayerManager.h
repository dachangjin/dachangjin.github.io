//
//  WALivePlayerManager.h
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WALivePlayerManager : NSObject

- (void)createLivePlayer:(NSString *)playerId
               inWebView:(WKWebView *)webView
            withPosition:(NSDictionary *)position
                   state:(NSDictionary *)state
       completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 设置相关属性
/// @param playerId playerId
/// @param state 属性字典
- (void)livePlayer:(NSString *)playerId setState:(NSDictionary *)state;

/// 退出全屏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId exitFullScreenWithCompletionHandler:(void(^)(BOOL success,
                                                                                     NSDictionary *result,
                                                                                     NSError *error))completionHandler;

/// 退出画中画
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success,
                                                                                           NSDictionary *result,
                                                                                           NSError *error))completionHandler;

/// 静音
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId muteWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 暂停
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId pauseWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 播放
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId playWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 请求全屏
/// @param playerId playerId
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 恢复
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId resumeWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 截图
/// @param playerId playerId
/// @param quality 图片质量 raw :原图，compressed:压缩图
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId snapShotWithQuality:(NSString *)quality
          completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 停止
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId stopWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
