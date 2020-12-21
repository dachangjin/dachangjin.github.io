//
//  NSTimer+BlockSupport.h
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTimer (BlockSupport)

+ (NSTimer *)qqScheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                     block:(void(^)(void))block
                                   repeats:(BOOL)repeats;

+ (NSTimer *)qqScheduledTimerWithTimeInterval:(NSTimeInterval)interval
                                 timerBlock:(void(^)(NSTimer *timer))block
                                    repeats:(BOOL)repeats;
@end

NS_ASSUME_NONNULL_END
