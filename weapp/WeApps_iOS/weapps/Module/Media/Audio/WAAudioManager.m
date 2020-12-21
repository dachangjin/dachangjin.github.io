//
//  WAAudioManager.m
//  weapps
//
//  Created by tommywwang on 2020/7/13.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAAudioManager.h"
#import "MAAudioPlayer.h"
#import "MAAudioManager.h"
#import "EventListenerList.h"
#import "Weapps.h"
#import "WKWebViewHelper.h"
#import "NetworkHelper.h"
#import <MediaPlayer/MediaPlayer.h>
#import "WACallbackModel.h"

@interface WABackgroundSong : NSObject

@property (nonatomic, copy) NSString *src;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *epname;
@property (nonatomic, copy) NSString *singer;
@property (nonatomic, copy) NSString *coverImgUrl;
@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, assign, readonly) BOOL isCoverImgUrlChanged;

@end

@implementation WABackgroundSong

- (void)setCoverImgUrl:(NSString *)coverImgUrl
{
    _isCoverImgUrlChanged = [_coverImgUrl isEqualToString:coverImgUrl] ? YES : NO;
    _coverImgUrl = coverImgUrl;
}

- (void)setCoverImage:(UIImage *)coverImage
{
    _coverImage = coverImage;
    _isCoverImgUrlChanged = NO;
}

@end

@interface WAAudioManager ()
@end

@interface WAInnerAudioModel : WACallbackModel

@property (nonatomic, weak) MAAudioPlayer *player;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *canPlayCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *endedCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *errorCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *pauseCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *playCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *seekingCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *seekedCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *stopCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *timeUpdateCallbackDict;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *waitingCallbackDict;

//添加或删除回调
- (void)webView:(WebView *)webView onCanPlayCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offCanPlayCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onEndedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offEndedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onErrorCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offErrorCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onPauseCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offPauseCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onPlayCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offPlayCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onSeekedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offSeekedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onSeekingCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offSeekingCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onStopCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offStopCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onTimeUpdateCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offTimeUpdateCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onWaitingCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offWaitingCallback:(NSString *)callback;

//回调
- (void)onError:(MAAudioStopCallBackErrorCode)errorCode withIdentifier:(NSInteger)audioId;
- (void)onAudioPlayerStatusUpdate:(MAPlayerStatus)status;
- (void)onAudioPlayerProgressUpdate:(CGFloat)currentTime;
- (void)onAudioPlayerEnd;
- (void)onNext;
- (void)onPrev;


@end

@implementation WAInnerAudioModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _canPlayCallbackDict = [NSMutableDictionary dictionary];
        _endedCallbackDict = [NSMutableDictionary dictionary];
        _errorCallbackDict = [NSMutableDictionary dictionary];
        _pauseCallbackDict = [NSMutableDictionary dictionary];
        _playCallbackDict = [NSMutableDictionary dictionary];
        _seekingCallbackDict = [NSMutableDictionary dictionary];
        _seekedCallbackDict = [NSMutableDictionary dictionary];
        _stopCallbackDict = [NSMutableDictionary dictionary];
        _timeUpdateCallbackDict = [NSMutableDictionary dictionary];
        _waitingCallbackDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setPlayer:(MAAudioPlayer *)player
{
    _player = player;
    @weakify(self)
    _player.statusChangedBlock = ^(MAPlayerStatus status, MAAudioStopCallBackErrorCode errorCode) {
        @strongify(self)
        if (errorCode == MAAudioStopCallBackNoError) {
            [self onAudioPlayerStatusUpdate:status];
        }else {
            [self onError:errorCode withIdentifier:player.audioID];
        }
    };
    _player.playingProgressBlock = ^(CGFloat currentTime) {
        @strongify(self)
        [self onAudioPlayerProgressUpdate:currentTime];
    };
    _player.playToEndBlock = ^{
        @strongify(self)
        [self onAudioPlayerEnd];
    };

}

