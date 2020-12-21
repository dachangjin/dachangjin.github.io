//
//  WARecordHandler.m
//  weapps
//
//  Created by tommywwang on 2020/7/9.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WARecordHandler.h"
#import <AVFoundation/AVFoundation.h>
#import "WARecordManager.h"
#import "Weapps.h"

kSELString(operateRecorder)
kSELString(onFrameRecorded)
kSELString(onInterruptionBegin)
kSELString(onInterruptionEnd)
kSELString(onPause)
kSELString(onResume)
kSELString(onStart)
kSELString(onStop)
kSELString(onError)
kSELString(getAvailableAudioSources)

@implementation WARecordHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            operateRecorder,
            getAvailableAudioSources
        ];
    }
    return methods;
}



#pragma mark 操作相关

JS_API(operateRecorder){
    kBeginCheck
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"start")) {
        return [self js_start:event];
    } else if (kStringEqualToString(operationType, @"stop")) {
        return [self js_stop:event];
    } else if (kStringEqualToString(operationType, @"pause")) {
        return [self js_pause:event];
    } else if (kStringEqualToString(operationType, @"resume")) {
        return [self js_resume:event];
    } else if (kStringEqualToString(operationType, onFrameRecorded)) {
        return [self js_onFrameRecorded:event];
    } else if (kStringEqualToString(operationType, onInterruptionBegin)) {
        return [self js_onInterruptionBegin:event];
    } else if (kStringEqualToString(operationType, onInterruptionEnd)) {
        return [self js_onInterruptionEnd:event];
    } else if (kStringEqualToString(operationType, onPause)) {
        return [self js_onPause:event];
    } else if (kStringEqualToString(operationType, onResume)) {
        return [self js_onResume:event];
    } else if (kStringEqualToString(operationType, onStart)) {
        return [self js_onStart:event];
    } else if (kStringEqualToString(operationType, onStop)) {
        return [self js_onStop:event];
    } else if (kStringEqualToString(operationType, onError)) {
        return [self js_onError:event];
    }
    return @"";
}



JS_API(start){
    kBeginCheck
    kCheck([NSNumber class], @"duration", YES)
    kCheck([NSNumber class], @"sampleRate", YES)
    kCheck([NSNumber class], @"numberOfChannels", YES)
    kCheck([NSNumber class], @"encodeBitRate", YES)
    kCheck([NSString class], @"format", YES)
    kCheck([NSNumber class], @"frameSize", YES)
    kEndCheck([NSString class], @"audioSource", YES)
    WARecordConfig *config = [[WARecordConfig alloc] init];
    //  录音的时长，单位 ms，最大值 600000（10 分钟）
    WARecordManager *manager = [Weapps sharedApps].recordManager;
    NSNumber *duration = event.args[@"duration"];
    
    if (!duration || duration.floatValue < 0) {
        config.duration = 60000; //默认值60000
    } else if (duration.floatValue > 600000) {
        config.duration = 600000; //最长10分钟
    } else {
        config.duration = [duration floatValue];
    }
    
    NSNumber *sampleRateNumber = event.args[@"sampleRate"];
    config.sampleRate = sampleRateNumber?[sampleRateNumber floatValue]:8000;
    NSArray *vailableValues = @[@(8000),@(11025),@(12000),@(16000),@(22050),@(24000),@(32000),@(44100),@(48000)];
    if (![vailableValues containsObject:@(config.sampleRate)]) {
        if ([manager respondsToSelector:@selector(onError:)]) {
            [manager onError:@"非法SampleRate,初始化失败"];
        }
        kFailWithErrorWithReturn(@"start", -1, @"非法SampleRate,初始化失败")
    }
    NSNumber *numberOfChannelsNumber = event.args[@"numberOfChannels"];
    config.numberOfChannels = numberOfChannelsNumber?(UInt32)[numberOfChannelsNumber integerValue]:2;
        vailableValues = @[@(1),@(2)];
    if (![vailableValues containsObject:@(config.numberOfChannels)]) {
        if ([manager respondsToSelector:@selector(onError:)]) {
            [manager onError:@"非法numberOfChannels,初始化失败"];
        }
        kFailWithErrorWithReturn(@"start", -1, @"非法numberOfChannels,初始化失败")
    }
    
    NSNumber *encodeBitRateNumber = event.args[@"encodeBitRate"];
    config.encodeBitRate = encodeBitRateNumber?(UInt32)[encodeBitRateNumber unsignedIntegerValue]:48000;
    
    NSString *formatType = [event.args[@"format"] lowercaseString];
    if (formatType.length == 0) {
        formatType = @"aac";
    }
    config.format = formatType;
    vailableValues = @[@"aac",@"mp3",@"wav",@"pcm"];
    if (![vailableValues containsObject:formatType]) {
        if ([manager respondsToSelector:@selector(onError:)]) {
            [manager onError:@"operateRecorder:fail record format error"];
        }
        kFailWithErrorWithReturn(@"start", -1, @"operateRecorder:fail record format error")
    }
    
    // frameSize, mp3格式有效
    config.frameSize = 0;
    if ([formatType isEqualToString:@"mp3"]) {
        config.frameSize = (UInt32)[event.args[@"frameSize"] unsignedIntegerValue];
    }
    
    NSString *audioSource = event.args[@"audioSource"];
    audioSource = audioSource ?: @"auto";
    config.audioSource = audioSource;
    if (![audioSource isEqualToString:@"auto"]) {
        AVAudioSessionPortDescription* portDesc = [self availableAudioSources][audioSource];
        if (portDesc == nil) {
            if ([manager respondsToSelector:@selector(onError:)]) {
                [manager onError:@"录音设备错误,初始化失败"];
            }
            kFailWithErrorWithReturn(@"start", -1, @"录音设备错误,初始化失败")
        }
        
        NSError* error = nil;
        [[AVAudioSession sharedInstance] setPreferredInput:portDesc error:&error];
        if (error) {
            WALOG(@"setPreferredInput %@ fail. %@", audioSource, error);
        }
    }
    [manager startWithConfig:config
                   inWebView:event.webView
           completionHandler:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result);
        } else {
            kFailWithError(@"start", -1, error.userInfo[NSLocalizedDescriptionKey])
        }
    }];
    return @"";
}

