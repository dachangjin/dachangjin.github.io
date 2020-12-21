//
//  WALivePlayerHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/18.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePlayerHandler.h"
#import "Weapps.h"

kSELString(createNativeLivePlayerComponent)
kSELString(createLivePlayerContext)
kSELString(operateLivePlayerContext)
kSELString(setLivePlayerContextState)

@implementation WALivePlayerHandler


- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createNativeLivePlayerComponent,
            createLivePlayerContext,
            operateLivePlayerContext,
            setLivePlayerContextState
        ];
    }
    return methods;
}


JS_API(createNativeLivePlayerComponent){
    kBeginCheck
    kCheck([NSString class], @"playerId", NO)
    kEndCheck([NSDictionary class], @"position", NO)
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager createLivePlayer:playerId
                                                  inWebView:event.webView
                                               withPosition:event.args[@"position"]
                                                      state:event.args
                                          completionHandler:^(BOOL success,
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

JS_API(createLivePlayerContext){
//    kBeginCheck
//    kCheck([NSString class], @"playerId", NO)
//    kEndCheck([NSDictionary class], @"position", NO)
//    NSString *playerId = event.args[@"playerId"];
//    [[Weapps sharedApps].livePlayerManager createLivePlayer:playerId
//                                                  inWebView:event.webView
//                                               withPosition:event.args[@"position"]
//                                                      state:event.args
//                                          completionHandler:^(BOOL success,
//                                                              NSDictionary * _Nonnull result,
//                                                              NSError * _Nonnull error) {
//        if (success) {
//            kSuccessWithDic(result)
//        } else {
//            kFailWithErr(error)
//        }
//    }];
    return @"";
}

JS_API(operateLivePlayerContext){
    kBeginCheck
    kCheck([NSString class], @"playerId", NO)
    kEndCheck([NSString class], @"operationType", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"exitFullScreen")) {
        return [self _exitFullScreen:event];
    } else if (kStringEqualToString(operationType, @"exitPictureInPicture")) {
        return [self _exitPictureInPicture:event];
    } else if (kStringEqualToString(operationType, @"mute")) {
        return [self _mute:event];
    } else if (kStringEqualToString(operationType, @"pause")) {
        return [self _pause:event];
    } else if (kStringEqualToString(operationType, @"play")) {
        return [self _play:event];
    } else if (kStringEqualToString(operationType, @"requestFullScreen")) {
        return [self _requestFullScreen:event];
    } else if (kStringEqualToString(operationType, @"resume")) {
        return [self _resume:event];
    } else if (kStringEqualToString(operationType, @"snapshot")) {
        return [self _snapshot:event];
    } else if (kStringContainString(operationType, @"stop")) {
        return [self _stop:event];
    }
    return @"";
}

JS_API(setLivePlayerContextState){
    kBeginCheck
    kCheck([NSString class], @"playerId", NO)
    kEndCheck([NSDictionary class], @"state", NO)
    NSString *playerId = event.args[@"playerId"];
    NSDictionary *state = event.args[@"state"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId setState:state];
    return @"";
}


PRIVATE_API(exitFullScreen){
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                  exitFullScreenWithCompletionHandler:^(BOOL success,
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

PRIVATE_API(exitPictureInPicture){
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
            exitPictureInPictureWithCompletionHandler:^(BOOL success,
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

PRIVATE_API(mute){
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                            muteWithCompletionHandler:^(BOOL success,
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

PRIVATE_API(pause){
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                           pauseWithCompletionHandler:^(BOOL success,
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

PRIVATE_API(play){
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                            playWithCompletionHandler:^(BOOL success,
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

PRIVATE_API(requestFullScreen){
    kBeginCheck
    kEndCheck([NSNumber class], @"direction", YES)
    NSNumber *direction = event.args[@"direction"];
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                       requestFullScreenWithDirection:direction
                                    completionHandler:^(BOOL success,
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
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                          resumeWithCompletionHandler:^(BOOL success,
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
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                                  snapShotWithQuality:quality
                                    completionHandler:^(BOOL success,
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
    NSString *playerId = event.args[@"playerId"];
    [[Weapps sharedApps].livePlayerManager livePlayer:playerId
                            stopWithCompletionHandler:^(BOOL success,
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