#pragma mark add and remove callbacks
- (void)webView:(WebView *)webView onCanPlayCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.canPlayCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offCanPlayCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.canPlayCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onEndedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.endedCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offEndedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.endedCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onErrorCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.errorCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offErrorCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.errorCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onPauseCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.pauseCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offPauseCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.pauseCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onPlayCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.playCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offPlayCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.playCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onSeekedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.seekedCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offSeekedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.seekedCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onSeekingCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.seekingCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offSeekingCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.seekingCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onStopCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.stopCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offStopCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.stopCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onTimeUpdateCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.timeUpdateCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offTimeUpdateCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.timeUpdateCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView onWaitingCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.waitingCallbackDict callback:callback];
}

- (void)webView:(WebView *)webView offWaitingCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.waitingCallbackDict callback:callback];
}


#pragma mark doCallbacks
- (void)onAudioPlayerStatusUpdate:(MAPlayerStatus)status
{
    switch (status) {
        case MAPlayerStatusReadyToPlay:
            [self doCallbackInCallbackDict:self.canPlayCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusPlaying:
            [self doCallbackInCallbackDict:self.playCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusBuffering:
            [self doCallbackInCallbackDict:self.waitingCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusPause:
            [self doCallbackInCallbackDict:self.pauseCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusSeeking:
            [self doCallbackInCallbackDict:self.seekingCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusSeeked:
            [self doCallbackInCallbackDict:self.seekedCallbackDict andResult:@{@"src": self.player.url}];
            break;
        case MAPlayerStatusStop:
            [self doCallbackInCallbackDict:self.stopCallbackDict andResult:@{@"src": self.player.url}];
            break;
        default:
            break;
    }
}


- (void)onAudioPlayerEnd
{
    [self doCallbackInCallbackDict:self.endedCallbackDict andResult:@{@"src": self.player.url}];
}

- (void)onAudioPlayerProgressUpdate:(CGFloat)currentTime
{
    [self doCallbackInCallbackDict:self.timeUpdateCallbackDict andResult:nil];
}

- (void)onError:(MAAudioStopCallBackErrorCode)errorCode withIdentifier:(NSInteger)audioId
{
    NSString *info = @"未知错误";
    switch (errorCode) {
        case MAAudioStopCallBackSystemError:
            info = @"系统错误";
            break;
        case MAAudioStopCallBackNetWorkError:
            info = @"网络错误";
            break;
        case MAAudioStopCallBackFileError:
            info = @"文件错误";
            break;
        case MAAudioStopCallBackFormatError:
            info = @"格式错误";
            break;
        default:
            break;
    }
    [self doCallbackInCallbackDict:self.errorCallbackDict andResult:@{
        @"errCode"      : @(errorCode),
        @"errMsg"       : info,
        @"identifier"   : [@(audioId) stringValue]
    }];
}

//子类重写
- (void)onNext{}

- (void)onPrev{}

@end



@interface WABackgroundAudioModel : WAInnerAudioModel

@property (nonatomic, strong) WABackgroundSong *bgSong;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *nextCallbackDictt;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *prevCallbackDictt;

- (void)webView:(WebView *)webView onNextCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offNextCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onPrevCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offPrevCallback:(NSString *)callback;
@end

@implementation WABackgroundAudioModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nextCallbackDictt = [NSMutableDictionary dictionary];
        _prevCallbackDictt = [NSMutableDictionary dictionary];
        _bgSong = [[WABackgroundSong alloc] init];
    }
    return self;
}


- (void)updateNowPlayingInfo
{
    __block NSMutableDictionary * songDict = [[NSMutableDictionary alloc] init];
    //设置歌曲题目
    [songDict setObject:_bgSong.title forKey:MPMediaItemPropertyTitle];
    //设置歌手名
    [songDict setObject:_bgSong.singer forKey:MPMediaItemPropertyArtist];
    //设置专辑名
    [songDict setObject:_bgSong.epname forKey:MPMediaItemPropertyAlbumTitle];
    //设置歌曲时长
    [songDict setObject:@(self.player.duration) forKey:MPMediaItemPropertyPlaybackDuration];
    //设置已经播放时长
    [songDict setObject:@(self.player.currentTime) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [songDict setObject:@(self.player.rate) forKey:MPNowPlayingInfoPropertyPlaybackRate];
    //下载海报图片
    if ((!_bgSong.coverImage || _bgSong.isCoverImgUrlChanged) && _bgSong.coverImgUrl.length) {
        [NetworkHelper loadImageWithURL:[NSURL URLWithString:_bgSong.coverImgUrl]
                               progress:nil
                              completed:^(UIImage * _Nullable image,
                                          NSData * _Nullable data,
                                          NSError * _Nullable error,
                                          BOOL finished,
                                          NSURL * _Nullable imageURL) {
            self->_bgSong.coverImage = image;
            //设置显示的海报图片
            if (image) {
                [songDict setObject:[[MPMediaItemArtwork alloc] initWithImage:image]
                             forKey:MPMediaItemPropertyArtwork];
            }
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
        }];
    }
    if (_bgSong.coverImage) {
        [songDict setObject:[[MPMediaItemArtwork alloc] initWithImage:_bgSong.coverImage]
        forKey:MPMediaItemPropertyArtwork];
    }
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
    WALOG(@"duration:%f, cuttentTime:%f",self.player.duration,self.player.currentTime);
}

- (void)setPlayer:(MAAudioPlayer *)player
{
    [super setPlayer:player];

    @weakify(self)
    self.player.statusChangedBlock = ^(MAPlayerStatus status, MAAudioStopCallBackErrorCode errorCode) {
        @strongify(self)
        if (errorCode == MAAudioStopCallBackNoError) {
            [self onAudioPlayerStatusUpdate:status];
        }else {
            [self onError:errorCode withIdentifier:player.audioID];
        }
        if (status == MAPlayerStatusReadyToPlay
            || status == MAPlayerStatusPause
            || status == MAPlayerStatusPlaying
            || status == MAPlayerStatusSeeked) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == MAPlayerStatusReadyToPlay || status == MAPlayerStatusPlaying) {
                    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                }
                [self updateNowPlayingInfo];
            });
        } else if (status == MAPlayerStatusStop) {
            //播放完毕或停止后释放控制权
            dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
            });
        }
    };
    self.player.playingProgressBlock = ^(CGFloat currentTime) {
        @strongify(self)
        [self onAudioPlayerProgressUpdate:currentTime];
    };
    
    MPRemoteCommandCenter *commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [commandCenter.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self)
        [self.player pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    [commandCenter.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self)
        [self.player play];
        return MPRemoteCommandHandlerStatusSuccess;
    }];

    [commandCenter.previousTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self)
        [self onPrev];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [commandCenter.nextTrackCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        @strongify(self)
        [self onNext];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
            
    //在控制台拖动进度条调节进度
    if (@available(iOS 9.1, *)) {
        [commandCenter.changePlaybackPositionCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
            @strongify(self)
            MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            [self.player manulSeekToTime:playbackPositionEvent.positionTime];
            return MPRemoteCommandHandlerStatusSuccess;
        }];
    } else {
        // Fallback on earlier versions
        MPRemoteCommandHandlerStatus (^block)(MPRemoteCommandEvent *) = ^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event){
            @strongify(self)
            MPChangePlaybackPositionCommandEvent * playbackPositionEvent = (MPChangePlaybackPositionCommandEvent *)event;
            [self.player manulSeekToTime:playbackPositionEvent.positionTime];
            return MPRemoteCommandHandlerStatusSuccess;
        };
        [commandCenter.seekForwardCommand addTargetWithHandler:block];
        [commandCenter.seekBackwardCommand addTargetWithHandler:block];
    }
}

