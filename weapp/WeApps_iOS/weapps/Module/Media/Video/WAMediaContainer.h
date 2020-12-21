//
//  WAMediaContainer.h
//  weapps
//
//  Created by tommywwang on 2020/8/13.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface WAMediaContainer : NSObject

@property (nonatomic, strong, readonly) NSNumber *containerId;

//需要当前track对应id
- (void)extractDataSource:(NSString *)source
    withCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary<NSNumber *,
                                   AVAssetTrack *> *results ,
                                   NSError *error))completionHandler;


- (void)addTrackById:(NSNumber *)trackId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)removeTrackById:(NSNumber *)trackId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)setTrackVolume:(CGFloat)volume withTrackId:(NSNumber *)trackId completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)destroy;

- (void)exportWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler;
@end

NS_ASSUME_NONNULL_END
