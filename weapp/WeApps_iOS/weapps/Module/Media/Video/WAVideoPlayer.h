//
//  WAVideoPlayer.h
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WADanmu : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) NSTimeInterval time;

- (id)initWithDict:(NSDictionary *)dict;

@end



typedef NS_ENUM(NSUInteger, WAVideoPlayerDirection) {
    WAVideoPlayerDirectionNormal = 0, //正常竖向
    WAVideoPlayerDirectionLeft = 90,  //屏幕逆时针90度
    WAVideoPlayerDirectionRight = -90 //屏幕顺时针90度
};

typedef NS_ENUM(NSUInteger, WAVideoPlayerObjectFit) {
    WAVideoPlayerObjectFitContain,
    WAVideoPlayerObjectFitFill,
    WAVideoPlayerObjectFitCover
};

typedef NS_ENUM(NSUInteger, WAVideoPlayerPlayButtonPosition) {
    WAVideoPlayerPlayButtonPositionBottom,
    WAVideoPlayerPlayButtonPositionCenter
};

typedef NS_ENUM(NSUInteger, WAVideoPlayerPicInPicMode) {
    WAVideoPlayerPicInPicModeNone,
    WAVideoPlayerPicInPicModePush,
    WAVideoPlayerPicInPicModePop,
    WAVideoPlayerPicInPicModeAll
};


@interface WAVideoPlayer : NSObject

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIView *previewView;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *playerId;

/// 视频时长
@property (nonatomic, assign) CGFloat duration;

/// 是否显示播放控件
@property (nonatomic, assign) BOOL showControls;

/// 弹幕列表
@property (nonatomic, strong) NSArray *danmuList;

/// 是否显示弹幕按钮，默认NO
@property (nonatomic, assign) BOOL showDanmuBtn;

/// 是否显示弹幕，只能在初始化时有效，默认NO
@property (nonatomic, assign) BOOL showDanmu;

/// 是否自动播放，默认NO
@property (nonatomic, assign) BOOL autoPlay;

/// 是否循环播放，默认NO
@property (nonatomic, assign) BOOL loop;

/// 是否静音，默认NO
@property (nonatomic, assign, getter=isMute) BOOL mute;

/// 视频初始播放位置
@property (nonatomic, assign) CGFloat initialTime;

/// 非全屏模式下，是否开启亮度与音量调节手势
@property (nonatomic, assign) BOOL enablePageGesture;

/// 设置全屏时视频的方向，不指定则根据宽高比自动判断
@property (nonatomic, strong) NSNumber *direction;

/// 显示进度，默认true，宽度大于240时才会显示
@property (nonatomic, assign) BOOL showProgress;

/// 是否显示全屏按钮
@property (nonatomic, assign) BOOL showFullScreenBtn;

/// 是否显示播放按钮
@property (nonatomic, assign) BOOL showPlayBtn;

/// 是否显示视频中间播放按钮
@property (nonatomic, assign) BOOL showCenterPlayBtn;

/// 是否开启控制进度手势
@property (nonatomic, assign) BOOL enableProgressGesture;

/// 视频表现形式
@property (nonatomic, assign) WAVideoPlayerObjectFit objectFit;

/// 视频封面的图片网络资源地址。若 controls 属性值为 false 则设置 poster 无效
@property (nonatomic, copy) NSString *poster;

/// 是否显示静音按钮
@property (nonatomic, assign) BOOL showMuteBtn;

/// 视频的标题，全屏时在顶部展示
@property (nonatomic, copy) NSString *title;

/// 播放按钮的位置，默认bottom
@property (nonatomic, assign) WAVideoPlayerPlayButtonPosition playBtnposition;

/// 是否开启播放手势，即双击切换播放/暂停，默认NO
@property (nonatomic, assign) BOOL enablePlayGesture;

/// 当跳转到本小程序的其他页面时，是否自动暂停本页面的视频播放，默认YES
@property (nonatomic, assign) BOOL autoPauseIfNavigate;

/// 当跳转到其它原生页面时，是否自动暂停本页面的视频，默认YES
@property (nonatomic, assign) BOOL autoPauseIfOpenNative;

/// 在非全屏模式下，是否开启亮度与音量调节手势（同 pagGesture），默认NO
@property (nonatomic, assign) BOOL vslideGesture;

/// 在全屏模式下，是否开启亮度与音量调节手势，默认YES
@property (nonatomic, assign) BOOL vslideGestureInFullscreen;

/// 显示投屏按钮。iOS 支持 AirPlay 和 DLNA 协议，默认NO
@property (nonatomic, assign) BOOL showCastingButton;