- (void)webView:(WebView *)webView onNextCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.nextCallbackDictt callback:callback];
}

- (void)webView:(WebView *)webView offNextCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.nextCallbackDictt callback:callback];
}

- (void)webView:(WebView *)webView onPrevCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.prevCallbackDictt callback:callback];
}

- (void)webView:(WebView *)webView offPrevCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.prevCallbackDictt callback:callback];
}


- (void)onNext
{
    [self doCallbackInCallbackDict:self.nextCallbackDictt andResult:nil];
}

- (void)onPrev
{
    [self doCallbackInCallbackDict:self.prevCallbackDictt andResult:nil];
}


@end





@implementation WAAudioManager
{
    MAAudioManager *_manager;
    NSMutableDictionary<NSNumber *, WAInnerAudioModel *> *_audioModels;
    NSLock                  *_audioModelLock;
    __weak Weapps           *_app;
    MAAudioPlayer           *_backgroundAudioPlayer;
    WABackgroundAudioModel  *_backgroundAudioModel;
    
}

- (id)initWithWeapps:(Weapps *)app;
{
    self = [super init];
    if (self) {
        _app = app;
        _audioModels = [NSMutableDictionary dictionary];
        _audioModelLock = [[NSLock alloc] init];
        _manager = [[MAAudioManager alloc] init];
    }
    return self;
}

