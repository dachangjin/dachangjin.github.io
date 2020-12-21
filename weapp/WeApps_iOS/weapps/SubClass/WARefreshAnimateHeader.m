//
//  WARefreshAnimateHeader.m
//  weapps
//
//  Created by tommywwang on 2020/7/7.
//  Copyright © 2020 tencent. All rights reserved.
//

#define kLightColor [UIColor lightGrayColor]
#define kDarkColor [UIColor darkGrayColor]

#import "WARefreshAnimateHeader.h"

@interface WARefreshAnimatorView : UIView

@property(nonatomic, strong, readonly) UIView *shapeView1;
@property(nonatomic, strong, readonly) UIView *shapeView2;
@property(nonatomic, strong, readonly) UIView *shapeView3;

- (void)beginAnimation;

- (void)stopAnimation;

- (void)switchToLight;

- (void)switchToDark;
@end


@implementation WARefreshAnimatorView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _shapeView1 = [[UIView alloc] init];
        _shapeView1.backgroundColor = kDarkColor;
        _shapeView1.layer.cornerRadius = 5;
        [self addSubview:_shapeView1];
        
        _shapeView2 = [[UIView alloc] init];
        _shapeView2.backgroundColor = kDarkColor;
        _shapeView2.layer.cornerRadius = 5;
        [self addSubview:_shapeView2];
        
        _shapeView3 = [[UIView alloc] init];
        _shapeView3.backgroundColor = kDarkColor;
        _shapeView3.layer.cornerRadius = 5;
        [self addSubview:_shapeView3];
    }
    return self;
}

- (void)switchToLight
{
    for (UIView *view in self.subviews) {
        view.backgroundColor = kLightColor;
    }
}

- (void)switchToDark
{
    for (UIView *view in self.subviews) {
        view.backgroundColor = kDarkColor;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat bigSize = 10;
    CGFloat lineSpace = 20;
    CGFloat minY = lineSpace;
    CGFloat minX = (CGRectGetWidth(self.bounds) - 10) / 2;
    
    _shapeView1.frame = CGRectMake(minX, minY, bigSize, bigSize);
    _shapeView2.frame = CGRectMake(minX, minY, bigSize, bigSize);
    _shapeView3.frame = CGRectMake(minX, minY, bigSize, bigSize);
}


- (void)beginAnimation
{
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animation];
    positionAnimation.keyPath = @"position.x";
    positionAnimation.values = @[ @-20, @-25, @-15, @0, @15, @25, @20 ];
    positionAnimation.keyTimes = @[ @0, @(5 / 90.0), @(15 / 90.0), @(45 / 90.0), @(75 / 90.0), @(85 / 90.0), @1 ];
    positionAnimation.additive = YES;
    
    CAKeyframeAnimation *scaleAnimation = [CAKeyframeAnimation animation];
    scaleAnimation.keyPath = @"transform.scale";
    scaleAnimation.values = @[ @.7, @.9, @1, @.9, @.7 ];
    scaleAnimation.keyTimes = @[ @0, @(15 / 90.0), @(45 / 90.0), @(75 / 90.0), @1 ];
    
    CAKeyframeAnimation *alphaAnimation = [CAKeyframeAnimation animation];
    alphaAnimation.keyPath = @"opacity";
    alphaAnimation.values = @[ @0, @1, @1, @1, @0 ];
    alphaAnimation.keyTimes = @[ @0, @(1 / 6.0), @(3 / 6.0), @(5 / 6.0), @1 ];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[positionAnimation, scaleAnimation, alphaAnimation];
    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    group.repeatCount = HUGE_VALF;
    group.duration = 1.3;
    
    [_shapeView1.layer addAnimation:group forKey:@"basic1"];
    group.timeOffset = .43;
    [_shapeView2.layer addAnimation:group forKey:@"basic2"];
    group.timeOffset = .86;
    [_shapeView3.layer addAnimation:group forKey:@"basic3"];
}


- (void)stopAnimation
{
    [_shapeView1.layer removeAllAnimations];
    [_shapeView2.layer removeAllAnimations];
    [_shapeView3.layer removeAllAnimations];
}


@end

@interface WARefreshAnimateHeader ()
{
    WARefreshAnimatorView *_animatorView;
    WARefreshAnimateHeaderStyle _style;
}

@end

@implementation WARefreshAnimateHeader

- (WARefreshAnimatorView *)animatorView
{
    if (!_animatorView) {
        _animatorView = [[WARefreshAnimatorView alloc] init];
        [self addSubview:_animatorView];
    }
    return _animatorView;
}


- (void)setStyle:(WARefreshAnimateHeaderStyle)style
{
    _style = style;
    if (style == WARefreshAnimateHeaderStyleDark) {
        [self.animatorView switchToDark];
    } else {
        [self.animatorView switchToLight];
    }
}

#pragma mark - 实现父类的方法
- (void)prepare
{
    [super prepare];
    
    // 初始化间距
    self.labelLeftInset = 20;
}

- (void)placeSubviews
{
    [super placeSubviews];
    self.animatorView.frame = self.bounds;
}

- (void)setPullingPercent:(CGFloat)pullingPercent
{
    [super setPullingPercent:pullingPercent];
    
    if (self.isRefreshing) return;
    
    if (self.isAutomaticallyChangeAlpha) {
        self.alpha = pullingPercent;
    }
}

- (void)setState:(MJRefreshState)state
{
    MJRefreshCheckState
    // 根据状态做事情
    if (state == MJRefreshStatePulling || state == MJRefreshStateRefreshing) {
        [self.animatorView beginAnimation];
    } else if (state == MJRefreshStateIdle) {
        [self.animatorView stopAnimation];
    }
}
@end
