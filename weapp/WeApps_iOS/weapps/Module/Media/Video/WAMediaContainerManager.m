//
//  WAMediaContainerManager.m
//  weapps
//
//  Created by tommywwang on 2020/8/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMediaContainerManager.h"
#import "WAMediaContainer.h"

@interface WAMediaContainerManager ()

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WAMediaContainer *> *containerDict;

@end

@implementation WAMediaContainerManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _containerDict = [NSMutableDictionary dictionary];
    }
    return self;
}


- (NSNumber *)createMediaContainer
{
    WAMediaContainer *container = [[WAMediaContainer alloc] init];
    _containerDict[container.containerId] = container;
    return container.containerId;
}

- (void)extractDataSource:(NSString *)source
              byContainer:(NSNumber *)containerId
    withCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary<NSNumber *, AVAssetTrack *> *results ,
                                   NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                           code:-1
                                                       userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container extractDataSource:source withCompletionHandler:completionHandler];
}

- (void)addTrackById:(NSNumber *)trackId
         toContainer:(NSNumber *)containerId
withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain
                                                      code:-1
                                                  userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container addTrackById:trackId withCompletionHandler:completionHandler];
}


- (void)removeTrackById:(NSNumber *)trackId
          fromContainer:(NSNumber *)containerId
  withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain
                                                      code:-1
                                                  userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container removeTrackById:trackId withCompletionHandler:completionHandler];
}

- (void)setTrackVolume:(CGFloat)volume
           withTrackId:(NSNumber *)trackId
           inContainer:(NSNumber *)containerId
     completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain
                                                      code:-1
                                                  userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container setTrackVolume:volume withTrackId:trackId completionHandler:completionHandler];
}

- (void)destroyContainer:(NSNumber *)containerId
       completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain
                                                      code:-1
                                                  userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container destroy];
    [_containerDict removeObjectForKey:containerId];
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)exportUseContainer:(NSNumber *)containerId
     withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WAMediaContainer *container = _containerDict[containerId];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:NSCocoaErrorDomain
                                                           code:-1
                                                       userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find container with id {%@}", containerId]
            }]);
        }
        return;
    }
    [container exportWithCompletionHandler:completionHandler];
}

@end
