//
//  WAVideoPlayer.m
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVideoPlayer.h"
#import "WKWebViewHelper.h"
#import "SuperPlayerView.h"
#import "SPDefaultControlView.h"
#import "UIColor+QMUI.h"
#import <SDWebImage/UIImageView+WebCache.h>

typedef void(^WAVideoPlayerPlayBlock)(void);
typedef void(^WAVideoPlayerPauseBlock)(void);
typedef void(^WAVideoPlayerEndBlock)(void);
typedef void(^WAVideoPlayerTimeUpdateBlock)(CGFloat currentTime,
                                            CGFloat duration);
//direction 有效值为 vertical 或 horizontal
typedef void(^WAVideoPlayerFullScreenChangeBlock)(BOOL fullScreen,
                                                  NSString *direction);
typedef void(^WAVideoPlayerWaitingBlock)(void);
typedef void(^WAVideoPlayerErrorBlock)(void);
typedef void(^WAVideoPlayerProgressBlock)(CGFloat buffered);
typedef void(^WAVideoPlayerLoadedMetadataBlock)(CGFloat width,
                                                CGFloat height,
                                                CGFloat duration);
typedef void(^WAVideoPlayerControlsToggleBlock)(BOOL show);
typedef void(^WAVideoPlayerEnterPicInPicBlock)(void);
typedef void(^WAVideoPlayerLeavePicInPicBlock)(void);
typedef void(^WAVideoPlayerSeekCompleteBlock)(CGFloat position);


@implementation WADanmu

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _text = dict[@"text"];
        _color = [UIColor qmui_rgbaColorWithHexString:dict[@"color"]];
        _time = [dict[@"time"] floatValue];
    }
    return self;
}

@end


@interface WAVideoPlayer () <SuperPlayerDelegate>

@property (nonatomic, strong) SuperPlayerView *playerView;
@property (nonatomic, copy) WAVideoPlayerPlayBlock playBlock;
@property (nonatomic, copy) WAVideoPlayerEndBlock endBlock;
@property (nonatomic, copy) WAVideoPlayerPauseBlock pauseBlock;
@property (nonatomic, copy) WAVideoPlayerTimeUpdateBlock timeUpdateBlock;
@property (nonatomic, copy) WAVideoPlayerFullScreenChangeBlock fullScreenChangeBlock;
@property (nonatomic, copy) WAVideoPlayerWaitingBlock waitingBlock;
@property (nonatomic, copy) WAVideoPlayerErrorBlock errorBlock;
@property (nonatomic, copy) WAVideoPlayerProgressBlock progressBlock;
@property (nonatomic, copy) WAVideoPlayerLoadedMetadataBlock loadedMetadataBlock;
@property (nonatomic, copy) WAVideoPlayerControlsToggleBlock controlsToggleBlock;
@property (nonatomic, copy) WAVideoPlayerEnterPicInPicBlock enterPicInPicBlock;
@property (nonatomic, copy) WAVideoPlayerLeavePicInPicBlock leavePicInPicBlock;
@property (nonatomic, copy) WAVideoPlayerSeekCompleteBlock seekCompleteBlock;
@end


@implementation WAVideoPlayer

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
    self.playerView.controlView = [[SPDefaultControlView alloc] init];
    
    self.showControls = YES;
    self.showProgress = YES;
    self.showFullScreenBtn = YES;
    self.showPlayBtn = YES;
    self.showCenterPlayBtn = YES;
    self.enableProgressGesture = YES;
    self.objectFit = WAVideoPlayerObjectFitContain;
    self.playBtnposition = WAVideoPlayerPlayButtonPositionBottom;
    self.autoPauseIfNavigate = YES;
    self.autoPauseIfOpenNative = YES;
    self.vslideGestureInFullscreen = YES;
    self.enablePlayGesture = NO;
    self.vslideGesture = NO;
    self.autoPlay = NO;
    self.showMuteBtn = NO;
    self.showScreenLockButton = NO;
    self.showSnapshotButton = NO;
    self.showDanmu = NO;
    self.showDanmuBtn = NO;
}

