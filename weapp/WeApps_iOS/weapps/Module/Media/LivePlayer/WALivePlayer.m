//
//  WALivePlayer.m
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePlayer.h"
#import "PathUtils.h"
#import "WKWebViewHelper.h"
#import "SuperPlayerView.h"
#import "SPDefaultControlView.h"

typedef void(^WALivePlayerStateChangeBlock)(int code);
typedef void(^WALivePlayerNetStateChangeBlock)(NSDictionary *info);
typedef void(^WALivePlayerAudioVolumeNotifyBlock)(NSInteger volume);
typedef void(^WALivePlayerFullScreenChangeBlock)(NSString * orientation, BOOL isFull);
typedef void(^WALivePlayerEnterPictureInPictureBlock)(void);
typedef void(^WALivePlayerLeavePictureInPictureBlock)(void);


@interface WALivePlayer () <SuperPlayerDelegate>

//@property (nonatomic, strong) TXLivePlayer *player;
@property (nonatomic, strong) SuperPlayerView *playerView;
//@property (nonatomic, strong) TXLivePlayConfig *config;

@property (nonatomic, copy) WALivePlayerStateChangeBlock stateChangeBlock;
@property (nonatomic, copy) WALivePlayerNetStateChangeBlock netStateChangeBlock;
@property (nonatomic, copy) WALivePlayerAudioVolumeNotifyBlock audioVolumeNotifyBlock;
@property (nonatomic, copy) WALivePlayerFullScreenChangeBlock fullScreenChangeBlock;
@property (nonatomic, copy) WALivePlayerEnterPictureInPictureBlock enterPicInPicBlock;
@property (nonatomic, copy) WALivePlayerLeavePictureInPictureBlock leavePicInPicBlock;

@end

@implementation WALivePlayer


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
    self.playerView = [[SuperPlayerView alloc] init];
    self.playerView.delegate = self;
    @weakify(self)
    [self.playerView setAudioVolumeEvaluationListener:^(int volume) {
        @strongify(self)
        if (self.audioVolumeNotifyBlock) {
            self.audioVolumeNotifyBlock(volume);
        }
    }];
    
    self.mode = WALivePlayerModeLive;
    self.isAutoPlay = NO;
    self.isMuted = NO;
    self.orientation = WALivePlayerOrientationVertical;
    self.fillMode = WALivePlayerFillModeContain;
    self.maxCache = 3;
    self.minCache = 1;
    self.soundMode = WALivePlayerSoundModeSpeaker;
    
    
    
//    _config = [[TXLivePlayConfig alloc] init];
//    [_config setMinAutoAdjustCacheTime:1];
//    [_config setMaxAutoAdjustCacheTime:3];
//    if (_mode == WALivePlayerModeLiveRTC) {
//        [_config setMinAutoAdjustCacheTime:0.2];
//        [_config setMaxAutoAdjustCacheTime:0.8];
//    }
    
//    _player = [[TXLivePlayer alloc] init];
//    _player.delegate = self;
//    _player.config = _config;
//    _player.isAutoPlay = NO;
//    [_player setMute:NO];
//    [_player setRenderRotation:HOME_ORIENTATION_DOWN];
//    [_player setRenderMode:RENDER_MODE_FILL_EDGE];
    [TXLivePlayer setAudioRoute:AUDIO_ROUTE_SPEAKER];

    
}

- (void)initBlocks
{
    @weakify(self)
    self.stateChangeBlock = ^(int code) {
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
    self.fullScreenChangeBlock = ^(NSString * orientation, BOOL isFull) {
        @strongify(self)
        if (self.bindfullscreenchange) {
            [WKWebViewHelper successWithResultData:@{
                @"direction": orientation,
                @"fullScreen": @(isFull)
            }
                                           webView:self.webView
                                          callback:self.bindfullscreenchange];
        }
    };
    self.enterPicInPicBlock = ^{
        @strongify(self)
        if (self.bindenterpictureinpicture) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindenterpictureinpicture];
        }
    };
    self.leavePicInPicBlock = ^{
        @strongify(self)
        if (self.bindleavepictureinpicture) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindleavepictureinpicture];
        }
    };
}

#pragma mark - setters


