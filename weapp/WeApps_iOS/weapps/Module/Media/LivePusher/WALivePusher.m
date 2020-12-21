//
//  WALivePusher.m
//  weapps
//
//  Created by tommywwang on 2020/9/15.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePusher.h"
#import <TXLiteAVSDK_Professional/TXLivePush.h>
#import "NetworkHelper.h"
#import "PathUtils.h"
#import "UIImage+QMUI.h"
#import "WKWebViewHelper.h"

#define kBGM_ID 1

typedef void(^WALivePusherStateChangeBlock)(int code);
typedef void(^WALivePusherNetStateChangeBlock)(NSDictionary *info);
typedef void(^WALivePusherErrorBlock)(int errCode, NSString *errMsg);
typedef void(^WALivePusherBGMusicStartBlock)(void);
typedef void(^WALivePusherBGMusicProgessBlock)(float progress, float duration);
typedef void(^WALivePusherBGMusicCompleteBlock)(void);
typedef void(^WALivePusherAudioVolumeNotifyBlock)(NSInteger volume);


@interface WALivePusher () <TXLivePushListener>



@property (nonatomic, strong) TXLivePush *pusher;

@property (nonatomic, strong) TXLivePushConfig *config;
@property (nonatomic, copy) WALivePusherStateChangeBlock stateChangeBlock;
@property (nonatomic, copy) WALivePusherNetStateChangeBlock netStateChangeBlock;
@property (nonatomic, copy) WALivePusherErrorBlock errorBlock;
@property (nonatomic, copy) WALivePusherBGMusicStartBlock bgmMusicStartBlock;
@property (nonatomic, copy) WALivePusherBGMusicProgessBlock bmgMusicProgressBlock;
@property (nonatomic, copy) WALivePusherBGMusicCompleteBlock bmgMusicCompletionBlock;
@property (nonatomic, copy) WALivePusherAudioVolumeNotifyBlock audioVolumeNotifyBlock;
@property (nonatomic, assign) BOOL isTorchOn;

@end

@implementation WALivePusher

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initConfig];
        [self initBlocks];
    }
    return self;
}

- (void)initConfig
{
    _config = [[TXLivePushConfig alloc] init];
    
    _config.homeOrientation = HOME_ORIENTATION_DOWN;
    _config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
    
    [_config setTouchFocus:NO];
    [_config setVideoBitrateMin:200];
    [_config setVideoBitrateMax:1000];
    [_config setEnableZoom:NO];
    [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_360_640];
    
    _pusher = [[TXLivePush alloc] initWithConfig:_config];
    _pusher.delegate = self;
    
    [_pusher setVideoQuality:VIDEO_QUALITY_LINKMIC_MAIN_PUBLISHER adjustBitrate:NO
            adjustResolution:NO];
    [_pusher setMute:NO];
    [_pusher setMirror:NO];
    [_pusher setMute:NO];
    @weakify(self)
    [_pusher setAudioVolumeEvaluationListener:^(NSInteger volume) {
       @strongify(self)
        if (self.audioVolumeNotifyBlock) {
            self.audioVolumeNotifyBlock(volume);
        }
    }];
    
    [[_pusher getBeautyManager] setBeautyLevel:0];
    [[_pusher getBeautyManager] setWhitenessLevel:0];
    [[_pusher getBeautyManager] setBeautyStyle:TXBeautyStyleSmooth];
}

