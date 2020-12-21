//
//  UINavigationBar+Custom.m
//  weapps
//
//  Created by tommywwang on 2020/8/5.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "UINavigationBar+Custom.h"
#import "Device.h"
#import "QMUIRuntime.h"


static NSDictionary * getTimingFuncDict()
{
    static NSDictionary *dict = nil;
    if (!dict) {
        dict = @{
            @"linear"   : kCAMediaTimingFunctionLinear,
            @"easeIn"   : kCAMediaTimingFunctionEaseIn,
            @"easeOut"  : kCAMediaTimingFunctionEaseOut,
            @"easeInOut": kCAMediaTimingFunctionEaseInEaseOut
        };
    }
    return dict;
}

@implementation AnimationInfo



@end

@implementation UINavigationBar (Custom)

+ (void)load
{
    ExchangeImplementations([UINavigationBar class], @selector(wa_layoutSubviews), @selector(layoutSubviews));
}


- (void)wa_layoutSubviews
{
    [self wa_layoutSubviews];
    for (UIView *view in self.subviews) {
        if ([view isEqual:[self bgView]]) {
            [self sendSubviewToBack:view];
        }
    }
}


- (UIView *)bgView
{
    UIView * view = objc_getAssociatedObject(self, @selector(bgView));
    return view;
}

- (void)setBgView:(UIView *)bgView
{
    objc_setAssociatedObject(self, @selector(bgView), bgView, OBJC_ASSOCIATION_RETAIN);
}

- (UIColor *)bgColor
{
    return objc_getAssociatedObject(self, @selector(bgColor));
}

- (void)setBgColor:(UIColor *)bgColor
{
    objc_setAssociatedObject(self, @selector(bgColor), bgColor, OBJC_ASSOCIATION_RETAIN);
}



- (void)setBackgroundColor:(UIColor *)backgroundColor withAnimationInfo:(AnimationInfo *)info
{
    [self setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self setShadowImage:[UIImage new]];
//    [self setBgColor:backgroundColor];
    UIView *bgView = [self bgView];
    if (!bgView) {
        bgView = [[UIView alloc] initWithFrame:CGRectMake(0, -[Device statusBarHeight],
                                                          CGRectGetWidth(self.frame),
                                                          CGRectGetHeight(self.frame) + [Device statusBarHeight])];
        [self insertSubview:bgView atIndex:0];
        
        [self setBgView:bgView];
    }
    if (!info || info.duration == 0) {
        bgView.backgroundColor = backgroundColor;
    } else {
        CABasicAnimation *animation = [[CABasicAnimation alloc] init];
        animation.keyPath = @"backgroundColor";
        animation.fromValue = (id)bgView.backgroundColor.CGColor;
        animation.toValue = (id)backgroundColor.CGColor;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.delegate = self;
        animation.duration = info.duration / 1000;
        CAMediaTimingFunctionName functionName = getTimingFuncDict()[info.timingFunc];
        if (!functionName) {
            functionName = kCAMediaTimingFunctionLinear;
        }
        animation.timingFunction = [CAMediaTimingFunction functionWithName:functionName];
        [bgView.layer addAnimation:animation forKey:@"backgroundColor"];
    }
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag) {
        [self bgView].backgroundColor = [UIColor colorWithCGColor:(__bridge CGColorRef _Nonnull)(((CABasicAnimation *)anim).toValue)];
        [[self bgView].layer removeAllAnimations];
        
    }
}

@end