- (void)setPreviewView:(UIView *)previewView
{
    _previewView = previewView;
    _playerView.fatherView = previewView;
}


- (void)setUrl:(NSString *)url
{
    _url = url;
    if (_isAutoPlay && _url) {
        SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
        // 设置播放地址，直播、点播都可以
        playerModel.videoURL = _url;
        // 开始播放
        [_playerView playWithModel:playerModel];
    }
}

- (void)setIsAutoPlay:(BOOL)isAutoPlay
{
    _isAutoPlay = isAutoPlay;
    if (_isAutoPlay && _url) {
        SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
        // 设置播放地址，直播、点播都可以
        playerModel.videoURL = _url;
        // 开始播放
        [_playerView playWithModel:playerModel];
    }
}

- (void)setIsMuted:(BOOL)isMuted
{
    _isMuted = isMuted;
    [_playerView mute:isMuted];
}

- (void)setOrientation:(WALivePlayerOrientation)orientation
{
    _orientation = orientation;
    TX_Enum_Type_HomeOrientation orien = HOME_ORIENTATION_DOWN;
    if (orientation == WALivePlayerOrientationHorizontal) {
        orien = HOME_ORIENTATION_RIGHT;
    }
    [_playerView setRenderRotation:orien];
}

- (void)setFillMode:(WALivePlayerFillMode)fillMode
{
    _fillMode = fillMode;
    TX_Enum_Type_RenderMode renderMode = RENDER_MODE_FILL_EDGE;
    if (fillMode == WALivePlayerFillModeFillCrop) {
        renderMode = RENDER_MODE_FILL_SCREEN;
    }
    [_playerView setRenderMode:renderMode];
}

- (void)setMinCache:(float)minCache
{
    _minCache = minCache;
    [_playerView setMinCache:minCache];
}

- (void)setMaxCache:(float)maxCache
{
    _maxCache = maxCache;
    [_playerView setMaxCache:maxCache];
}

- (void)setSoundMode:(WALivePlayerSoundMode)soundMode
{
    _soundMode = soundMode;
    TXAudioRouteType type = AUDIO_ROUTE_SPEAKER;
    if (soundMode == WALivePlayerSoundModeEar) {
        type = AUDIO_ROUTE_RECEIVER;
    }
    [TXLivePlayer setAudioRoute:type];
}

- (void)setPicInPicMode:(WALivePlayerPicInPicMode)picInPicMode
{
    _picInPicMode = picInPicMode;
}


#pragma mark - methods

/// 退出全屏
/// @param completionHandler 完成回调
- (void)exitFullScreenWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView setFullScreen:NO];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

#warning 退出画中画
/// 退出画中画
/// @param completionHandler 完成回调
- (void)exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    //TODO: 不支持
}

/// 静音
/// @param completionHandler 完成回调
- (void)muteWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView mute:YES];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 暂停
/// @param completionHandler 完成回调
- (void)pauseWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView pause];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 播放
/// @param completionHandler 完成回调
- (void)playWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    if (_url) {
        SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
        // 设置播放地址，直播、点播都可以
        playerModel.videoURL = _url;
        // 开始播放
        [_playerView playWithModel:playerModel];
    } else {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"play" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"url is nil"
            }]);
        }
    }
}

/// 请求全屏
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
#warning 设置方向
    [_playerView setFullScreen:YES];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 恢复
/// @param completionHandler 完成回调
- (void)resumeWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView resume];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


/// 截图
/// @param quality 图片质量 raw :原图，compressed:压缩图
/// @param completionHandler 完成回调
- (void)snapShotWithQuality:(NSString *)quality
          completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView snapshot:^(TXImage *image) {
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

/// 停止
/// @param completionHandler 完成回调
- (void)stopWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    
    int code = [_playerView stopPlay];
    if (code == 0) {
        completionHandler(YES, nil, nil);
    } else {
        completionHandler(NO, nil, [NSError errorWithDomain:@"stop" code:code userInfo:nil]);
    }
}

#pragma mark - SuperPlayerDelegate
- (void)onPlayEvent:(int)eventId withParam:(NSDictionary *)param;
{
    if (self.stateChangeBlock) {
        self.stateChangeBlock(eventId);
    }
}

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
