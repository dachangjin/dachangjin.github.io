//
//  WAMediaContainerManager.h
//  weapps
//
//  Created by tommywwang on 2020/8/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WAMediaContainerManager : NSObject

- (NSNumber *)createMediaContainer;

- (void)extractDataSource:(NSString *)source
              byContainer:(NSNumber *)containerId
    withCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary<NSNumber *, AVAssetTrack *> *results ,
                                   NSError *error))completionHandler;

- (void)addTrackById:(NSNumber *)trackId
         toContainer:(NSNumber *)containerId
withCompletionHandler:(void(^)(BOOL success,
                               NSError *error))completionHandler;

- (void)removeTrackById:(NSNumber *)trackId
          fromContainer:(NSNumber *)containerId
  withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)setTrackVolume:(CGFloat)volume
           withTrackId:(NSNumber *)trackId
           inContainer:(NSNumber *)containerId
     completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)destroyContainer:(NSNumber *)containerId
       completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)exportUseContainer:(NSNumber *)containerId
     withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
