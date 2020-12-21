//
//  MAAudioPlayer.m
//  MiniAppSDK
//
//  Created by wellingjin on 4/12/2018.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MAAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "MAAudioManager.h"
#import "Weapps.h"
#import "IdGenerator.h"

@implementation MAAudioPlayer {
    AVPlayer *_player;
    id _timeObserver;
    BOOL _isFirstPlay;
    
    BOOL _haveAddItemObserver;
    NSLock *_lock;
    BOOL _isActive;
    BOOL _isInterrupted;
    
    //音乐播放途中切后台会暂停播放，回到前台后会继续播放。由于时序问题，可能出现没有正常恢复播放的情况。
    //该变量记录了是否需要重新尝试一次播放操作。
    BOOL _shouldRetryPlayWhenActive;
}

+ (dispatch_queue_t)maAudioQueue {
    static dispatch_queue_t maAudioQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        maAudioQueue = dispatch_queue_create("audioQueue.ma.qq.tencent", DISPATCH_QUEUE_SERIAL);
    });
    
    return maAudioQueue;
}

- (instancetype)init {
    NSUInteger audioId = [IdGenerator generateIdWithClass:[self class]];
    return [self initWithAudioID:audioId];
}

- (instancetype)initWithAudioID:(NSUInteger)audioID {
    if (self = [super init]) {
        _isFirstPlay = YES;
        _audioID = audioID;
        _volume = 1.0;
        _lock = [[NSLock alloc] init];
        _isActive = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
        
        dispatch_async([MAAudioPlayer maAudioQueue], ^{
            [self createPlayer];
        });
    }
    return self;
}

- (void)createPlayer {
    _player = [AVPlayer new];
    @weakify(self);
    _timeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0)
                                                          queue:dispatch_get_weapps_queue()
                                                     usingBlock:^(CMTime time) {
        @strongify(self);
        if (!self || ![self isPlaying]) {
            return;
        }
        self->_currentTime = CMTimeGetSeconds(time);
        if (self.playingProgressBlock) {
            self.playingProgressBlock(self->_currentTime);
        }
    }];
}

- (CGFloat)duration {
    CGFloat dt = CMTimeGetSeconds(_player.currentItem.duration);
    if (isnan(dt)) {
        dt = 0;
    }
    return dt;
}

- (void)setStatus:(MAPlayerStatus)status {
    [self setStatus:status error:nil];
}

- (void)setStatus:(MAPlayerStatus)status error:(NSError *)error {
    //MAPlayerStatusReadyToPlay比较特殊，因为可能前面的ready后播放不了，需要再次进 来播放
    if (_status == status && _status != MAPlayerStatusReadyToPlay) {
        return;
    }
    
    _status = status;
    MAAudioStopCallBackErrorCode errorCode = MAAudioStopCallBackNoError;
    if (error) {
        switch (error.code) {
            case  AVErrorFileFailedToParse:
                errorCode = MAAudioStopCallBackFileError;
                break;
            case AVErrorFileFormatNotRecognized:
                errorCode = MAAudioStopCallBackFormatError;
                break;
            case AVErrorUnknown:
                errorCode = MAAudioStopCallBackUnknownError;
                break;
            default:
                errorCode = MAAudioStopCallBackSystemError;
                break;
        }
    }
    
    if (status == MAPlayerStatusErrorNetwork) {
        errorCode = MAAudioStopCallBackNetWorkError;
    }
    
    if (status == MAPlayerStatusReadyToPlay) {
        if (_autoPlay) {//只有自动播放才需要在这里播放
            [self play];
        }
        WALOG(@"MAAudioPlayer->audioId:%zd src: %@", _audioID,_url);
    } else if (status == MAPlayerStatusFailed) {
        WALOG(@"MAAudioPlayer->audioId:%zd error: %@", _audioID,_player.error);
        [self.audioManager deactiveAudioSessionIfNeeded];
    } else if (status == MAPlayerStatusStop || status == MAPlayerStatusPause) {
        [self.audioManager deactiveAudioSessionIfNeeded];
    }
    
    WALOG(@"MAAudioPlayer->status:%zd audioId:%zd autoPlay %d",status, _audioID,_autoPlay);
    
    if (self.statusChangedBlock) {
        self.statusChangedBlock(status, errorCode);
    }
}

-(BOOL)isPlaying {
    return (_player.rate > 0 && _player.error == nil);
}

//KVO 监听
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    });
}

