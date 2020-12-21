//
//  WAVoiceHandler.m
//  weapps
//
//  Created by tommywwang on 2020/7/13.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVoiceHandler.h"
#import <AVFoundation/AVFoundation.h>
#import "WAAudioManager.h"
#import "MAAudioPlayer.h"
#import "Weapps.h"
#import "JSONHelper.h"

kSELString(createInnerAudioContext)
kSELString(operateInnerAudio)
kSELString(operateBackgroundAudio)

kSELString(setInnerAudioOption)
kSELString(setInnerAudioState)
kSELString(getInnerAudioState)

kSELString(setBackgroundAudioState)
kSELString(getBackgroundAudioState)

kSELString(playVoice)
kSELString(pauseVoice)
kSELString(stopVoice)
kSELString(createAudioContext)



@implementation WAVoiceHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createInnerAudioContext,
            operateInnerAudio,
            operateBackgroundAudio,
            setBackgroundAudioState,
            getBackgroundAudioState,
            setInnerAudioState,
            getInnerAudioState,
            setInnerAudioOption
        ];
    }
    return methods;
}


#pragma mark - ************************innerAudio methods*********************
JS_API(createInnerAudioContext){
    return [@([[Weapps sharedApps].audioManager createAudioPlayerWithWebView:event.webView]) stringValue];
}

JS_API(operateInnerAudio){
    kBeginCheck
    kCheck([NSString class], @"identifier", NO)
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"play")) {
        return [self js_play:event];
    } else if (kStringEqualToString(operationType, @"pause")) {
        return [self js_pause:event];
    } else if (kStringEqualToString(operationType, @"seek")) {
        return [self js_seek:event];
    } else if (kStringEqualToString(operationType, @"stop")) {
        return [self js_stop:event];
    } else if (kStringEqualToString(operationType, @"destroy")) {
        return [self js_destroy:event];
    } else if (kStringEqualToString(operationType, @"onCanplay")) {
        return [self js_onCanplay:event];
    } else if (kStringEqualToString(operationType, @"offCanplay")) {
        return [self js_offCanplay:event];
    } else if (kStringEqualToString(operationType, @"onEnded")) {
        return [self js_onEnded:event];
    } else if (kStringEqualToString(operationType, @"offEnded")) {
        return [self js_offEnded:event];
    } else if (kStringEqualToString(operationType, @"onError")) {
        return [self js_onError:event];
    } else if (kStringEqualToString(operationType, @"offError")) {
        return [self js_offError:event];
    } else if (kStringEqualToString(operationType, @"onPause")) {
        return [self js_onPause:event];
    } else if (kStringEqualToString(operationType, @"offPause")) {
        return [self js_offPause:event];
    } else if (kStringEqualToString(operationType, @"onPlay")) {
        return [self js_onPlay:event];
    } else if (kStringEqualToString(operationType, @"offPlay")) {
        return [self js_offPlay:event];
    } else if (kStringEqualToString(operationType, @"onSeeked")) {
        return [self js_offSeeked:event];
    } else if (kStringEqualToString(operationType, @"offSeeked")) {
        return [self js_offSeeked:event];
    } else if (kStringEqualToString(operationType, @"onSeeking")) {
        return [self js_onSeeking:event];
    } else if (kStringEqualToString(operationType, @"offSeeking")) {
        return [self js_offSeeking:event];
    } else if (kStringEqualToString(operationType, @"onStop")) {
        return [self js_onStop:event];
    } else if (kStringEqualToString(operationType, @"offStop")) {
        return [self js_offStop:event];
    } else if (kStringEqualToString(operationType, @"onTimeUpdate")) {
        return [self js_onTimeUpdate:event];
    } else if (kStringEqualToString(operationType, @"offTimeUpdate")) {
        return [self js_offTimeUpdate:event];
    } else if (kStringEqualToString(operationType, @"onWaiting")) {
        return [self js_onWaiting:event];
    } else if (kStringEqualToString(operationType, @"offWaiting")) {
        return [self js_offWaiting:event];
    }
    return @"";
}

