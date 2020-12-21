//
//  WAVideoDecoderHandler.m
//  weapps
//
//  Created by tommywwang on 2020/8/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVideoDecoderHandler.h"
#import "Weapps.h"
#import "JSONHelper.h"

kSELString(createVideoDecoder)
kSELString(getFrameData)
kSELString(operateVideoDecoder)


@implementation WAVideoDecoderHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createVideoDecoder,
            getFrameData,
            operateVideoDecoder
        ];
    }
    return methods;
}

JS_API(createVideoDecoder){
    return [[[Weapps sharedApps].videoDecoderManager createMediaContainerWithWebView:event.webView] stringValue];
}

JS_API(getFrameData){
    kBeginCheck
    kEndCheck([NSString class], @"identifier", NO)
    NSString *identifier = event.args[@"identifier"];
    NSDictionary *result = [[Weapps sharedApps].videoDecoderManager getFrameDataWithDecoder:@([identifier integerValue])];
    
    return [JSONHelper exchengeDictionaryToString:result] ?: @"";
}

JS_API(operateVideoDecoder){
    kBeginCheck
    kCheck([NSString class], @"operationType", NO)
    kEndCheck([NSString class], @"identifier", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"start")) {
        [self js_start:event];
    } else if (kStringEqualToString(operationType, @"stop")) {
        [self js_stop:event];
    } else if (kStringEqualToString(operationType, @"seek")) {
        [self js_seek:event];
    } else if (kStringEqualToString(operationType, @"remove")) {
        [self js_remove:event];
    } else if (kStringEqualToString(operationType, @"on")) {
        [self js_on:event];
    } else if (kStringEqualToString(operationType, @"off")) {
        [self js_off:event];
    }
    return @"";
}

JS_API(start){
    kBeginCheck
    kCheck([NSString class], @"source", NO)
    kEndCheck([NSNumber class], @"mode", YES)
    NSString *identifier = event.args[@"identifier"];
    NSString *source = event.args[@"source"];
    WAVideoDecoderMode mode = WAVideoDecoderModeDts;
    if (event.args[@"mode"] && [event.args[@"mode"] integerValue] == 0) {
        mode = WAVideoDecoderModePts;
    }
    [[Weapps sharedApps].videoDecoderManager startWithDecoder:@([identifier integerValue])
                                                      webView:event.webView
                                                       source:source
                                                       inMode:mode
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

JS_API(stop){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager stopWithDecoder:@([identifier integerValue])
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

JS_API(seek){
    NSString *identifier = event.args[@"identifier"];
    kBeginCheck
    kEndCheck([NSNumber class], @"position", NO)
    NSNumber *position = event.args[@"position"];
    [[Weapps sharedApps].videoDecoderManager seekTo:position
                                        withDecoder:@([identifier integerValue])
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

JS_API(remove){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager removeDecoder:@([identifier integerValue])
                                     withCompletionHandler:^(BOOL success,
                                                             NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(on){
    kBeginCheck
    kEndCheck([NSString class], @"eventName", NO)
    NSString *eventName = event.args[@"eventName"];
    if (kStringEqualToString(eventName, @"start")) {
        [self js_onStart:event];
    } else if (kStringEqualToString(eventName, @"stop")) {
        [self js_onStop:event];
    } else if (kStringEqualToString(eventName, @"seek")) {
        [self js_onSeek:event];
    } else if (kStringEqualToString(eventName, @"bufferchange")) {
        [self js_onBufferChange:event];
    } else if (kStringEqualToString(eventName, @"ended")) {
        [self js_onEnd:event];
    }
    return @"";
}

JS_API(off){
    kBeginCheck
    kEndCheck([NSString class], @"eventName", NO)
    NSString *eventName = event.args[@"eventName"];
    if (kStringEqualToString(eventName, @"start")) {
        [self js_offStart:event];
    } else if (kStringEqualToString(eventName, @"stop")) {
        [self js_offStop:event];
    } else if (kStringEqualToString(eventName, @"seek")) {
        [self js_offSeek:event];
    } else if (kStringEqualToString(eventName, @"bufferchange")) {
        [self js_offBufferChange:event];
    } else if (kStringEqualToString(eventName, @"ended")) {
        [self js_offEnd:event];
    }
    return @"";
}

JS_API(onStart){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager onStartCallback:event.callbacak
                                               withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(offStart){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager offStartCallback:event.callbacak
                                                withDecoderId:@([identifier integerValue])];
    return @"";
}


JS_API(onStop){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager onStopCallback:event.callbacak
                                              withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(offStop){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager offStopCallback:event.callbacak
                                               withDecoderId:@([identifier integerValue])];
    return @"";
}


JS_API(onSeek){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager onSeekCallback:event.callbacak
                                              withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(offSeek){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager offSeekCallback:event.callbacak
                                               withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(onBufferChange){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager onBufferChangeCallback:event.callbacak
                                                      withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(offBufferChange){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager offBufferChangeCallback:event.callbacak
                                                       withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(onEnd){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager onEndCallback:event.callbacak
                                             withDecoderId:@([identifier integerValue])];
    return @"";
}

JS_API(offEnd){
    NSString *identifier = event.args[@"identifier"];
    [[Weapps sharedApps].videoDecoderManager offEndCallback:event.callbacak
                                              withDecoderId:@([identifier integerValue])];
    return @"";
}

@end