- (void)_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"] && [object isKindOfClass:[AVPlayerItem class]]) { // 状态
        AVPlayerItemStatus status = [(AVPlayerItem *)object status];
        if (status == AVPlayerItemStatusReadyToPlay) {
            [self setStatus:MAPlayerStatusReadyToPlay];
        } else {
            NSError *error = [(AVPlayerItem *)object error];
            WALOG(@"MAAudioPlayer: fail error: %@",[error description]);
            [self setStatus:MAPlayerStatusFailed error:error];
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) { // 缓存进度
        NSArray *array=_player.currentItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        _totalBuffer = startSeconds + durationSeconds;
        if (isnan(_totalBuffer)) {
            WALOG(@"MAAudioPlayer: startSeconds: %d, durationSeconds: %d",CMTIME_IS_INDEFINITE(timeRange.start),CMTIME_IS_INDEFINITE(timeRange.duration));
            _totalBuffer = 0;
        }
        WALOG(@"MAAudioPlayer: cache Time：%.2f", _totalBuffer);
    } else if([keyPath isEqualToString:@"playbackBufferEmpty"]){ //空缓存
        [self setStatus:MAPlayerStatusBuffering];
    }else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){ //有缓存
        if (_player.currentItem.playbackLikelyToKeepUp && _player.rate > 0) {
            [self setStatus:MAPlayerStatusPlaying];
        }
    }
}

- (void)checkFirstPlay {
    if (_isFirstPlay && _startTime > 0) {
        [self seekToTime:_startTime];
    }
    _isFirstPlay = NO;
}

- (void)audioPlay{
    //后台状态不启动播放 防止异常,若是后台播放则开启
    if (_isActive || _audioID == K_BACKGROUND_AUDIO_ID) {
        [_player play];
    }
}

- (void)play {
    _shouldRetryPlayWhenActive = YES;
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _play];
    });
}

- (void)_play {
    if ([self isPlaying]) {
        return;
    }
    [self audioPlay]; //如果是自动播放，让status来处理播放
    [self checkFirstPlay];
    if (_player.currentItem.status == AVPlayerStatusReadyToPlay && _player.rate > 0) {
        [self setStatus:MAPlayerStatusPlaying];
    }
    if (_audioID == K_BACKGROUND_AUDIO_ID) {
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    } else {
        [self.audioManager activeAudioSession];
    }
}

//这个方法务必在play之前设置
- (void)setAppID:(NSString *)appID {
    if (![_appID isEqualToString:appID]) {
        _appID = appID;
    }
}

- (void)setUrl:(NSString *)url {
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _setUrl:url];
    });
}

- (void)_setUrl:(NSString *)url {
    if (url.length == 0) {
        _url = url;
        return;
    }
    if ([_url isEqualToString:url]) {
        return;
    }
    
    _url = url;
    NSURL *musicUrl = nil;
    if ([_url hasPrefix:@"http://"] || [_url hasPrefix:@"https://"]) {
        musicUrl = [NSURL URLWithString:_url];
    } else {
        NSString *absPath = url;
        // 验证文件是否存在,to garry
        if (absPath) {
            musicUrl = [NSURL fileURLWithPath:absPath isDirectory:NO];
        }
        // 如果获取不到本地路径，再用原路径试一下
        if (musicUrl == nil) {
            musicUrl = [NSURL fileURLWithPath:url isDirectory:NO];
        }
    }
    WALOG(@"MAAudioPlayer set url : %s", url.UTF8String ? : "");
    if (musicUrl == nil) {
        return;
    }
    [self removeCurrentItemObservers];
    AVPlayerItem *songItem = [[AVPlayerItem alloc] initWithURL:musicUrl];
    [_player replaceCurrentItemWithPlayerItem:songItem];
    [self addCurrentItemObservers];
}

- (void)setVolume:(CGFloat)volume {
    _volume = volume;
    if (volume >= 0 && volume <= 1.0) {
        [_player setVolume:volume];
    }
}

- (void)stop {
    _shouldRetryPlayWhenActive = NO;
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _stop];
    });
}

- (void)_stop {
    if (_status == MAPlayerStatusStop) {
        return;
    }
    
    [_player pause];
    [self seekToTime:0];
    [self setStatus:MAPlayerStatusStop];
}

- (void)pause {
    _shouldRetryPlayWhenActive = NO;
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _pause];
    });
}

- (void)_pause {
    if (_status == MAPlayerStatusPause) {
        return;
    }
    
    [_player pause];
    [self setStatus:MAPlayerStatusPause];
}

