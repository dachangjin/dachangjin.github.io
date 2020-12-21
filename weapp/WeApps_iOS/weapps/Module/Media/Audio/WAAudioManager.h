//
//  WAAudioManager.h
//  weapps
//
//  Created by tommywwang on 2020/7/13.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAAudioPlayer.h"
#import "WebView.h"
NS_ASSUME_NONNULL_BEGIN

#define K_BACKGROUND_AUDIO_ID NSIntegerMax

@class Weapps;
@interface WAAudioManager : NSObject

- (id)initWithWeapps:(Weapps *)app;
/// 创建AudioPlayer并返回id
/// @param webView  当前请求webView，会被弱引用
- (NSInteger)createAudioPlayerWithWebView:(WebView *)webView;

- (void)setAudioPlayerObeyMuteSwith:(BOOL)obeyMuteSwitch;

- (void)activeAudioSessionMixWithOther:(BOOL)mixWithOther andObeyMuteSwitch:(BOOL)obeyMuteSwitch;

- (void)setAudioPlayerSrc:(NSString *)src withAudioId:(NSInteger)audioId;

- (void)setAudioPlayerStartTime:(float)startTime withAudioId:(NSInteger)audioId;

- (void)setAudioPlayerAutoPlay:(BOOL)autoPlay withAudioId:(NSInteger)audioId;

- (void)setAudioPlayerLoop:(BOOL)loop withAudioId:(NSInteger)audioId;

- (void)setAudioPlayerVolume:(float)volume withAudioId:(NSInteger)audioId;

- (void)setAudioPlayerPlaybackRate:(float)playbackRate withAudioId:(NSInteger)audioId;

- (float)getAudioPlayerDurationWithAudioId:(NSInteger)audioId;

- (float)getAudioPlayerCurrentTimeWithAudioId:(NSInteger)audioId;

- (BOOL)isAudioPlayerPausedWithAudioId:(NSInteger)audioId;

- (float)getAudipPlayerBufferedWithAudioId:(NSInteger)audioId;
 
- (void)destroyAudioPlayerWithAudioId:(NSInteger)audioId;

- (void)playAudioPlayerWithAudioId:(NSInteger)audioId;

- (void)pauseAudioPlayerWithAudioId:(NSInteger)audioId;

- (void)stopAudioPlayerWithAudioId:(NSInteger)audioId;

- (void)seekAudioPlayerTo:(float)position withAudioId:(NSInteger)audioId;


- (void)setAudioPlayerState:(NSDictionary *)state
                withAudioId:(NSUInteger)audioId
          completionHandler:(void(^)(BOOL success,NSError *error))completionHandler;


- (NSDictionary *)getAudioPlayerStateById:(NSUInteger)audioId;

- (void)webView:(WebView *)webView onCanPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offCanPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onEndedCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offEndedCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onErrorCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offErrorCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onPauseCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offPauseCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offPlayCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onSeekedCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offSeekedCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onSeekingCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offSeekingCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onStopCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offStopCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onTimeUpdateCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offTimeUpdateCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onWaitingCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offWaitingCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onNextCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offNextCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView onPrevCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

- (void)webView:(WebView *)webView offPrevCallback:(NSString *)callback withAudioId:(NSInteger)audioId;

@end

NS_ASSUME_NONNULL_END