- (WABackgroundAudioModel *)bgAudioModel
{
    if (!_backgroundAudioModel) {
        _backgroundAudioModel = [[WABackgroundAudioModel alloc] init];
        _backgroundAudioPlayer = [[MAAudioPlayer alloc] initWithAudioID:K_BACKGROUND_AUDIO_ID];
        _backgroundAudioModel.player = _backgroundAudioPlayer;
    }
    return _backgroundAudioModel;
}


- (NSInteger)createAudioPlayerWithWebView:(WebView *)webView
{
    MAAudioPlayer *player = [_manager createAudioPlayerWithWebView:webView];
    player.startTime = 0;
    player.autoPlay = NO;
    player.loop = NO;
    player.volume = 1;
    [player setRate:1];
    WAInnerAudioModel *model = [[WAInnerAudioModel alloc] init];
    model.player = player;
    [self addAudioModel:model withKey:@(player.audioID)];
    [self addLifeCycleManager:webView audioId:player.audioID];
    return player.audioID;
}


- (void)setAudioPlayerObeyMuteSwith:(BOOL)obeyMuteSwitch
{    
    [_manager activeAudioSession:_manager.mixWithOther obeyMuteSwitch:obeyMuteSwitch];
}


- (void)activeAudioSessionMixWithOther:(BOOL)mixWithOther andObeyMuteSwitch:(BOOL)obeyMuteSwitch
{
    [_manager activeAudioSession:mixWithOther obeyMuteSwitch:obeyMuteSwitch];
}


- (MAAudioPlayer *)getPlayWithAudioId:(NSInteger)audioId
{
    return [_manager getPlayerWithID:audioId];
}

//删除相关数据
- (void)destroyAudioPlayerWithAudioId:(NSInteger)audioId
{
    [self checkIfPlayerExistWithAudioId:audioId];
    [self removeAudioModelWithKey:@(audioId)];
    [_manager destroyPlayerWithID:audioId];
}


- (void)playAudioPlayerWithAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] play];
    if (audioId == K_BACKGROUND_AUDIO_ID) {
        //背景音乐开启远程控制
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
}

- (void)pauseAudioPlayerWithAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] pause];
}

- (void)stopAudioPlayerWithAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] stop];
}

- (void)seekAudioPlayerTo:(float)position withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] manulSeekToTime:position];
}