//返回值其实没有使用，后期可以改为void.
- (BOOL)manulSeekToTime:(float)time {
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _manulSeekToTime:time];
    });
    return YES;
}

- (BOOL)_manulSeekToTime:(float)time {
    CMTime cmTime = CMTimeMake(time, 1);
    if (CMTIME_IS_INDEFINITE(cmTime) || CMTIME_IS_INVALID(cmTime)) { //!OCLINT:bitwise operator in conditional
        WALOG(@"MAAudioPlayer: INDEFINITE TIME ");
        return NO;
    }
    [self setStatus:MAPlayerStatusSeeking];
    @weakify(self);
    [_player seekToTime:cmTime completionHandler:^(BOOL finished) {
        @strongify(self);
        if (self) {
            if (finished) {
                self->_currentTime = time;
            }
            [self setStatus:MAPlayerStatusSeeked];
        }
    }];
    
    return YES;
}

//返回值其实没有使用，后期可以改为void.
- (BOOL)seekToTime:(float)time {
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _seekToTime:time];
    });
    return YES;
}

- (BOOL)_seekToTime:(float)time {
    CMTime cmTime = CMTimeMake(time, 1);
    if (CMTIME_IS_INDEFINITE(cmTime) || CMTIME_IS_INVALID(cmTime)) { //!OCLINT:bitwise operator in conditional
        WALOG(@"MAAudioPlayer: INDEFINITE TIME ");
        return NO;
    }
    
    [_player seekToTime:cmTime];
    _currentTime = time;
    return YES;
}

- (void)setRate:(float)rate
{
    if (rate == 0) {
        [self pause];
        return;
    }
    if (rate <= 2.0 && rate >= 0.5) {
        dispatch_async([MAAudioPlayer maAudioQueue], ^{
            [self _setRate:rate];
        });
    }
}

- (void)_setRate:(float)rate
{
    if (_status == MAPlayerStatusPlaying) {
        _player.rate = rate;
    }
}

- (float)rate
{
    return _player.rate;;
}

//播放结束
- (void)playToEnd:(NSNotification*)notification {
    dispatch_async([MAAudioPlayer maAudioQueue], ^{
        [self _playToEnd:notification];
    });
}

//播放结束
- (void)_playToEnd:(NSNotification*)notification {
    WALOG(@"MAAudioPlayer: play to end");
    [self setStatus:MAPlayerStatusEnded];
    
    if (self.playToEndBlock) {
        self.playToEndBlock();
    }
    
    if (self.loop) {
        [self seekToTime:0];
        [self audioPlay];
    } else {
        [self stop];
    }
}

- (void)removeCurrentItemObservers {
    if (_player.currentItem == nil) {
        return;
    }
    
    [_lock lock];
    if (_haveAddItemObserver) {
        [_player.currentItem removeObserver:self forKeyPath:@"status"];
        [_player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_player.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_player.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        
        _haveAddItemObserver = NO;
        //MAInfoLog(@"[MediaStream] player: %p , playerItem: %p, removeObserver, mainThread = %d", _player, _player.currentItem, [NSThread isMainThread]);
    }
    [_lock unlock];
}

- (void)addCurrentItemObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playToEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_player.currentItem];
    
    if (_player.currentItem == nil) {
        return;
    }
    
    [_lock lock];
    if (!_haveAddItemObserver) {
        [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [_player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        [_player.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        [_player.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
        
        _haveAddItemObserver = YES;
        //MAInfoLog(@"[MediaStream] player: %p , playerItem: %p, addObserver, mainThread = %d", _player, _player.currentItem, [NSThread isMainThread]);
    }
    [_lock unlock];
}

- (void)dealloc {
    [self removeCurrentItemObservers];
    [_player removeTimeObserver:_timeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_audioManager deactiveAudioSessionIfNeeded];
    _audioManager = nil;
}

#pragma mark - notification
- (void)willResignActive:(NSNotification *)notification {
    _isActive = NO;
    _shouldRetryPlayWhenActive = NO;
}

- (void)didBecomeActive:(NSNotification *)notification {
    _isActive = YES;
    if (_shouldRetryPlayWhenActive) {
        [self play];
        _shouldRetryPlayWhenActive = NO;
    }
}

#pragma mark - audioSession 打断和恢复
- (void)interruptPlay {
    if ([self isPlaying]) {
        [self pause];
        _isInterrupted = YES;
    }
}

- (void)resumePlay {
    if (_isInterrupted) {
        [self play];
        _isInterrupted = NO;
    }
}

@end
 
