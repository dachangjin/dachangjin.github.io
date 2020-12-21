//
//  MAAudioManager.h
//  MiniAppSDK
//
//  Created by wellingjin on 4/12/2018.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MAAudioPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class WebView;
@interface MAAudioManager : NSObject

@property(nonatomic, assign, readonly) BOOL mixWithOther;                         // 是否混播，默认为YES
@property(nonatomic, assign, readonly) BOOL obeyMuteSwitch;                       // 是否遵循系统静音开关，默认为YES

- (void)activeAudioSession:(BOOL)mixWithOther obeyMuteSwitch:(BOOL)obeyMuteSwitch;

// 小程序，如果传入webview，audio生命周期受webview管理
- (MAAudioPlayer *)createAudioPlayerWithWebView:(WebView * _Nullable)webView;

- (void)destroyPlayerWithID:(NSInteger)audioID;

- (MAAudioPlayer*)getPlayerWithID:(NSInteger)audioID;

// 慎用，会清空所有的audio，并且没法恢复，目前只用在退出小程序时
- (void)removeAllAudio;

//小游戏专用api: 退出前台时暂停所有在播放的player 使用场景:关闭小游戏
- (void)pausePlayingPlayer;

//小游戏专用api: 进入前台时播放之前被暂停的player 使用场景:重新进入同一小游戏
- (void)resumePlayedPlayer;

- (void)activeAudioSession;

- (void)deactiveAudioSessionIfNeeded;

@end
NS_ASSUME_NONNULL_END
