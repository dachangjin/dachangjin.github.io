//
//  WAMapView.m
//  weapps
//
//  Created by tommywwang on 2020/10/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMapView.h"

@implementation WAMapView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([otherGestureRecognizer.view isKindOfClass:NSClassFromString(@"WKContentView")]) {
        return YES;
    }
    return NO;
}

@end
