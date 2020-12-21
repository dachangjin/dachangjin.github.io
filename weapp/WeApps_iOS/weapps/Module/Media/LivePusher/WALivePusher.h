//
//  WALivePusher.h
//  weapps
//
//  Created by tommywwang on 2020/9/15.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WALivePusherMode) {
    WALivePusherModeSD = 1,
    WALivePusherModeHD,
    WALivePusherModeFHD,
    WALivePusherModeRTC
};

typedef NS_ENUM(NSUInteger, WALivePusherOrientation) {
    WALivePusherOrientationVertical,
    WALivePusherOrientationHorizontal
};

typedef NS_ENUM(NSUInteger, WALivePusherAspect) {
    WALivePusherAspect3To4,
    WALivePusherAspect9To16
};

typedef NS_ENUM(NSUInteger, WALivePusherAudioQuality) {
    WALivePusherAudioQualityHigh,
    WALivePusherAudioQualityLow
};

typedef NS_ENUM(NSUInteger, WALivePusherDevicePosition) {
    WALivePusherDevicePositionFront,
    WALivePusherDevicePositionBack
};

typedef NS_ENUM(NSUInteger, WALivePusherLocalMirror) {
    WALivePusherLocalMirrorAuto = 0, //前置摄像头镜像，后置摄像头不镜像
    WALivePusherLocalMirrorEnable, //前后置摄像头均镜像
    WALivePusherLocalMirrorDisable, //前后置摄像头均不镜像
};

typedef NS_ENUM(NSUInteger, WALivePusherAudioReverbType) {
    WALivePusherAudioReverbTypeNone = 0,
    WALivePusherAudioReverbTypeKTV,
    WALivePusherAudioReverbTypeRoom,
    WALivePusherAudioReverbTypeConcert,
    WALivePusherAudioReverbTypeDeep,
    WALivePusherAudioReverbTypeHigh,
    WALivePusherAudioReverbTypeMetal,
    WALivePusherAudioReverbTypeMagnetic
};

typedef NS_ENUM(NSUInteger, WALivePusherAudioVolumeType) {
    WALivePusherAudioVolumeTypeAuto = 0,
    WALivePusherAudioVolumeTypeMedia, //媒体音量
    WALivePusherAudioVolumeTypeVoIP, //通话音量
};

typedef NS_ENUM(NSUInteger, WALivePusherBeautyStyle) {
    WALivePusherBeautyStyleSmooth = 0,
    WALivePusherBeautyStyleNatura
};

typedef NS_ENUM(NSUInteger, WALivePusherFilter) {
    WALivePusherFilterStandard = 0,
    WALivePusherFilterPink,
    WALivePusherFilterNostalgia,
    WALivePusherFilterBlues,
    WALivePusherFilterRomantic,
    WALivePusherFilterCool,
    WALivePusherFilterFresher,
    WALivePusherFilterSolor,
    WALivePusherFilterAestheticism,
    WALivePusherFilterWhitening,
    WALivePusherFilterCerisered
};


@interface WALivePusher : NSObject

@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIView *previewView;
@property (nonatomic, copy) NSString *rtmpURL;
@property (nonatomic, assign) WALivePusherMode mode;
/// 自动推流
@property (nonatomic, assign) BOOL autopush;
/// 是否静音。即将废弃，可用 enable-mic 替代
@property (nonatomic, assign) BOOL muted;

/// 开启摄像头
@property (nonatomic, assign) BOOL enableCamara;

/// 自动聚集
@property (nonatomic, assign) BOOL autoFocus;

/// 画面方向
@property (nonatomic, assign) WALivePusherOrientation orientation;

/// 美颜，取值范围 0-9 ，0 表示关闭
@property (nonatomic, assign) CGFloat beauty;

/// 美白，取值范围 0-9 ，0 表示关闭
@property (nonatomic, assign) CGFloat whiteness;

/// 宽高比，可选值有 3:4, 9:16
@property (nonatomic, assign) WALivePusherAspect aspect;

/// 最小码率
@property (nonatomic, assign) uint minBitrate;

/// 最大码率
@property (nonatomic, assign) uint maxBitrate;

/// 高音质(48KHz)或低音质(16KHz)，值为high, low
@property (nonatomic, assign) WALivePusherAudioQuality audioQuality;

/// 进入后台时推流的等待画面
@property (nonatomic, copy) NSString *waitingImage;

/// 等待画面资源的MD5值
@property (nonatomic, copy) NSString *waitingImageHash;

/// 调整焦距
@property (nonatomic, assign) BOOL zoom;

/// 前置或后置，值为front, back
@property (nonatomic, assign) WALivePusherDevicePosition devicePosition;

/// 设置推流画面是否镜像，产生的效果在 live-player 反应到
@property (nonatomic, assign) BOOL mirror;

/// 同 mirror 属性，后续 mirror 将废弃
@property (nonatomic, assign) BOOL remoteMirror;

/// 控制本地预览画面是否镜像
@property (nonatomic, assign) WALivePusherLocalMirror localMirror;

/// 音频混响类型
@property (nonatomic, assign) WALivePusherAudioReverbType audioReverbType;

/// 开启或关闭麦克风
@property (nonatomic, assign) BOOL enableMic;

/// 开启或关闭音频自动增益
@property (nonatomic, assign) BOOL enableAgc;

/// 开启或关闭音频噪声抑制
@property (nonatomic, assign) BOOL enableAns;

/// 音量类型
@property (nonatomic, assign) WALivePusherAudioVolumeType audioVolumType;

/// 上推视频分辨率宽度
@property (nonatomic, assign) uint videoWidth;

/// 上推视频分辨率高度
@property (nonatomic, assign) uint videoHeight;

/// 美颜类型
@property (nonatomic, assign) WALivePusherBeautyStyle beautyStyle;

/// 滤镜
@property (nonatomic, assign) WALivePusherFilter filter;

@property (nonatomic, copy) NSString *bindstatechange;
@property (nonatomic, copy) NSString *bindnetstatus;
@property (nonatomic, copy) NSString *binderror;
@property (nonatomic, copy) NSString *bindbgmstart;
@property (nonatomic, copy) NSString *bindbgmprogress;
@property (nonatomic, copy) NSString *bindbgmcomplete;
@property (nonatomic, copy) NSString *bindaudiovolumenotify;

//开启摄像头渲染
- (void)startPreview:(UIView *)view
withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//关闭摄像头渲染
- (void)stopPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//开始推流
- (void)startPushwithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//加入背景音乐
- (void)playBGM:(NSString *)url withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;

//停止推流,预览
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

@end

NS_ASSUME_NONNULL_END