JS_API(stop){
    [[Weapps sharedApps].recordManager stop];
    return @"";
}

JS_API(pause){
    [[Weapps sharedApps].recordManager pause];
    return @"";
}

JS_API(resume){
    [[Weapps sharedApps].recordManager resume];
    return @"";
}

   


#pragma mark 回调相关
JS_API(onFrameRecorded){
    [[Weapps sharedApps].recordManager webView:event.webView onFrameRecorded:event.callbacak];
    return @"";
}

JS_API(onInterruptionBegin){
    [[Weapps sharedApps].recordManager webView:event.webView onInterruptionBegin:event.callbacak];
    return @"";
}

JS_API(onInterruptionEnd){
    [[Weapps sharedApps].recordManager webView:event.webView onInterruptionEnd:event.callbacak];
    return @"";
}

JS_API(onPause){
    [[Weapps sharedApps].recordManager webView:event.webView onPause:event.callbacak];
    return @"";
}

JS_API(onResume){
    [[Weapps sharedApps].recordManager webView:event.webView onResume:event.callbacak];
    return @"";
}

JS_API(onStart){
    [[Weapps sharedApps].recordManager webView:event.webView onStart:event.callbacak];
    return @"";
}

JS_API(onStop){
    [[Weapps sharedApps].recordManager webView:event.webView onStop:event.callbacak];
    return @"";
}

JS_API(onError){
    [[Weapps sharedApps].recordManager webView:event.webView onError:event.callbacak];
    return @"";
}



JS_API(getAvailableAudioSources) {
    NSMutableArray* audioSources = [[[self availableAudioSources] allKeys] mutableCopy];
    if (audioSources == nil) {
        audioSources = [NSMutableArray array];
    }
    [audioSources addObject:@"auto"];
    kSuccessWithDic(@{ @"audioSources": audioSources })
    return @"";
}



#pragma mark private
- (NSDictionary<NSString *, AVAudioSessionPortDescription* > *)availableAudioSources {
    NSMutableDictionary *outputDict = [NSMutableDictionary dictionary];
    NSArray* inputArray = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription* desc in inputArray) {
        if ([desc.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            outputDict[@"buildInMic"] = desc;
        } else if ([desc.portType isEqualToString:AVAudioSessionPortHeadsetMic]) {
            outputDict[@"headsetMic"] = desc;
        }
    }
    return outputDict;
}

@end
