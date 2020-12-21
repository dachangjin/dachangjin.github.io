//
//  MAAudioManager.m
//  MiniAppSDK
//
//  Created by wellingjin on 4/12/2018.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MAAudioManager.h"
#import "MAAudioPlayer.h"
#import "WebView.h"
#import "Weapps.h"
#import <AVFoundation/AVFoundation.h>
#import "QMAAudioSessionHelper.h"

#define LIST_LIMITED_COUNT 100

@implementation MAAudioManager {
    NSMutableDictionary<NSNumber *,MAAudioPlayer *> *_playerList;
    NSMutableArray<MAAudioPlayer *> *_pausePlayerList;
    QMAAudioSessionHelper *_audioSessionHelper;
    BOOL _hasActivedAudioSession;
}

- (instancetype) init {
    if (self = [super init]) {
        _playerList = [NSMutableDictionary new];
        _pausePlayerList = [NSMutableArray new];
        _obeyMuteSwitch = YES;
        _mixWithOther = YES;
        
        [self createSessionHelper];
    }
    return self;
}

- (void)destroyPlayerWithID:(NSInteger)audioID {
    @synchronized (self) {
        __block MAAudioPlayer* player = _playerList[@(audioID)];
        if (player) {
            [player stop];
            [_playerList removeObjectForKey:@(audioID)];
            
            //将MAAudioManager的释放移到工作线程
            dispatch_async([MAAudioPlayer maAudioQueue], ^{
                player = nil;
            });
        }
    }
}

- (void)popSomePlayers {
    @synchronized (self) {
        NSMutableArray<NSNumber *> *needRemoveKeys = [NSMutableArray arrayWithCapacity:1];
        for (NSNumber *key in _playerList) {
            MAAudioPlayer *play = _playerList[key];
            if ([play isPlaying] == NO) {
                [play stop];
                [needRemoveKeys addObject:key];
            }
        }
        
        NSMutableArray *needRemoveAudioPlayers = [NSMutableArray new];
        for (NSNumber *key in needRemoveKeys) {
            [needRemoveAudioPlayers addObject:_playerList[key]];
            [_playerList removeObjectForKey:key];
        }
        //将MAAudioManager的释放移到工作线程
        dispatch_async([MAAudioPlayer maAudioQueue], ^{
            [needRemoveAudioPlayers removeAllObjects];
        });
    }
}

- (MAAudioPlayer*)createAudioPlayerWithWebView:(WebView * _Nullable)webView {
    MAAudioPlayer *player = [[MAAudioPlayer alloc] init];
    player.audioManager = self;
    if (webView) {
        [self addLifeCycleManager:webView player:player];
    }
    @synchronized (self) {
        if (_playerList.count > LIST_LIMITED_COUNT) {
            [self popSomePlayers];
        }
        [_playerList setObject:player forKey:@(player.audioID)];
    }
    return player;
}

- (void)addLifeCycleManager:(WebView *)webView player:(MAAudioPlayer *)player{
    @weakify(player);
    [webView addViewDidAppearBlock:^(WebView * webView) {
        @strongify(player);
        if (player.isPausedWhenDisappear) {
            [player play];
            player.isPausedWhenDisappear = NO;
        }
    }];
    
    [webView addViewWillDisappearBlock:^(WebView * webView) {
        @strongify(player);
        if (player.isPlaying) {
            [player pause];
            player.isPausedWhenDisappear = YES;
        }
    }];
    @weakify(self)
    [webView addViewWillDeallocBlock:^(WebView * webView) {
        @strongify(self);
        @strongify(player);
        [self destroyPlayerWithID:player.audioID];
    }];
}

- (MAAudioPlayer*)getPlayerWithID:(NSInteger)audioID {
    @synchronized (self) {
        MAAudioPlayer *player = _playerList[@(audioID)];
        return player;
    }
}

- (void)pausePlayingPlayer
{
    @synchronized (self) {
        for (NSNumber *key in [_playerList allKeys]) {
            MAAudioPlayer *player = _playerList[key];
            if ([player isPlaying]) {
                [player pause];
                [_pausePlayerList addObject:player];
            }
        }
    }
}

- (void)resumePlayedPlayer
{
    @synchronized (self) {
        for (MAAudioPlayer *player in _pausePlayerList) {
            [player play];
        }
        [_pausePlayerList removeAllObjects];
    }
}

- (void)removeAllAudio {
    @synchronized (self) {
        for (MAAudioPlayer *player in [_playerList allValues]) {
            [player stop];
        }
        
        NSMutableDictionary *dict = [_playerList mutableCopy];
        [_playerList removeAllObjects];
        //将MAAudioManager的释放移到工作线程
        dispatch_async([MAAudioPlayer maAudioQueue], ^{
            [dict removeAllObjects];
        });
    }
}

#pragma mark - audio session
- (void)activeAudioSession:(BOOL)mixWithOther obeyMuteSwitch:(BOOL)obeyMuteSwitch {
    @synchronized (self) {
        _mixWithOther = mixWithOther;
        _obeyMuteSwitch = obeyMuteSwitch;
        _hasActivedAudioSession = NO;
        [self activeAudioSession];
    }
}

#pragma mark - audio session
- (void)createSessionHelper {
    @weakify(self);
    void (^ resumePlayBlock)(void) = ^{
        @strongify(self);
        if (!self) {
            return;
        }
        
        self -> _hasActivedAudioSession = YES;
        for (NSNumber *key in self -> _playerList) {
            MAAudioPlayer *player = self -> _playerList[key];
            [player resumePlay];
        }
    };
    
    void (^ pauseBlock)(void) = ^{
        @strongify(self);
        if (!self || self.mixWithOther) {
            return;
        }
        
        self -> _hasActivedAudioSession = NO;
        for (NSNumber *key in self -> _playerList) {
            MAAudioPlayer *player = self -> _playerList[key];
            [player interruptPlay];
        }
    };
    
    if ([[Weapps sharedApps] respondsToSelector:@selector(createAudioSessionHelplerResumePlayBlock:pauseBlock:)]) {
        _audioSessionHelper = (QMAAudioSessionHelper *)[[Weapps sharedApps] createAudioSessionHelplerResumePlayBlock:resumePlayBlock
                                                                                                              pauseBlock:pauseBlock];
    }
//
}

- (void)activeAudioSession {
    @synchronized (self) {
        if (_hasActivedAudioSession) {
            return;
        }
    
        if ([[Weapps sharedApps]
             respondsToSelector:@selector(activeAudioSessionForAudioPlayer:mixWithOther:obeyMuteSwitch:)]) {
            [[Weapps sharedApps] activeAudioSessionForAudioPlayer:_audioSessionHelper
                                                                                  mixWithOther:self.mixWithOther
                                                                                obeyMuteSwitch:self.obeyMuteSwitch];
            _hasActivedAudioSession = YES;
        }
    }
}

- (void)deactiveAudioSessionIfNeeded {
    @synchronized (self) {
        BOOL shouldDeactive = YES;
        for (NSNumber *key in self -> _playerList) {
            MAAudioPlayer *player = self -> _playerList[key];
            if ([player isPlaying]) {
                shouldDeactive = NO;
                return;
            }
        }
        if (shouldDeactive
            && _hasActivedAudioSession
            && [[Weapps sharedApps] respondsToSelector:@selector(deactiveAudioSession:)]) {
            [[Weapps sharedApps] deactiveAudioSession:_audioSessionHelper];
            _hasActivedAudioSession = NO;
        }
    }
}

@end