- (void)initBlocks
{
    @weakify(self)
    self.playBlock = ^{
      @strongify(self)
        if (self.bindplay) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindplay];
        }
    };
    self.pauseBlock = ^{
        @strongify(self)
        if (self.bindpause) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindpause];
        }
    };
    self.endBlock = ^{
        @strongify(self)
        if (self.bindended) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindended];
        }
    };
    self.timeUpdateBlock = ^(CGFloat currentTime, CGFloat duration) {
        @strongify(self)
        if (self.bindtimeupdate) {
            [WKWebViewHelper successWithResultData:@{
                @"currentTime"  : @(currentTime),
                @"duration"     : @(duration)
            }
                                           webView:self.webView
                                          callback:self.bindtimeupdate];
        }
    };
    self.fullScreenChangeBlock = ^(BOOL fullScreen, NSString *direction) {
        @strongify(self)
        if (self.bindfullscreenchange) {
            [WKWebViewHelper successWithResultData:@{
                @"fullScreen"   : @(fullScreen),
                @"direction"    : direction
            }
                                           webView:self.webView
                                          callback:self.bindfullscreenchange];
        }
    };
    self.waitingBlock = ^{
        @strongify(self)
        if (self.bindwaiting) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.bindwaiting];
        }
    };
    self.errorBlock = ^{
        @strongify(self)
        if (self.binderror) {
            [WKWebViewHelper successWithResultData:nil
                                           webView:self.webView
                                          callback:self.binderror];
        }
    };
    self.progressBlock = ^(CGFloat buffered) {
        @strongify(self)
        if (self.bindprogress) {
            [WKWebViewHelper successWithResultData:@{
                @"buffered" : @(buffered)
            }
                                           webView:self.webView
                                          callback:self.bindprogress];
        }
    };
    self.loadedMetadataBlock = ^(CGFloat width, CGFloat height, CGFloat duration) {
        @strongify(self)
        if (self.bindloadedmetadata) {
            [WKWebViewHelper successWithResultData:@{
                @"width"    : @(width),
                @"height"   : @(height),
                @"duration" : @(duration)
            }
                                           webView:self.webView
                                          callback:self.bindloadedmetadata];
        }
    };
    self.controlsToggleBlock = ^(BOOL show) {
        @strongify(self)
        if (self.bindcontrolstoggle) {
            [WKWebViewHelper successWithResultData:@{
                @"show" : @(show)
            }
                                           webView:self.webView
                                          callback:self.bindcontrolstoggle];
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
    self.seekCompleteBlock = ^(CGFloat position) {
        @strongify(self)
        if (self.bindseekcomplete) {
            [WKWebViewHelper successWithResultData:@{
                @"position": @(position)
            }
                                           webView:self.webView
                                          callback:self.bindseekcomplete];
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
    SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
    // 设置播放地址，直播、点播都可以
    playerModel.videoURL = _url;
    // 开始播放
    [_playerView playWithModel:playerModel];
}

- (void)setAutoPlay:(BOOL)autoPlay
{
    _autoPlay = autoPlay;
    _playerView.autoPlay = autoPlay;
    if (_autoPlay && _url) {
        SuperPlayerModel *playerModel = [[SuperPlayerModel alloc] init];
        // 设置播放地址，直播、点播都可以
        playerModel.videoURL = _url;
        // 开始播放
        [_playerView playWithModel:playerModel];
    }
}

- (void)setInitialTime:(CGFloat)initialTime
{
    _initialTime = initialTime;
    [_playerView setStartTime:initialTime];
}

- (void)setDuration:(CGFloat)duration
{
    _duration = duration;
    [_playerView setPlayDuration:duration];
}

- (void)setLoop:(BOOL)loop
{
    _loop = loop;
    [_playerView setLoop:loop];
}

- (void)setMute:(BOOL)mute
{
    _mute = mute;
    [_playerView mute:mute];
}

- (void)setShowControls:(BOOL)showControls
{
    _showControls = showControls;
    [_playerView setHidden:!showControls];
}


- (void)setDanmuList:(NSArray *)danmuList
{
    _danmuList = danmuList;
    NSMutableArray *array = [NSMutableArray array];
    for (WADanmu *danmu in danmuList) {
        CFDanmaku *danmuku = [[CFDanmaku alloc] init];
        NSMutableAttributedString *contentStr = [[NSMutableAttributedString alloc] initWithString:danmu.text ?: @""
                                                                                       attributes:@
        {
            NSFontAttributeName : [UIFont systemFontOfSize:15],
            NSForegroundColorAttributeName : danmu.color ?: [UIColor blackColor]
        }];
        danmuku.contentStr = contentStr;
        danmuku.timePoint = danmu.time;
        [array addObject:danmuku];
    }
    [_playerView setDanmuList:[array copy]];
}

- (void)setShowDanmuBtn:(BOOL)showDanmuBtn
{
    _showDanmuBtn = showDanmuBtn;
    ((SPDefaultControlView *)_playerView.controlView).disableDanmakuBtn = !showDanmuBtn;
}

- (void)setShowDanmu:(BOOL)showDanmu
{
    _showDanmu = showDanmu;
    _playerView.enableDanmu = showDanmu;
    if (_showDanmu) {
        ((SPDefaultControlView *)_playerView.controlView).danmakuBtn.selected = YES;
    } else {
        ((SPDefaultControlView *)_playerView.controlView).danmakuBtn.selected = NO;
    }
}

- (void)setEnablePageGesture:(BOOL)enablePageGesture
{
    _enablePageGesture = enablePageGesture;
    _vslideGesture = enablePageGesture;
    _playerView.disableVerticalGesture = !_enablePageGesture;
}

- (void)setVslideGesture:(BOOL)vslideGesture
{
    _vslideGesture = vslideGesture;
    _enablePageGesture = vslideGesture;
    _playerView.disableVerticalGesture = !_vslideGesture;
}

- (void)setVslideGestureInFullscreen:(BOOL)vslideGestureInFullscreen
{
    _vslideGestureInFullscreen = vslideGestureInFullscreen;
    _playerView.disableVerticalGestureInFullScreen = !_vslideGestureInFullscreen;
}

- (void)setShowFullScreenBtn:(BOOL)showFullScreenBtn
{
    _showFullScreenBtn = showFullScreenBtn;
    ((SPDefaultControlView *)_playerView.controlView).showFullScreenBtn = showFullScreenBtn;
}

- (void)setShowProgress:(BOOL)showProgress
{
    _showProgress = showProgress;
    ((SPDefaultControlView *)_playerView.controlView).videoSlider.hidden = !showProgress;
}

- (void)setShowPlayBtn:(BOOL)showPlayBtn
{
    _showPlayBtn = showPlayBtn;
    ((SPDefaultControlView *)_playerView.controlView).startBtn.hidden = !showPlayBtn;
}

- (void)setShowCenterPlayBtn:(BOOL)showCenterPlayBtn
{
    _showCenterPlayBtn = showCenterPlayBtn;
    _playerView.showCenterPlayButton = showCenterPlayBtn;
}

- (void)setEnableProgressGesture:(BOOL)enableProgressGesture
{
    _enableProgressGesture = enableProgressGesture;
    _playerView.disableHorizontalGesture = !enableProgressGesture;
}

- (void)setObjectFit:(WAVideoPlayerObjectFit)objectFit
{
    _objectFit = objectFit;
    if (objectFit == WAVideoPlayerObjectFitContain ||
        objectFit == WAVideoPlayerObjectFitCover) {
        [_playerView setRenderMode:RENDER_MODE_FILL_EDGE];
    } else {
        [_playerView setRenderMode:RENDER_MODE_FILL_SCREEN];
    }
}

- (void)setPoster:(NSString *)poster
{
    _poster = poster;
    if (!_showControls) {
        return;
    }
    [_playerView.coverImageView sd_setImageWithURL:[NSURL URLWithString:poster]
                                         completed:^(UIImage * _Nullable image,
                                                     NSError * _Nullable error,
                                                     SDImageCacheType cacheType,
                                                     NSURL * _Nullable imageURL)
    {
        if (error) {
            NSLog(@"download poster fail:%@",error.localizedDescription);
        }
    }];
}

- (void)setShowMuteBtn:(BOOL)showMuteBtn
{
    _showMuteBtn = showMuteBtn;
    ((SPDefaultControlView *)_playerView.controlView).hideMuteBtn = !showMuteBtn;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    ((SPDefaultControlView *)_playerView.controlView).title = title;
}

- (void)setPlayBtnposition:(WAVideoPlayerPlayButtonPosition)playBtnposition
{
    _playBtnposition = playBtnposition;
    //TODO: 设置播放按钮
}

- (void)setEnablePlayGesture:(BOOL)enablePlayGesture
{
    _enablePlayGesture = enablePlayGesture;
    _playerView.disablePlayGesture = !enablePlayGesture;
}

- (void)setPictureInPictureShowProgress:(BOOL)pictureInPictureShowProgress
{
    _pictureInPictureShowProgress = pictureInPictureShowProgress;
    //TODO: 是否在小窗模式下显示播放进度
}

- (void)setEnableAutoRotation:(BOOL)enableAutoRotation
{
    _enableAutoRotation = enableAutoRotation;
    //TODO: 是否开启手机横屏时自动全屏，当系统设置开启自动旋转时生效
}

- (void)setShowScreenLockButton:(BOOL)showScreenLockButton
{
    _showScreenLockButton = showScreenLockButton;
    ((SPDefaultControlView *)_playerView.controlView).showLockBtn = showScreenLockButton;
}

- (void)setShowSnapshotButton:(BOOL)showSnapshotButton
{
    _showSnapshotButton = showSnapshotButton;
    ((SPDefaultControlView *)_playerView.controlView).disableCaptureBtn = !showSnapshotButton;
}

// 退出全屏
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

/// 影藏状态栏
/// @param completionHandler 完成回调
- (void)hideStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                                    NSDictionary *result,
                                                    NSError *error))completionHandler
{
    if (!_playerView.isFullScreen) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"hideStatusBar"
                                                           code:-1
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"player is not in fullscreen mode"
                                                       }]);
        }
        return;
    }
    [_playerView hideStatusBar];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 显示状态栏