- (void)initBlocks
{
    @weakify(self)
    self.stateChangeBlock = ^(int code){
        @strongify(self)
        if (self.bindstatechange) {
            [WKWebViewHelper successWithResultData:@{
                @"code": @(code)
            }
                                           webView:self.webView
                                          callback:self.bindstatechange];
        }
    };
    self.netStateChangeBlock = ^(NSDictionary *info) {
        @strongify(self)
        if (self.bindnetstatus) {
            [WKWebViewHelper successWithResultData:@{
                @"info": info
            }
                                           webView:self.webView
                                          callback:self.bindnetstatus];
        }
    };
    self.errorBlock = ^(int errCode, NSString *errMsg) {
        @strongify(self)
        if (self.binderror) {
            [WKWebViewHelper successWithResultData:@{
                @"errCode"  : @(errCode),
                @"errMsg"   : errMsg ?: @"unknown error"
            }
                                           webView:self.webView
                                          callback:self.binderror];
        }
    };
    self.bgmMusicStartBlock = ^{
        @strongify(self)
        if (self.bindbgmstart) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindbgmstart];
        }
    };
    self.bmgMusicProgressBlock = ^(float progress, float duration) {
        @strongify(self)
        if (self.bindbgmprogress) {
            [WKWebViewHelper successWithResultData:@{
                @"progress"  : @(progress),
                @"duration"  : @(duration)
            }
                                           webView:self.webView
                                          callback:self.bindbgmprogress];
        }
    };
    self.bmgMusicCompletionBlock = ^{
        @strongify(self)
        if (self.bindbgmcomplete) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindbgmcomplete];
        }
    };
    self.audioVolumeNotifyBlock = ^(NSInteger volume) {
        @strongify(self)
        if (self.bindaudiovolumenotify) {
            [WKWebViewHelper successWithResultData:@{
                @"volume"  : @(volume)
            }
                                           webView:self.webView
                                          callback:self.bindaudiovolumenotify];
        }
    };
}

#pragma mark - setters

- (void)setMode:(WALivePusherMode)mode
{
    _mode = mode;
    [_pusher setVideoQuality:(TX_Enum_Type_VideoQuality)mode
               adjustBitrate:NO
            adjustResolution:NO];
}

- (void)setRtmpURL:(NSString *)rtmpURL
{
    _rtmpURL = rtmpURL;
    if (_autopush && _previewView) {
        [self startPreview:_previewView withCompletionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
            if (success) {
                [self startPushwithCompletionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
                    
                }];
            }
        }];
    }
}

- (void)setAutopush:(BOOL)autopush
{
    _autopush = autopush;
    if (_autopush && _rtmpURL && _previewView) {
        [self startPreview:_previewView withCompletionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
            if (success) {
                [self startPushwithCompletionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
                    
                }];
            }
        }];
    }
}

- (void)setMuted:(BOOL)muted
{
    _muted = muted;
    _enableMic = !muted;
    [_pusher setMute:muted];
}

- (void)setEnableCamara:(BOOL)enableCamara
{
    _enableCamara = enableCamara;
    if (_enableCamara) {
        [_pusher stopPreview];
    } else {
        [_pusher startPreview:_previewView];
    }
}

- (void)setAutoFocus:(BOOL)autoFocus
{
    _autoFocus = autoFocus;
    if (_autoFocus) {
        [_config setTouchFocus:NO];
        [_pusher setConfig:_config];
    } else {
        [_config setTouchFocus:YES];
        [_pusher setConfig:_config];
    }
}

- (void)setOrientation:(WALivePusherOrientation)orientation
{
    _orientation = orientation;
    if (_orientation == WALivePusherOrientationVertical) {
        _config.homeOrientation = HOME_ORIENTATION_DOWN;
        [_pusher setConfig:_config];
        [_pusher setRenderRotation:0];
    } else {
        _config.homeOrientation = HOME_ORIENTATION_RIGHT;
        [_pusher setConfig:_config];
        [_pusher setRenderRotation:90];
    }
}

- (void)setBeauty:(CGFloat)beauty
{
    _beauty = beauty;
    [[_pusher getBeautyManager] setBeautyLevel:beauty];
}

- (void)setWhiteness:(CGFloat)whiteness
{
    _whiteness = whiteness;
    [[_pusher getBeautyManager] setWhitenessLevel:whiteness];
}

