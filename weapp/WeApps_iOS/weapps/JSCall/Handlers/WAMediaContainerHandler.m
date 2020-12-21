//
//  WAMediaContainerHandler.m
//  weapps
//
//  Created by tommywwang on 2020/8/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMediaContainerHandler.h"
#import "Weapps.h"

kSELString(createMediaContainer)
kSELString(extractDataSource)
kSELString(addTrack)
kSELString(removeTrack)
kSELString(destroyContainer)
kSELString(setTrackVolume)
kSELString(exportMedia)

@implementation WAMediaContainerHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createMediaContainer,
            extractDataSource,
            addTrack,
            removeTrack,
            destroyContainer,
            setTrackVolume,
            exportMedia
        ];
    }
    return methods;
}

JS_API(createMediaContainer){
    return [[[Weapps sharedApps].mediaContainerManager createMediaContainer] stringValue];
}

JS_API(extractDataSource){
    kBeginCheck
    kCheck([NSString class], @"containerId", NO)
    kEndCheck([NSString class], @"source", NO)
              
    NSString *source = event.args[@"source"];
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    [[Weapps sharedApps].mediaContainerManager extractDataSource:source
                                                     byContainer:containerId
                                           withCompletionHandler:^(BOOL success,
                                                                   NSDictionary<NSNumber *,AVAssetTrack *> * _Nonnull results,
                                                                   NSError * _Nonnull error) {
        if (!success) {
            kFailWithErr(error)
            return;
        }
        NSMutableArray *tracks = [NSMutableArray array];
        for (NSNumber *key in results.allKeys) {
            AVAssetTrack *track = results[key];
            NSDictionary *dict = @{
                @"id"       : key,
                @"kind"     : track.mediaType == AVMediaTypeAudio ? @"audio" : @"video",
                @"duration" : @(CMTimeGetSeconds(track.timeRange.duration) * 1000)
            };
            [tracks addObject:dict];
        }
        
        kSuccessWithDic((@{
            @"containerId"  : containerId,
            @"tracks"       : tracks
                        }))
    }];
    return @"";
}

JS_API(addTrack){
    kBeginCheck
    kCheck([NSString class], @"trackId", NO)
    kEndCheck([NSString class], @"containerId", NO)
    
    NSNumber *trackId = [event.args[@"trackId"] numberValue];
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    
    [[Weapps sharedApps].mediaContainerManager addTrackById:trackId
                                                toContainer:containerId
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

JS_API(removeTrack){
    kBeginCheck
    kCheck([NSString class], @"trackId", NO)
    kEndCheck([NSString class], @"containerId", NO)
    
    NSNumber *trackId = [event.args[@"trackId"] numberValue];
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    
    [[Weapps sharedApps].mediaContainerManager removeTrackById:trackId
                                                 fromContainer:containerId
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

JS_API(destroyContainer){
    kBeginCheck
    kEndCheck([NSString class], @"containerId", NO)
    
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    [[Weapps sharedApps].mediaContainerManager destroyContainer:containerId
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


JS_API(setTrackVolume){
    kBeginCheck
    kCheck([NSString class], @"trackId", NO)
    kCheck([NSNumber class], @"volume", NO)
    kEndCheck([NSString class], @"containerId", NO)
    
    NSNumber *trackId = [event.args[@"trackId"] numberValue];
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    CGFloat volume = [event.args[@"volume"] floatValue];
    
    [[Weapps sharedApps].mediaContainerManager setTrackVolume:volume
                                                  withTrackId:trackId
                                                  inContainer:containerId
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

JS_API(exportMedia){
    kBeginCheck
    kEndCheck([NSString class], @"containerId", NO)
    
    NSNumber *containerId = [event.args[@"containerId"] numberValue];
    [[Weapps sharedApps].mediaContainerManager exportUseContainer:containerId
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


@end
