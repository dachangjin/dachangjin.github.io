//
//  WAVideoDecoder.h
//  weapps
//
//  Created by tommywwang on 2020/8/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WAVideoDecoderMode) {
    WAVideoDecoderModePts,
    WAVideoDecoderModeDts
};

@interface WAVideoDecoder : NSObject

@property (nonatomic, strong, readonly) NSNumber *decoderId;
@property (nonatomic, copy) void(^didStartBlock)(CGSize size);
@property (nonatomic, copy) void(^didStopBlock)(void);
@property (nonatomic, copy) void(^didSeekBlock)(CGFloat position);
@property (nonatomic, copy) void(^didBufferChangeBlock)(void);
@property (nonatomic, copy) void(^didEndBlock)(void);



- (void)startWithSource:(NSString *)source
                   mode:(WAVideoDecoderMode)mode
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)seekTo:(CGFloat)time completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)stopWithCompletionHandler:(void(^_Nullable)(BOOL success, NSError *error))completionHandler;;

- (NSDictionary *)getFrameData;

@end

NS_ASSUME_NONNULL_END