/// @param completionHandler 完成回调
- (void)showStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                                    NSDictionary *result,
                                                    NSError *error))completionHandler
{
    if (!_playerView.isFullScreen) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"hideStatusBar"
                                                           code:-1
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"player is not in fullscreen mode"
                                                       }]);
        }
        return;
    }
    [_playerView showStatusBar];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 播放
/// @param completionHandler 完成回调
- (void)playWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler
{
    [_playerView resume];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 暂停播放
/// @param completionHandler 完成回调
- (void)pauseWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler
{
    [_playerView pause];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 停止播放
/// @param completionHandler 完成回调
- (void)stopWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler
{
    [_playerView stopPlay];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 设置播放速率
/// @param rate 播放速率
/// @param completionHandler 完成回调
- (void)playbackRate:(CGFloat)rate withCompletionHandler:(void(^)(BOOL success,
                                                                  NSDictionary *result,
                                                                  NSError *error))completionHandler
{
    [_playerView setRate:rate];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 全屏播放
/// @param direction 播放方向
/// @param completionHandler 完成回调
- (void)requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [_playerView setFullScreen:YES];
    if ([direction intValue] == 0) {
        [_playerView setRenderRotation:HOME_ORIENTATION_DOWN];
    } else if ([direction intValue] == 90) {
        [_playerView setRenderRotation:HOME_ORIENTATION_LEFT];
    } else if ([direction intValue] == -90) {
        [_playerView setRenderRotation:HOME_ORIENTATION_RIGHT];
    }
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 跳转到指定位置
/// @param position 位置
/// @param completionHandler 完成回调
- (void)seek:(CGFloat)position withCompletionHandler:(void(^)(BOOL success,
                                                              NSDictionary *result,
                                                              NSError *error))completionHandler
{
    [_playerView seekToTime:position];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

/// 发送弹幕
/// @param danmu 弹幕
/// @param completionHandler 完成回调
- (void)sendDanmu:(WADanmu *)danmu withCompletionHandler:(void(^)(BOOL success,
                                                                       NSDictionary *result,
                                                                       NSError *error))completionHandler
{
    CFDanmaku *danmuku = [[CFDanmaku alloc] init];
    
    NSMutableAttributedString *contentStr = [[NSMutableAttributedString alloc] initWithString:danmu.text ?: @""
                                                                                   attributes:@
    {
        NSFontAttributeName : [UIFont systemFontOfSize:15],
        NSForegroundColorAttributeName : danmu.color ?: [UIColor blackColor]
    }];
    danmuku.contentStr = contentStr;
    //弹幕时间为当前播放时间后推迟2秒
    danmuku.timePoint = _playerView.playCurrentTime + 2;
    [_playerView sendDanmu:danmuku];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

#pragma mark - SuperPlayerDelegate

/// 返回事件
- (void)superPlayerBackAction:(SuperPlayerView *)player
{
    
}

/// 全屏改变通知
- (void)superPlayer:(SuperPlayerView *)player
didChangefullScreen:(BOOL)fullScreen
      withDirection:(NSString *)direction
{
    if (self.fullScreenChangeBlock) {
        self.fullScreenChangeBlock(fullScreen, direction);
    }
}

/// 显示或影藏控制界面
- (void)superPlayer:(SuperPlayerView *)player
    controlsDidShow:(BOOL)show
{
    if (self.controlsToggleBlock) {
        self.controlsToggleBlock(show);
    }
}

/// 获取视频元数据
- (void)superPlayer:(SuperPlayerView *)player
didLoadMetaDataOfSize:(CGSize)size
           duration:(CGFloat)duration
{
    if (self.loadedMetadataBlock) {
        self.loadedMetadataBlock(size.width,
                                 size.height,
                                 duration);
    }
}
/// 开始/恢复播放
- (void)superPlayerDidResume:(SuperPlayerView *)player
{
    if (self.playBlock) {
        self.playBlock();
    }
}
/// 暂停播放
- (void)superPlayerDidPause:(SuperPlayerView *)player
{
    if (self.pauseBlock) {
        self.pauseBlock();
    }
}
/// 开始缓冲
- (void)superPlayerDidStartBuffering:(SuperPlayerView *)player
{
    if (self.waitingBlock) {
        self.waitingBlock();
    }
}
/// 播放结束通知
- (void)superPlayerDidEnd:(SuperPlayerView *)player
{
    if (self.endBlock) {
        self.endBlock();
    }
}
/// 播放进度更新
- (void)superPlayer:(SuperPlayerView *) player
          didUpdate:(CGFloat)currentTime
           duration:(CGFloat)duration
{
    if (self.timeUpdateBlock) {
        self.timeUpdateBlock(currentTime, duration);
    }
}

/// 加载进度变化时触发
- (void)superPlayer:(SuperPlayerView *)player
     didEndProgress:(CGFloat)buffered
{
    if (self.progressBlock) {
        self.progressBlock(buffered);
    }
}
/// 播放错误通知
- (void)superPlayerError:(SuperPlayerView *)player errCode:(int)code errMessage:(NSString *)why
{
    if (self.errorBlock) {
        self.errorBlock();
    }
}
/// seek到某位置
- (void)superPlayer:(SuperPlayerView *)player
      didSeekToTime:(CGFloat)position
{
    if (self.seekCompleteBlock) {
        self.seekCompleteBlock(position);
    }
}

@end