/// 设置小窗模式： push, pop，空字符串或通过数组形式设置多种模式（如： ["push", "pop"]）
@property (nonatomic, assign) WAVideoPlayerPicInPicMode picInPicMode;

/// 是否在小窗模式下显示播放进度，默认NO
@property (nonatomic, assign) BOOL pictureInPictureShowProgress;

/// 是否开启手机横屏时自动全屏，当系统设置开启自动旋转时生效，默认NO
@property (nonatomic, assign) BOOL enableAutoRotation;

/// 是否显示锁屏按钮，仅在全屏时显示，锁屏后控制栏的操作，默认NO
@property (nonatomic, assign) BOOL showScreenLockButton;

/// 是否显示截屏按钮，仅在全屏时显示，默认NO
@property (nonatomic, assign) BOOL showSnapshotButton;

/// 当开始/继续播放时触发play事件
@property (nonatomic, copy) NSString *bindplay;

/// 当暂停播放时触发 pause 事件
@property (nonatomic, copy) NSString *bindpause;

/// 当播放到末尾时触发 ended 事件
@property (nonatomic, copy) NSString *bindended;

/// 播放进度变化时触发，event.detail = {currentTime, duration} 。触发频率 250ms 一次
@property (nonatomic, copy) NSString *bindtimeupdate;

/// 视频进入和退出全屏时触发，event.detail = {fullScreen, direction}，direction 有效值为 vertical 或 horizontal
@property (nonatomic, copy) NSString *bindfullscreenchange;

/// 视频出现缓冲时触发
@property (nonatomic, copy) NSString *bindwaiting;

/// 视频播放出错时触发
@property (nonatomic, copy) NSString *binderror;

/// 加载进度变化时触发，只支持一段加载。event.detail = {buffered}，百分比
@property (nonatomic, copy) NSString *bindprogress;

/// 视频元数据加载完成时触发。event.detail = {width, height, duration}
@property (nonatomic, copy) NSString *bindloadedmetadata;

/// 切换 controls 显示隐藏时触发。event.detail = {show}
@property (nonatomic, copy) NSString *bindcontrolstoggle;

/// 播放器进入小窗
@property (nonatomic, copy) NSString *bindenterpictureinpicture;

/// 播放器退出小窗
@property (nonatomic, copy) NSString *bindleavepictureinpicture;

/// seek 完成时触发 (position iOS 单位 s, Android 单位 ms)
@property (nonatomic, copy) NSString *bindseekcomplete;


/// 退出全屏
/// @param completionHandler 完成回调
- (void)exitFullScreenWithCompletionHandler:(void(^)(BOOL success,
                                                     NSDictionary *result,
                                                     NSError *error))completionHandler;

/// 退出画中画
/// @param completionHandler 完成回调
- (void)exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success,
                                                           NSDictionary *result,
                                                           NSError *error))completionHandler;

/// 影藏状态栏
/// @param completionHandler 完成回调
- (void)hideStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                                    NSDictionary *result,
                                                    NSError *error))completionHandler;
/// 显示状态栏
/// @param completionHandler 完成回调
- (void)showStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                                    NSDictionary *result,
                                                    NSError *error))completionHandler;

/// 播放
/// @param completionHandler 完成回调
- (void)playWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                           NSError *error))completionHandler;

/// 暂停播放
/// @param completionHandler 完成回调
- (void)pauseWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler;
/// 停止播放
/// @param completionHandler 完成回调
- (void)stopWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler;

/// 设置播放速率
/// @param rate 播放速率
/// @param completionHandler 完成回调
- (void)playbackRate:(CGFloat)rate withCompletionHandler:(void(^)(BOOL success,
                                                                  NSDictionary *result,
                                                                  NSError *error))completionHandler;

/// 全屏播放
/// @param direction 播放方向
/// @param completionHandler 完成回调
- (void)requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

/// 跳转到指定位置
/// @param position 位置
/// @param completionHandler 完成回调
- (void)seek:(CGFloat)position withCompletionHandler:(void(^)(BOOL success,
                                                              NSDictionary *result,
                                                              NSError *error))completionHandler;

/// 发送弹幕
/// @param danmu 弹幕
/// @param completionHandler 完成回调
- (void)sendDanmu:(WADanmu *)danmu withCompletionHandler:(void(^)(BOOL success,
                                                                       NSDictionary *result,
                                                                       NSError *error))completionHandler;


@end

NS_ASSUME_NONNULL_END