- (void)setAspect:(WALivePusherAspect)aspect
{
    _aspect = aspect;
    //TODO:
}

- (void)setMinBitrate:(uint)minBitrate
{
    _minBitrate = minBitrate;
    [_config setVideoBitrateMin:minBitrate];
    [_pusher setConfig:_config];
}

- (void)setMaxBitrate:(uint)maxBitrate
{
    _maxBitrate = maxBitrate;
    [_config setVideoBitrateMax:maxBitrate];
    [_pusher setConfig:_config];
}

- (void)setAudioQuality:(WALivePusherAudioQuality)audioQuality
{
    _audioQuality = audioQuality;
    if (_audioQuality == WALivePusherAudioQualityLow) {
        _config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
    } else {
        _config.audioSampleRate = AUDIO_SAMPLE_RATE_16000;
    }
}

- (void)setWaitingImage:(NSString *)waitingImage
{
    _waitingImage = waitingImage;
    NSString *path = [PathUtils h5BundlePathForRelativePath:waitingImage];
    if (path) {
        [_config setPauseImg:[UIImage imageWithContentsOfFile:path]];
        [_pusher setConfig:_config];
    } else if ([waitingImage containsString:@"http"]){
        [NetworkHelper loadImageWithURL:[NSURL URLWithString:waitingImage]
                               progress:nil
                              completed:^(UIImage * _Nullable image,
                                          NSData * _Nullable data,
                                          NSError * _Nullable error,
                                          BOOL finished,
                                          NSURL * _Nullable imageURL) {
            if (image) {
                [self->_config setPauseImg:image];
                [self->_pusher setConfig:self->_config];
            }
        }];
    }
}

- (void)setWaitingImageHash:(NSString *)waitingImageHash
{
    //TODO: 待验证
    _waitingImageHash = waitingImageHash;
}

- (void)setZoom:(BOOL)zoom
{
    _zoom = zoom;
    [_config setEnableZoom:zoom];
    [_pusher setConfig:_config];
}

- (void)setDevicePosition:(WALivePusherDevicePosition)devicePosition
{
    _devicePosition = devicePosition;
    if ((_pusher.frontCamera && _devicePosition == WALivePusherDevicePositionBack) ||
        (!_pusher.frontCamera && _devicePosition == WALivePusherDevicePositionFront)) {
        [_pusher switchCamera];
    }
}
- (void)setMirror:(BOOL)mirror
{
    _mirror = mirror;
    _remoteMirror = mirror;
    [_pusher setMirror:mirror];
}

- (void)setRemoteMirror:(BOOL)remoteMirror
{
    _remoteMirror = remoteMirror;
    _mirror = remoteMirror;
    [_pusher setMirror:remoteMirror];
}

- (void)setLocalMirror:(WALivePusherLocalMirror)localMirror
{
    _localMirror = localMirror;
    if (localMirror == WALivePusherLocalMirrorAuto) {
        [_config setLocalVideoMirrorType:LocalVideoMirrorType_Auto];
    } else if (localMirror == WALivePusherLocalMirrorEnable) {
        [_config setLocalVideoMirrorType:LocalVideoMirrorType_Enable];
    } else {
        [_config setLocalVideoMirrorType:LocalVideoMirrorType_Disable];
    }
    [_pusher setConfig:_config];
}

- (void)setAudioReverbType:(WALivePusherAudioReverbType)audioReverbType
{
    _audioReverbType = audioReverbType;
    [[_pusher getAudioEffectManager] setVoiceReverbType:(TXVoiceReverbType)audioReverbType];
}

- (void)setEnableMic:(BOOL)enableMic
{
    _enableMic = enableMic;
    _muted = !enableMic;
    [_pusher setMute:!enableMic];
}

- (void)setEnableAgc:(BOOL)enableAgc
{
    _enableAgc = enableAgc;
    [_config setEnableAGC:enableAgc];
    [_pusher setConfig:_config];
}