JS_API(play){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager playAudioPlayerWithAudioId:[identifier integerValue]];
    return @"";
}

JS_API(pause){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager pauseAudioPlayerWithAudioId:[identifier integerValue]];
    return @"";
}

JS_API(seek){
    NSString *identifier = event.args[@"identifier"];
    kBeginCheck
    kEndCheck([NSNumber class], @"position", NO)
    [[Weapps sharedApps].audioManager seekAudioPlayerTo:[event.args[@"position"] floatValue] withAudioId:[identifier integerValue]];
    return @"";
}

JS_API(stop){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager stopAudioPlayerWithAudioId:[identifier integerValue]];
    return @"";
}

JS_API(destroy){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager destroyAudioPlayerWithAudioId:[identifier integerValue]];
    return @"";
}


#pragma mark - *********************innerAudio props****************************

JS_API(setInnerAudioState){
    kBeginCheck
    kEndCheck([NSString class], @"identifier", NO)
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager setAudioPlayerState:event.args
                                              withAudioId:[identifier integerValue]
                                        completionHandler:^(BOOL success,
                                                            NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getInnerAudioState){
    kBeginCheck
    kEndCheck([NSString class], @"identifier", NO)
    NSString *identifier = event.args[@"identifier"];
    return [JSONHelper exchengeDictionaryToString:[[Weapps sharedApps].audioManager getAudioPlayerStateById:[identifier integerValue]]];
}

//JS_API(setInnerAudioSrcSync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndCheck([NSString class], @"src", NO)
//    NSString *identifier = event.args[@"identifier"];
//    NSString *src = event.args[@"src"];
//    [[Weapps sharedApps].audioManager setAudioPlayerSrc:src withAudioId:[identifier integerValue]];
//    return @"";
//}

//JS_API(setInnerAudioStartTimeSync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndCheck([NSNumber class], @"startTime", NO)
//    NSString *identifier = event.args[@"identifier"];
//    NSNumber *startTime = event.args[@"startTime"];
//    [[Weapps sharedApps].audioManager setAudioPlayerStartTime:[startTime floatValue] withAudioId:[identifier integerValue]];
//    return @"";
//}
//
//JS_API(setInnerAudioAutoplaySync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndChecIsBoonlean(@"autoplay", NO)
//    NSString *identifier = event.args[@"identifier"];
//    BOOL autoplay = [event.args[@"autoplay"] boolValue];
//    [[Weapps  sharedApps].audioManager setAudioPlayerAutoPlay:autoplay withAudioId:[identifier integerValue]];
//    return @"";
//}
//
//JS_API(setInnerAudioLoopSync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndChecIsBoonlean(@"loop", NO)
//    NSString *identifier = event.args[@"identifier"];
//    BOOL loop = [event.args[@"loop"] boolValue];
//    [[Weapps  sharedApps].audioManager setAudioPlayerLoop:loop withAudioId:[identifier integerValue]];
//    return @"";
//}
//
//JS_API(setInnerAudioObeyMuteSwitchSync){
//    kBeginCheck
//    kEndChecIsBoonlean(@"obeyMuteSwitch", NO)
//    BOOL obeyMuteSwitch = [event.args[@"obeyMuteSwitch"] boolValue];
//    [[Weapps  sharedApps].audioManager setAudioPlayerObeyMuteSwith:obeyMuteSwitch];
//    return @"";
//}
//
//JS_API(setInnerAudioVolumeSync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndChecIsBoonlean(@"volume", NO)
//    NSString *identifier = event.args[@"identifier"];
//    NSNumber *volume = event.args[@"volume"];
//    [[Weapps  sharedApps].audioManager setAudioPlayerVolume:[volume floatValue] withAudioId:[identifier integerValue]];
//    return @"";
//}
//
//JS_API(setInnerAudioPlaybackRateSync){
//    kBeginCheck
//    kCheck([NSString class], @"identifier", NO)
//    kEndChecIsBoonlean(@"playbackRate", NO)
//    NSString *identifier = event.args[@"identifier"];
//    NSNumber *playbackRate = event.args[@"playbackRate"];
//    [[Weapps  sharedApps].audioManager setAudioPlayerPlaybackRate:[playbackRate floatValue] withAudioId:[identifier integerValue]];
//    return @"";
//}
//
//JS_API(getInnerAudioDurationSync){
//    kBeginCheck
//    kEndCheck([NSString class], @"identifier", NO)
//    NSString *identifier = event.args[@"identifier"];
//    return [NSString stringWithFormat:@"%.0f",[[Weapps sharedApps].audioManager getAudioPlayerDurationWithAudioId:[identifier integerValue]]];
//}
//
//JS_API(getInnerAudioCurrentTimeSync){
//    kBeginCheck
//    kEndCheck([NSString class], @"identifier", NO)
//    NSString *identifier = event.args[@"identifier"];
//    return [NSString stringWithFormat:@"%.6f",[[Weapps sharedApps].audioManager getAudioPlayerCurrentTimeWithAudioId:[identifier integerValue]]];
//}
//
//JS_API(getInnerAudioPausedSync){
//    kBeginCheck
//    kEndCheck([NSString class], @"identifier", NO)
//    NSString *identifier = event.args[@"identifier"];
//    BOOL isPaused = [[Weapps sharedApps].audioManager isAudioPlayerPausedWithAudioId:[identifier integerValue]];
//    if (isPaused) {
//        return @"true";
//    } else {
//        return @"false";
//    }
//}
//
//
//JS_API(getInnerAudioBufferedSync){
//    kBeginCheck
//    kEndCheck([NSString class], @"identifier", NO)
//    NSString *identifier = event.args[@"identifier"];
//    return [NSString stringWithFormat:@"%.0f",[[Weapps sharedApps].audioManager getAudipPlayerBufferedWithAudioId:[identifier integerValue]]];
//}


#pragma mark - *********************innerAudio callbacks**************************
JS_API(onCanplay){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                            onCanPlayCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offCanplay){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                           offCanPlayCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(onEnded){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                              onEndedCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offEnded){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                             offEndedCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(onError){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                              onErrorCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offError){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                             offErrorCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onPause){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                              onPauseCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offPause){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                             offPauseCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onPlay){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                               onPlayCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offPlay){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                              offPlayCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onSeeked){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                             onSeekedCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offSeeked){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                            offSeekedCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onSeeking){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                            onSeekingCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offSeeking){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                           offSeekingCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(onStop){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                               onStopCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offStop){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                              offStopCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onTimeUpdate){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                         onTimeUpdateCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offTimeUpdate){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                        offTimeUpdateCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(onWaiting){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                            onWaitingCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}

JS_API(offWaiting){
    NSString *audioId = event.args[@"identifier"];
    [[Weapps sharedApps].audioManager webView:event.webView
                           offWaitingCallback:event.callbacak
                                  withAudioId:[audioId integerValue]];
    return @"";
}


JS_API(setInnerAudioOption){
    kBeginCheck
    kCheckIsBoolean([NSNumber class], @"mixWithOther", YES, YES)
    kEndChecIsBoonlean(@"obeyMuteSwitch", YES)
    BOOL mixWithOther = YES;
    if (event.args[@"mixWithOther"] && ![event.args[@"mixWithOther"] boolValue]) {
        mixWithOther = NO;
    }
    BOOL obeyMuteSwitch = YES;
    if (event.args[@"obeyMuteSwitch"] && ![event.args[@"obeyMuteSwitch"] boolValue]) {
        obeyMuteSwitch = NO;
    }
    [[Weapps sharedApps].audioManager activeAudioSessionMixWithOther:mixWithOther andObeyMuteSwitch:obeyMuteSwitch];
    kSuccessWithDic(nil)
    return @"";
}


#pragma mark - BackgroundAudio

JS_API(operateBackgroundAudio){
    kBeginCheck
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"play")) {
           return [self js_playBG:event];
       } else if (kStringEqualToString(operationType, @"pause")) {
           return [self js_pauseBG:event];
       } else if (kStringEqualToString(operationType, @"seek")) {
           return [self js_seekBG:event];
       } else if (kStringEqualToString(operationType, @"stop")) {
           return [self js_stopBG:event];
       } else if (kStringEqualToString(operationType, @"onCanplay")) {
           return [self js_onBGCanPlay:event];
       } else if (kStringEqualToString(operationType, @"onEnded")) {
           return [self js_onBGEnded:event];
       } else if (kStringEqualToString(operationType, @"onError")) {
           return [self js_onBGError:event];
       } else if (kStringEqualToString(operationType, @"onPause")) {
           return [self js_onBGPause:event];
       } else if (kStringEqualToString(operationType, @"onPlay")) {
           return [self js_onBGPlay:event];
       } else if (kStringEqualToString(operationType, @"onSeeked")) {
           return [self js_onBGSeeked:event];
       } else if (kStringEqualToString(operationType, @"onSeeking")) {
           return [self js_onBGSeeking:event];
       } else if (kStringEqualToString(operationType, @"onStop")) {
           return [self js_onBGStop:event];
       } else if (kStringEqualToString(operationType, @"onTimeUpdate")) {
           return [self js_onBGTimeUpdate:event];
       } else if (kStringEqualToString(operationType, @"onWaiting")) {
           return [self js_onBGWaiting:event];
       } else if (kStringEqualToString(operationType, @"onNext")) {
           return [self js_onBGNext:event];
       } else if (kStringEqualToString(operationType, @"onPrev")) {
           return [self js_onBGPrev:event];
       }
    return @"";
}

#pragma mark - ********************backgroundAudio methods*****************
JS_API(playBG){
    [[Weapps sharedApps].audioManager playAudioPlayerWithAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(pauseBG){
    [[Weapps sharedApps].audioManager pauseAudioPlayerWithAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(seekBG){
    kBeginCheck
    kEndCheck([NSNumber class], @"position", NO)
    [[Weapps sharedApps].audioManager seekAudioPlayerTo:[event.args[@"position"] floatValue] withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(stopBG){
    [[Weapps sharedApps].audioManager stopAudioPlayerWithAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}


#pragma mark - ********************backgroundAudio props*****************
JS_API(setBackgroundAudioState){
    [[Weapps sharedApps].audioManager setAudioPlayerState:event.args
                                              withAudioId:K_BACKGROUND_AUDIO_ID
                                        completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getBackgroundAudioState){
    return [JSONHelper exchengeDictionaryToString:[[Weapps sharedApps].audioManager getAudioPlayerStateById:K_BACKGROUND_AUDIO_ID]];
}

#pragma mark - ********************backgroundAudio callbacks****************


JS_API(onBGCanPlay){
    [[Weapps sharedApps].audioManager webView:event.webView
                            onCanPlayCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGWaiting){
    [[Weapps sharedApps].audioManager webView:event.webView
                            onWaitingCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGError){
    [[Weapps sharedApps].audioManager webView:event.webView
                              onErrorCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGPlay){
    [[Weapps sharedApps].audioManager webView:event.webView
                               onPlayCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGPause){
    [[Weapps sharedApps].audioManager webView:event.webView
                              onPauseCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGSeeking){
    [[Weapps sharedApps].audioManager webView:event.webView
                            onSeekingCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGSeeked){
    [[Weapps sharedApps].audioManager webView:event.webView
                             onSeekedCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGEnded){
    [[Weapps sharedApps].audioManager webView:event.webView
                              onEndedCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGStop){
    [[Weapps sharedApps].audioManager webView:event.webView
                               onStopCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGTimeUpdate){
    [[Weapps sharedApps].audioManager webView:event.webView
                         onTimeUpdateCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGNext){
    [[Weapps sharedApps].audioManager webView:event.webView
                               onNextCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}

JS_API(onBGPrev){
    [[Weapps sharedApps].audioManager webView:event.webView
                               onPrevCallback:event.callbacak
                                  withAudioId:K_BACKGROUND_AUDIO_ID];
    return @"";
}




@end
