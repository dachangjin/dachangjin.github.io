//
//  WALivePlayer.h
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WALivePlayerMode) {
    WALivePlayerModeLive,
    WALivePlayerModeLiveRTC
};

typedef NS_ENUM(NSUInteger, WALivePlayerOrientation) {
    WALivePlayerOrientationVertical,
    WALivePlayerOrientationHorizontal
};

typedef NS_ENUM(NSUInteger, WALivePlayerFillMode) {
    WALivePlayerFillModeContain,
    WALivePlayerFillModeFillCrop
};

typedef NS_ENUM(NSUInteger, WALivePlayerSoundMode) {
    WALivePlayerSoundModeSpeaker,
    WALivePlayerSoundModeEar
};

typedef NS_ENUM(NSUInteger, WALivePlayerPicInPicMode) {
    WALivePlayerPicInPicModeNone,
    WALivePlayerPicInPicModePush,
    WALivePlayerPicInPicModePop,
    WALivePlayerPicInPicModeAll
};

@interface WALivePlayer : NSObject

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIView *previewView;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *playerId;


/// 播放模式
@property (nonatomic, assign) WALivePlayerMode mode;

/// 自动播放
@property (nonatomic, assign) BOOL isAutoPlay;

/// 静音
@property (nonatomic, assign) BOOL isMuted;

/// 方向
@property (nonatomic, assign) WALivePlayerOrientation orientation;

/// 填充模式
@property (nonatomic, assign) WALivePlayerFillMode fillMode;

/// 最小缓冲区，单位s
@property (nonatomic, assign) float minCache;

/// 最大缓冲区，单位s
@property (nonatomic, assign) float maxCache;

/// 声音输出方式
@property (nonatomic, assign) WALivePlayerSoundMode soundMode;

/// 小窗模式，目前不支持
@property (nonatomic, assign) WALivePlayerPicInPicMode picInPicMode;

/// 播放状态变化事件
@property (nonatomic, copy) NSString *bindstatechange;

/// 全屏变化事件
@property (nonatomic, copy) NSString *bindfullscreenchange;

/// 网络状态通知
@property (nonatomic, copy) NSString *bindnetstatus;

/// 播放音量大小通知
@property (nonatomic, copy) NSString *bindaudiovolumenotify;


/// 播放器进入小窗（暂不支持）
@property (nonatomic, copy) NSString *bindenterpictureinpicture;

/// 播放器退出小窗（暂不支持）
@property (nonatomic, copy) NSString *bindleavepictureinpicture;


/// 退出全屏
/// @param completionHandler 完成回调
- (void)exitFullScreenWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 退出画中画
/// @param completionHandler 完成回调
- (void)exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 静音
/// @param completionHandler 完成回调
- (void)muteWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 暂停
/// @param completionHandler 完成回调
- (void)pauseWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 播放
/// @param completionHandler 完成回调
- (void)playWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 请求全屏
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 恢复
/// @param completionHandler 完成回调
- (void)resumeWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;


/// 截图
/// @param quality 图片质量 raw :原图，compressed:压缩图
/// @param completionHandler 完成回调
- (void)snapShotWithQuality:(NSString *)quality
          completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 停止
/// @param completionHandler 完成回调
- (void)stopWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

@end

NS_ASSUME_NONNULL_END