- (void)setEnableAns:(BOOL)enableAns
{
    _enableAns = enableAns;
    [_config setEnableNAS:enableAns];
    [_pusher setConfig:_config];
}

- (void)setAudioVolumType:(WALivePusherAudioVolumeType)audioVolumType
{
    _audioVolumType = audioVolumType;
    [_config setVolumeType:(TXSystemAudioVolumeType)audioVolumType];
}

- (void)setVideoWidth:(uint)videoWidth
{
    switch (videoWidth) {
        case 360:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_360_640];
            _videoWidth = videoWidth;
            break;
        case 540:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_540_960];
            _videoWidth = videoWidth;
            break;
        case 720:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_720_1280];
            _videoWidth = videoWidth;
            break;
        case 1080:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_1080_1920];
            _videoWidth = videoWidth;
            break;
        default:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_360_640];
            _videoWidth = videoWidth;
            break;
    }
    [_pusher setConfig:_config];
}


- (void)setVideoHeight:(uint)videoHeight
{
    
    switch (videoHeight) {
        case 640:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_360_640];
            _videoHeight = videoHeight;
            break;
        case 960:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_540_960];
            _videoHeight = videoHeight;
            break;
        case 1280:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_720_1280];
            _videoHeight = videoHeight;
            break;
        case 1920:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_1080_1920];
            _videoHeight = videoHeight;
            break;
        default:
            [_config setVideoResolution:VIDEO_RESOLUTION_TYPE_360_640];
            _videoHeight = videoHeight;
            break;
    }
    [_pusher setConfig:_config];
}

- (void)setBeautyStyle:(WALivePusherBeautyStyle)beautyStyle
{
    _beautyStyle = beautyStyle;
    [[_pusher getBeautyManager] setBeautyStyle:(TXBeautyStyle)beautyStyle];
}

- (void)setFilter:(WALivePusherFilter)filter
{
    _filter = filter;
    [[_pusher getBeautyManager] setFilter:[UIImage qmui_imageWithColor:nil]];
}

#pragma mark - methods

//开启摄像头渲染
- (void)startPreview:(UIView *)view
withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    int code = [_pusher startPreview:view];
    if (completionHandler) {
        if (code == 0) {
            completionHandler(YES, nil, nil);
        } else {
            completionHandler(NO, nil, [NSError errorWithDomain:@"startPreview" code:code userInfo:nil]);
        }
    }
}

//关闭摄像头渲染
- (void)stopPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_pusher stopPreview];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


//开始推流
- (void)startPushwithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    int code = [_pusher startPush:_rtmpURL];
    if (completionHandler) {
        if (code == 0) {
            completionHandler(YES, nil, nil);
        } else {
            NSString *errInfo = @"";
            if (code == -1) {
                errInfo = @"start fail";
            } else if (code == -5) {
                errInfo = @"license invalid";
            }
            completionHandler(NO, nil, [NSError errorWithDomain:@"start" code:code userInfo:@{
                NSLocalizedDescriptionKey: errInfo
            }]);
        }
    }
}

//加入背景音乐
- (void)playBGM:(NSString *)url withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    TXAudioMusicParam *param = [[TXAudioMusicParam alloc] init];
    NSString *path = [PathUtils h5BundlePathForRelativePath:url];
    param.path = path;
    param.ID = kBGM_ID;
    if (!path) {
        //可能是网络地址
        param.path = url;
    }
    @weakify(self)
    [[_pusher getAudioEffectManager] startPlayMusic:param
                                            onStart:^(NSInteger errCode) {
        @strongify(self)
        if (self.bgmMusicStartBlock) {
            self.bgmMusicStartBlock();
        }
    } onProgress:^(NSInteger progressMs, NSInteger durationMs) {
        @strongify(self)
        if (self.bmgMusicProgressBlock) {
            self.bmgMusicProgressBlock(progressMs, durationMs);
        }
    } onComplete:^(NSInteger errCode) {
        @strongify(self)
        if (self.bmgMusicCompletionBlock) {
            self.bmgMusicCompletionBlock();
        }
    }];
}