- (void)setBackgroundSongWithInfo:(NSDictionary *)info
{
    NSString *src = info[@"src"];
    
    CGFloat playbackRate = 1.0;
    if (info[@"playbackRate"]) {
        playbackRate = [info[@"playbackRate"] floatValue];
    }
    if (playbackRate < 0.5 || playbackRate > 2) {
        playbackRate = 1.0;
    }
    CGFloat startTime = [info[@"startTime"] floatValue];
    
    WABackgroundAudioModel *model = [self bgAudioModel];
    
    model.bgSong.src = src;
    model.bgSong.title = info[@"title"];
    model.bgSong.epname = info[@"epname"];
    model.bgSong.singer = info[@"singer"];
    model.bgSong.coverImgUrl = info[@"coverImgUrl"];
    
    
    MAAudioPlayer *player = model.player;
    [player setRate:playbackRate];
    [player setStartTime:startTime];
    
    //src为空就停止
    if (src.length == 0) {
        return;
    }
    [player setUrl:src];
    [player play];
}

- (void)setAudioPlayerState:(NSDictionary *)state
                withAudioId:(NSUInteger)audioId
          completionHandler:(void(^)(BOOL success,NSError *error))completionHandler
{
    MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
    if (!player) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"setAudioPlayerState"
                                                      code:-1
                                                  userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find audioPlayer with id:{%lu}",(unsigned long)audioId]
            }]);
        }
        return;
    }
    
    NSString *src = state[@"src"];
    
    CGFloat playbackRate = 1.0;
    if (state[@"playbackRate"]) {
        playbackRate = [state[@"playbackRate"] floatValue];
    }
    if (playbackRate < 0.5 || playbackRate > 2) {
        playbackRate = 1.0;
    }
    CGFloat startTime = [state[@"startTime"] floatValue];
    [player setRate:playbackRate];
    [player setStartTime:startTime];
    
    
    if (audioId == K_BACKGROUND_AUDIO_ID) {
        //背景音乐
        WABackgroundAudioModel *model = [self bgAudioModel];

        model.bgSong.src = src;
        model.bgSong.title = state[@"title"];
        model.bgSong.epname = state[@"epname"];
        model.bgSong.singer = state[@"singer"];
        model.bgSong.coverImgUrl = state[@"coverImgUrl"];
        player.autoPlay = YES;
    } else {
        BOOL autoPlay = NO;
        if ([state[@"autoplay"] boolValue]) {
            autoPlay = YES;
        }
        player.autoPlay = YES;
        BOOL loop = NO;
        if ([state[@"loop"] boolValue]) {
            loop = YES;
            player.loop = loop;
        }
        CGFloat volume = 0.5;
        if (state[@"volume"] && [state[@"volume"] isKindOfClass:[NSNumber class]]) {
            volume = [state[@"volume"] floatValue];
        }
        player.volume = volume;
//        BOOL obeyMuteSwitch = YES;
//        if (state[@"obeyMuteSwitch"] && ![state[@"obeyMuteSwitch"] boolValue]) {
//            obeyMuteSwitch = NO;
//        }
        
    }
    
    //src为空就停止
    if (src.length == 0) {
        return;
    }
    [player setUrl:src];
    [player play];
}



- (NSDictionary *)getAudioPlayerStateById:(NSUInteger)audioId
{
    if (audioId == K_BACKGROUND_AUDIO_ID) {
        return [self getBackgroundAudioState];
    } else {
        MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        kWA_DictSetObjcForKey(dict, @"src", player.url)
        kWA_DictSetObjcForKey(dict, @"autoplay", @(player.autoPlay))
        kWA_DictSetObjcForKey(dict, @"loop", @(player.loop))
        kWA_DictSetObjcForKey(dict, @"volume", @(player.volume))
        kWA_DictSetObjcForKey(dict, @"startTime", @(player.startTime))
        kWA_DictSetObjcForKey(dict, @"playbackRate", @(player.rate))
        kWA_DictSetObjcForKey(dict, @"duration", @(player.duration))
        kWA_DictSetObjcForKey(dict, @"currentTime", @(player.currentTime))
        kWA_DictSetObjcForKey(dict, @"paused", @(!player.isPlaying))
        kWA_DictSetObjcForKey(dict, @"buffered", @(player.totalBuffer))
        kWA_DictSetObjcForKey(dict, @"obeyMuteSwitch", @(_manager.obeyMuteSwitch))
        return dict;
    }
}


