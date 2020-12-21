//
//  WADebugInfo.m
//  weapps
//
//  Created by tommywwang on 2020/7/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WADebugInfo.h"
#import "QMUIKit.h"

@interface WADebugInfo ()
@property(nonatomic, strong) UIWindow *consoleWindow;
@property (nonatomic, strong) QMUIButton *popoverButton;
@property(nonatomic, strong) UIPanGestureRecognizer *popoverPanGesture;
@property (nonatomic, copy) void(^infoButtonClickBlock)(__kindof UIControl *sender);
@end

@implementation WADebugInfo
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static WADebugInfo *instance = nil;
    dispatch_once(&onceToken,^{
        instance = [[super allocWithZone:NULL] init];
        instance.canShow = IS_DEBUG;
        [instance initConsoleWindowIfNeeded];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone{
    return [self sharedInstance];
}


- (void)setButtonClickBlock:(void (^)(__kindof UIControl * _Nonnull))block
{
    self.infoButtonClickBlock = block;
}

- (void)show {
    if (self.canShow) {
        self.popoverButton.hidden = NO;
    }
}

- (void)hide {
    self.popoverButton.hidden = YES;
}

- (void)initConsoleWindowIfNeeded {
    if (!self.consoleWindow) {
        self.consoleWindow = [[UIApplication sharedApplication].windows firstObject];
        [self.consoleWindow addSubview:self.popoverButton];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self.consoleWindow bringSubviewToFront:self.popoverButton];
        });
    }
}


- (QMUIButton *)popoverButton {
    if (!_popoverButton) {
        _popoverButton = [[QMUIButton alloc] initWithFrame:CGRectMake(30, 200, 40, 40)];
        _popoverButton.layer.masksToBounds = YES;
        _popoverButton.adjustsButtonWhenHighlighted = NO;
        _popoverButton.backgroundColor = [[QMUIConsole appearance].backgroundColor colorWithAlphaComponent:.3];
        _popoverButton.layer.cornerRadius = CGRectGetHeight(_popoverButton.bounds) / 2;
        _popoverButton.clipsToBounds = YES;
        _popoverButton.highlightedBackgroundColor = [[QMUIConsole appearance].backgroundColor colorWithAlphaComponent:.5];
        
        self.popoverPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                         action:@selector(handlePopoverPanGestureRecognizer:)];
        [_popoverButton addGestureRecognizer:self.popoverPanGesture];
        
        @weakify(self)
        [_popoverButton setQmui_tapBlock:^(__kindof UIControl *sender) {
            @strongify(self)
            if (self.infoButtonClickBlock) {
                self.infoButtonClickBlock(sender);
            }
        }];

    }
    return _popoverButton;
}

- (void)handlePopoverPanGestureRecognizer:(UIPanGestureRecognizer *)gesture {
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            [self.popoverButton qmui_bindObject:[NSValue valueWithCGPoint:self.popoverButton.frame.origin] forKey:@"origin"];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:self.consoleWindow];
            self.popoverButton.transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
        }
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed: {
            CGRect popoverButtonFrame = [self safetyPopoverButtonFrame:self.popoverButton.frame];
            BOOL animated = CGRectEqualToRect(popoverButtonFrame, self.popoverButton.frame);
            [UIView qmui_animateWithAnimated:animated duration:.25
                                       delay:0
                                     options:QMUIViewAnimationOptionsCurveOut animations:^{
                self.popoverButton.transform = CGAffineTransformIdentity;
                self.popoverButton.frame = popoverButtonFrame;
            } completion:^(BOOL finished) {
                [self.popoverButton qmui_bindObject:[NSValue valueWithCGPoint:popoverButtonFrame.origin] forKey:@"origin"];
            }];
        }
            break;
        default:
            break;
    }
}

- (CGRect)safetyPopoverButtonFrame:(CGRect)popoverButtonFrame {
    CGRect safetyBounds = CGRectInsetEdges(self.consoleWindow.bounds, self.consoleWindow.qmui_safeAreaInsets);
    if (!CGRectContainsRect(safetyBounds, self.popoverButton.frame)) {
        popoverButtonFrame = CGRectSetX(popoverButtonFrame,
                                        MAX(self.consoleWindow.qmui_safeAreaInsets.left,
                                            MIN(CGRectGetMaxX(safetyBounds) - CGRectGetWidth(popoverButtonFrame),
                                                CGRectGetMinX(popoverButtonFrame))));
        popoverButtonFrame = CGRectSetY(popoverButtonFrame,
                                        MAX(self.consoleWindow.qmui_safeAreaInsets.top,
                                            MIN(CGRectGetMaxY(safetyBounds) - CGRectGetHeight(popoverButtonFrame),
                                                CGRectGetMinY(popoverButtonFrame))));
    }
    return popoverButtonFrame;
}


@end
