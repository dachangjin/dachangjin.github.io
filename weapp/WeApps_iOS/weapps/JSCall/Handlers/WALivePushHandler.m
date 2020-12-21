//
//  WALivePushHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/16.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePushHandler.h"
#import "Weapps.h"

kSELString(createNativeLivePusherComponent)
kSELString(createLivePusherContext)
kSELString(operateLivePusherContext)
kSELString(setLivePusherContextState)

@implementation WALivePushHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createNativeLivePusherComponent,
            createLivePusherContext,
            operateLivePusherContext,
            setLivePusherContextState
        ];
    }
    return methods;
}

JS_API(createNativeLivePusherComponent){
    kBeginCheck
    kEndCheck([NSDictionary class], @"position", NO)
    [[Weapps sharedApps].livePusherManager createLivePusherInWebView:event.webView
                                                        withPosition:event.args[@"position"]
                                                               state:event.args
                                                   completionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(createLivePusherContext){
//    kBeginCheck
//    kEndCheck([NSDictionary class], @"position", NO)
//    [[Weapps sharedApps].livePusherManager createLivePusherInWebView:event.webView
//                                                        withPosition:event.args[@"position"]
//                                                               state:event.args
//                                                   completionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
//        if (success) {
//            kSuccessWithDic(result)
//        } else {
//            kFailWithErr(error)
//        }
//    }];
    return @"";
}

JS_API(operateLivePusherContext){
    kBeginCheck
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"pause")) {
        return [self _pause:event];
    } else if (kStringEqualToString(operationType, @"pauseBGM")) {
        return [self _pauseBGM:event];
    } else if (kStringEqualToString(operationType, @"playBGM")) {
        return [self _playBGM:event];
    } else if (kStringEqualToString(operationType, @"resume")) {
        return [self _resume:event];
    } else if (kStringEqualToString(operationType, @"resumeBGM")) {
        return [self _resumeBGM:event];
    } else if (kStringEqualToString(operationType, @"setBGMVolume")) {
        return [self _setBGMVolume:event];
    } else if (kStringEqualToString(operationType, @"setMICVolume")) {
        return [self _setMICVolume:event];
    } else if (kStringEqualToString(operationType, @"snapshot")) {
        return [self _snapshot:event];
    } else if (kStringEqualToString(operationType, @"start")) {
        return [self _start:event];
    } else if (kStringEqualToString(operationType, @"startPreview")) {
        return [self _startPreview:event];
    } else if (kStringEqualToString(operationType, @"stop")) {
        return [self _stop:event];
    } else if (kStringEqualToString(operationType, @"stopBGM")) {
        return [self _stopBGM:event];
    } else if (kStringEqualToString(operationType, @"stopPreview")) {
        return [self _stopPreview:event];
    } else if (kStringEqualToString(operationType, @"switchCamera")) {
        [self _switchCamera:event];
    } else if (kStringEqualToString(operationType, @"toggleTorch")) {
        return [self _toggleTorch:event];
    }
    return @"";
}

JS_API(setLivePusherContextState){
    kBeginCheck
    kEndCheck([NSDictionary class], @"state", NO)
    NSDictionary *state = event.args[@"state"];
    [[Weapps sharedApps].livePusherManager setLivePusherContextState:state];
    return @"";
}


PRIVATE_API(pause){
    [[Weapps sharedApps].livePusherManager pausePushWithCompletionHandler:^(BOOL success,
                                                                            NSDictionary * _Nonnull result,
                                                                            NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


PRIVATE_API(pauseBGM){
    [[Weapps sharedApps].livePusherManager pauseBGMWithCompletionHandler:^(BOOL success,
                                                                           NSDictionary * _Nonnull result,
                                                                           NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(playBGM){
    kBeginCheck
    kEndCheck([NSString class], @"url", NO)
    NSString *url = event.args[@"url"];
    [[Weapps sharedApps].livePusherManager playBGM:url
                             withCompletionHandler:^(BOOL success,
                                                     NSDictionary * _Nonnull result,
                                                     NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(resume){
    [[Weapps sharedApps].livePusherManager resumePushWithCompletionHandler:^(BOOL success,
                                                                             NSDictionary * _Nonnull result,
                                                                             NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(resumeBGM){
    [[Weapps sharedApps].livePusherManager resumeBGMWithCompletionHandler:^(BOOL success,
                                                                            NSDictionary * _Nonnull result,
                                                                            NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(setBGMVolume){
    kBeginCheck
    kEndCheck([NSNumber class], @"volume", NO)
    NSNumber *volume = event.args[@"volume"];
    [[Weapps sharedApps].livePusherManager setBGMVolume:[volume floatValue]
                                  withCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(setMICVolume){
    kBeginCheck
    kEndCheck([NSNumber class], @"volume", NO)
    NSNumber *volume = event.args[@"volume"];
    [[Weapps sharedApps].livePusherManager setMicVolume:[volume floatValue]
                                  withCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(snapshot){
    kBeginCheck
    kEndCheck([NSString class], @"quality", YES)
    NSString *quality = event.args[@"quality"];
    [[Weapps sharedApps].livePusherManager snapshot:quality
                              withCompletionHandler:^(BOOL success,
                                                      NSDictionary * _Nonnull result,
                                                      NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(start){
    [[Weapps sharedApps].livePusherManager startPushwithCompletionHandler:^(BOOL success,
                                                                            NSDictionary * _Nonnull result,
                                                                            NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(startPreview){
    [[Weapps sharedApps].livePusherManager startPreviewWithCompletionHandler:^(BOOL success,
                                                                               NSDictionary * _Nonnull result,
                                                                               NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


PRIVATE_API(stop){
    [[Weapps sharedApps].livePusherManager stopPushWithCompletionHandler:^(BOOL success,
                                                                           NSDictionary * _Nonnull result,
                                                                           NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(stopBGM){
    [[Weapps sharedApps].livePusherManager stopBGMWithCompletionHandler:^(BOOL success,
                                                                          NSDictionary * _Nonnull result,
                                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(stopPreview){
    [[Weapps sharedApps].livePusherManager stopPreviewWithCompletionHandler:^(BOOL success,
                                                                              NSDictionary * _Nonnull result,
                                                                              NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(switchCamera){
    [[Weapps sharedApps].livePusherManager switchCameraWithCompletionHandler:^(BOOL success,
                                                                               NSDictionary * _Nonnull result,
                                                                               NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(toggleTorch){
    [[Weapps sharedApps].livePusherManager toggleTorchWithCompletionHandler:^(BOOL success,
                                                                              NSDictionary * _Nonnull result,
                                                                              NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

@end