//停止推流
- (void)stopPushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_pusher stopPush];
    [_pusher stopPreview];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//暂停推流
- (void)pausePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_pusher pausePush];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//暂停背景音乐
- (void)pauseBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [[_pusher getAudioEffectManager] pausePlayMusic:kBGM_ID];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//停止背景音
- (void)stopBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [[_pusher getAudioEffectManager] stopPlayMusic:kBGM_ID];
}

//恢复推流
- (void)resumePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    if ([_pusher isPublishing]) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"resumePush" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"livePusher is Pushing"
            }]);
        }
        return;
    }
    [_pusher resumePush];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//恢复背景音乐
- (void)resumeBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [[_pusher getAudioEffectManager] resumePlayMusic:kBGM_ID];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//设置背景音量
- (void)setBGMVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [[_pusher getAudioEffectManager] setAllMusicVolume:volume * 100];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

//设置麦克风音量
- (void)setMicVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [[_pusher getAudioEffectManager] setVoiceVolume:volume * 100];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


//截图，quality：raw|compressed
- (void)snapshot:(NSString *)quality withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_pusher snapshot:^(TXImage *image) {
        CGFloat compressQuality = 1.0;
        if (kStringEqualToString(@"compressed", quality)) {
            compressQuality = 0.5;
        }
        NSData *imageData = UIImageJPEGRepresentation(image, compressQuality);
        NSString *tempPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"snapshot_%@.jpg",[[NSUUID UUID] UUIDString]]];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [imageData writeToFile:tempPath atomically:YES];
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completionHandler(YES, @{
                        @"tempFilePath": tempPath
                                           }, nil);
                });
            }
        });
    }];
}

//切换手电筒
- (void)toggleTorchWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    BOOL success = [_pusher toggleTorch:!self.isTorchOn];
    if (success) {
        self.isTorchOn = !self.isTorchOn;
    }
    if (completionHandler) {
        completionHandler(success, nil, nil);
    }
}

//切换摄像头
- (void)switchCameraWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    int code = [_pusher switchCamera];
    if (completionHandler) {
        if (code == 0) {
            completionHandler(YES, nil, nil);
        } else {
            completionHandler(NO, nil, [NSError errorWithDomain:@"switchCamera" code:-1 userInfo:nil]);
        }
    }
}


#pragma mark - TXLivePushListener

/**
 * 事件通知
 * @param eventId 参见 TXLiveSDKEventDef.h
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onPushEvent:(int)eventId withParam:(NSDictionary *)param
{
    if (self.stateChangeBlock) {
        self.stateChangeBlock(eventId);
    }
}

/**
 * 状态通知
 * @param param 参见 TXLiveSDKTypeDef.h
 */
- (void)onNetStatus:(NSDictionary *)param
{
    if (self.netStateChangeBlock) {
        NSDictionary *dict = @{
            @"videoBitrate" :   param[NET_STATUS_VIDEO_BITRATE] ?: @(0),
            @"audioBitrate" :   param[NET_STATUS_AUDIO_BITRATE] ?: @(0),
            @"videoFPS"     :   param[NET_STATUS_VIDEO_FPS] ?: @(0),
            @"videoGOP"     :   param[NET_STATUS_VIDEO_GOP] ?: @(0),
            @"netSpeed"     :   param[NET_STATUS_NET_SPEED] ?: @(0),
            @"netJitter"    :   param[NET_STATUS_NET_JITTER] ?: @(0),
            @"videoWidth"   :   param[NET_STATUS_VIDEO_WIDTH] ?: @(0),
            @"videoHeight"  :   param[NET_STATUS_VIDEO_HEIGHT] ?: @(0)
        };
        self.netStateChangeBlock(dict);
    }
}

@end