- (NSDictionary *)getBackgroundAudioState
{
    WABackgroundAudioModel *model = [self bgAudioModel];
    MAAudioPlayer *player = [self bgAudioModel].player;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(dict, @"src", model.bgSong.src)
    kWA_DictSetObjcForKey(dict, @"startTime", @(player.startTime))
    kWA_DictSetObjcForKey(dict, @"title", model.bgSong.title)
    kWA_DictSetObjcForKey(dict, @"epname", model.bgSong.epname)
    kWA_DictSetObjcForKey(dict, @"singer", model.bgSong.singer)
    kWA_DictSetObjcForKey(dict, @"coverImgUrl", model.bgSong.coverImgUrl)
    kWA_DictSetObjcForKey(dict, @"playbackRate", @(player.rate))
    kWA_DictSetObjcForKey(dict, @"duration", @(player.duration))
    kWA_DictSetObjcForKey(dict, @"currentTime", @(player.currentTime))
    kWA_DictSetObjcForKey(dict, @"paused", @(!player.isPlaying))
    kWA_DictSetObjcForKey(dict, @"buffered", @(player.totalBuffer))
    return dict;
}

#pragma mark properties
- (void)setAudioPlayerSrc:(NSString *)src withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] setUrl:src];
}

- (void)setAudioPlayerStartTime:(float)startTime withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] setStartTime:startTime];
}

- (void)setAudioPlayerAutoPlay:(BOOL)autoPlay withAudioId:(NSInteger)audioId
{
    [[self  checkIfPlayerExistWithAudioId:audioId] setAutoPlay:autoPlay];
}

- (void)setAudioPlayerLoop:(BOOL)loop withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] setLoop:loop];
}

- (void)setAudioPlayerVolume:(float)volume withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] setVolume:volume];
}

- (void)setAudioPlayerPlaybackRate:(float)playbackRate withAudioId:(NSInteger)audioId
{
    [[self checkIfPlayerExistWithAudioId:audioId] setRate:playbackRate];
}

- (float)getAudioPlayerDurationWithAudioId:(NSInteger)audioId
{
    MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
    if (player) {
        return player.duration;
    }
    return 0;;
}

- (float)getAudioPlayerCurrentTimeWithAudioId:(NSInteger)audioId
{
    MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
    if (player) {
        return player.currentTime;
    }
    return 0;
}

- (BOOL)isAudioPlayerPausedWithAudioId:(NSInteger)audioId
{
    MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
    if (player) {
        return player.status == MAPlayerStatusPause;
    }
    return NO;
}

- (float)getAudipPlayerBufferedWithAudioId:(NSInteger)audioId
{
    MAAudioPlayer *player = [self checkIfPlayerExistWithAudioId:audioId];
    if (player) {
        return player.totalBuffer;
    }
    return 0;
}

//查找player，若没找到回调onError
- (MAAudioPlayer *)checkIfPlayerExistWithAudioId:(NSInteger)audioId
{
    if (audioId == K_BACKGROUND_AUDIO_ID) {
        return [self bgAudioModel].player;
    }
    MAAudioPlayer *player = [_manager getPlayerWithID:audioId];
    if (!player) {
        WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
        if (model) {
            [model onError:MAAudioStopCallBackUnknownError withIdentifier:audioId];
        }
    }
    return player;
}


#pragma mark callbacks
- (void)webView:(WebView *)webView onCanPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onCanPlayCallback:callback];
}

- (void)webView:(WebView *)webView offCanPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offCanPlayCallback:callback];
}

- (void)webView:(WebView *)webView onEndedCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onEndedCallback:callback];
}

- (void)webView:(WebView *)webView offEndedCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offEndedCallback:callback];
}

- (void)webView:(WebView *)webView onErrorCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onErrorCallback:callback];
}

- (void)webView:(WebView *)webView offErrorCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offErrorCallback:callback];
}

- (void)webView:(WebView *)webView onPauseCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onPauseCallback:callback];
}

