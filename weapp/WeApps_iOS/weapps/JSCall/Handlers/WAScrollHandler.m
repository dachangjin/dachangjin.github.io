//
//  WAScrollHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAScrollHandler.h"
static  NSString *const pageScrollTo = @"pageScrollTo";

@implementation WAScrollHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            pageScrollTo
        ];
    }
    return methods;
}

JS_API(pageScrollTo){
    
    kBeginCheck
    kCheck([NSNumber class], @"scrollTop", YES)
    kEndCheck([NSNumber class], @"duration", YES)
    
    CGFloat scrollTop = [event.args[@"scrollTop"] floatValue];
    NSTimeInterval duration = [event.args[@"duration"] doubleValue];
    if (duration == 0) {
        duration = 300;
    }
    [UIView animateWithDuration:duration / 1000 animations:^{
        [event.webView.scrollView setContentOffset:CGPointMake(0, scrollTop) animated:NO];
    }];
    return @"";

}

@end
