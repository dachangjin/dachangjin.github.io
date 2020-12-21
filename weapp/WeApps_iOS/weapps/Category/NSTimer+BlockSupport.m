//
//  NSTimer+BlockSupport.m
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NSTimer+BlockSupport.h"

@implementation NSTimer (BlockSupport)

+ (NSTimer *)qqScheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)repeats
 {
     //block存在了userInfo字段中，是一个强引用，但在invalidate时会解引用，所以可以打破引用循环（如果存在的话）
     return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(fxInvokeBlock:) userInfo:[block copy] repeats:repeats];
 }
 
 + (NSTimer *)qqScheduledTimerWithTimeInterval:(NSTimeInterval)interval timerBlock:(void (^)(NSTimer *))block repeats:(BOOL)repeats
 {
     return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(fxInvokeTimerBlock:) userInfo:[block copy] repeats:repeats];
 }
 
 + (void)fxInvokeBlock:(NSTimer *)timer
 {
     void (^block)(void) = timer.userInfo;
     if (block) {
         block();
     }
 }
 
 + (void)fxInvokeTimerBlock:(NSTimer *)timer
 {
     void (^block)(NSTimer *) = timer.userInfo;
     if (block) {
         block(timer);
     }
 }

@end