- (void)webView:(WebView *)webView offPauseCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offPauseCallback:callback];
}

- (void)webView:(WebView *)webView onPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onPlayCallback:callback];
}

- (void)webView:(WebView *)webView offPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offPlayCallback:callback];
}

- (void)webView:(WebView *)webView onSeekedCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onSeekedCallback:callback];
}

- (void)webView:(WebView *)webView offSeekedCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offSeekedCallback:callback];
}

- (void)webView:(WebView *)webView onSeekingCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onSeekingCallback:callback];
}

- (void)webView:(WebView *)webView offSeekingCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offSeekingCallback:callback];
}

- (void)webView:(WebView *)webView onStopCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onStopCallback:callback];
}

- (void)webView:(WebView *)webView offStopCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offStopCallback:callback];
}

- (void)webView:(WebView *)webView onTimeUpdateCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onTimeUpdateCallback:callback];
}

- (void)webView:(WebView *)webView offTimeUpdateCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offTimeUpdateCallback:callback];
}

- (void)webView:(WebView *)webView onWaitingCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onWaitingCallback:callback];
}

- (void)webView:(WebView *)webView offWaitingCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
    if (!model) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offWaitingCallback:callback];
}

- (void)webView:(WebView *)webView onNextCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WABackgroundAudioModel *model = (WABackgroundAudioModel *)[self audioModelWithKey:@(audioId)];
    if (!model || ![model isKindOfClass:[WABackgroundAudioModel class]]) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onNextCallback:callback];
}

- (void)webView:(WebView *)webView offNextCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WABackgroundAudioModel *model = (WABackgroundAudioModel *)[self audioModelWithKey:@(audioId)];
    if (!model || ![model isKindOfClass:[WABackgroundAudioModel class]]) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offNextCallback:callback];
}

- (void)webView:(WebView *)webView onPrevCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WABackgroundAudioModel *model = (WABackgroundAudioModel *)[self audioModelWithKey:@(audioId)];
    if (!model || ![model isKindOfClass:[WABackgroundAudioModel class]]) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView onPrevCallback:callback];
}

- (void)webView:(WebView *)webView offPrevCallback:(NSString *)callback withAudioId:(NSInteger)audioId
{
    NSParameterAssert(audioId);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WABackgroundAudioModel *model = (WABackgroundAudioModel *)[self audioModelWithKey:@(audioId)];
    if (!model || [model isKindOfClass:[WABackgroundAudioModel class]]) {
        WALOG(@"AudioContext with auidpId:%@ not found",@(audioId));
        return;
    }
    [model webView:webView offPrevCallback:callback];
}

//随着webView的销毁，删除对应model
- (void)addLifeCycleManager:(WebView *)webView audioId:(NSInteger)audioId{
    @weakify(self)
    [webView addViewWillDeallocBlock:^(WebView * webView) {
        @strongify(self);
        WAInnerAudioModel *model = [self audioModelWithKey:@(audioId)];
        [model.player stop];
        [self removeAudioModelWithKey:@(audioId)];
    }];
}


- (void)addAudioModel:(WAInnerAudioModel *)model withKey:(NSNumber *)key
{
    NSParameterAssert(model);
    NSParameterAssert(key);
    [_audioModelLock lock];
    _audioModels[key] = model;
    [_audioModelLock unlock];
}

- (void)removeAudioModelWithKey:(NSNumber *)key
{
    NSParameterAssert(key);
    [_audioModelLock lock];
    [_audioModels removeObjectForKey:key];
    [_audioModelLock unlock];
}

- (WAInnerAudioModel *)audioModelWithKey:(NSNumber *)key
{
    
    NSParameterAssert(key);
    if ([key integerValue] == K_BACKGROUND_AUDIO_ID) {
        return [self bgAudioModel];
    }
    WAInnerAudioModel *model = nil;
    [_audioModelLock lock];
    model = _audioModels[key];
    [_audioModelLock unlock];
    return  model;
}
@end
