//
//  ScanQRCodeMaskView.m
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "ScanQRCodeMaskView.h"
#import "UIImage+Addition.h"

static NSString *const kAnimationKey = @"shake";

@interface ScanQRCodeMaskView ()
@property (nonatomic ,assign)CGRect pickingFieldRect;
@property (nonatomic, strong) UIImageView * line;
@property (nonatomic ,strong) CAKeyframeAnimation *animation;
@end

@implementation ScanQRCodeMaskView

- (id)initWithFrame:(CGRect)frame andMaskFrame:(CGRect)maskFrame
{
    if (self = [super initWithFrame:frame]) {
        _pickingFieldRect = maskFrame;
        _line = [[UIImageView alloc] init];
        _line.frame = CGRectMake(maskFrame.origin.x + 5,maskFrame.origin.y + maskFrame.size.height / 2 ,maskFrame.size.width - 10,2);
        _line.image = [UIImage imageNamed:@"line" resizedImageforwidthPercent:0.5 andheightPercent:0.5];
        UILabel *lable = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width / 2 - 150, CGRectGetMaxY(maskFrame) + 30, 300, 30)];
        lable.backgroundColor = [UIColor clearColor];
        lable.textAlignment = NSTextAlignmentCenter;
        lable.font = [UIFont systemFontOfSize:18];
        lable.textColor = [UIColor whiteColor];
        lable.text = @"请将取景框对准二维码";
        [self addSubview:lable];
        [self addSubview:_line];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:maskFrame];
        [imageView setImage:[UIImage imageNamed:@"capture" resizedImageforwidthPercent:0.5 andheightPercent:0.5]];
        [self addSubview:imageView];
        [self createAnimation];
    }
    return self;
}

- (void)createAnimation
{
    _animation = [CAKeyframeAnimation animation];
    _animation.keyPath = @"position.y";
    _animation.values = @[ @0, @130, @(-130), @0 ];
    _animation.keyTimes = @[@0,@(1.0/4),@(3.0/4),@1];
    _animation.duration = 3;
    _animation.additive = YES;
    _animation.repeatCount = HUGE_VALF;
}

- (void)startAnimation
{
    
    [_line.layer addAnimation:_animation forKey:kAnimationKey];
}

- (void)stopAnimation
{
    [_line.layer removeAnimationForKey:kAnimationKey];
}


- (void)drawRect:(CGRect)rect {
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    CGContextSaveGState(contextRef);
    CGContextSetRGBFillColor(contextRef, 0, 0, 0, 0.4);
    CGContextSetLineWidth(contextRef, 3);
    
    UIBezierPath *pickingFieldPath = [UIBezierPath bezierPathWithRect:self.pickingFieldRect];
    UIBezierPath *bezierPathRect = [UIBezierPath bezierPathWithRect:rect];
    [bezierPathRect appendPath:pickingFieldPath];
    bezierPathRect.usesEvenOddFillRule = YES;
    [bezierPathRect fill];
    CGContextSetLineWidth(contextRef, 2);
    CGFloat dash[2] = {4,4};
    [pickingFieldPath setLineDash:dash count:2 phase:0];
    CGContextRestoreGState(contextRef);
    self.layer.contentsGravity = kCAGravityCenter;
}

@end
