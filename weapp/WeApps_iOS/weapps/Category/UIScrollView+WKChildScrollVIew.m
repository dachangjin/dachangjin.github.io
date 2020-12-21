//
//  UIScrollView+WKChildScrollVIew.m
//  weapps
//
//  Created by tommywwang on 2020/7/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "UIScrollView+WKChildScrollVIew.h"
#import <objc/runtime.h>
#import "QMUIRuntime.h"

@interface UIView (hittest)

@end

@implementation UIView (hittest)

+ (void)load
{
//    ExchangeImplementationsInTwoClasses(NSClassFromString(@"WKCompositingView"), @selector(hitTest:withEvent:), [self class], @selector(_hitTest:withEvent:));
//    ExchangeImplementationsInTwoClasses(NSClassFromString(@"WKCompositingView"), @selector(nextResponder), [self class], @selector(_nextResponder));
//    ExchangeImplementationsInTwoClasses(NSClassFromString(@"WKCompositingView"), @selector(touchesBegan:withEvent:), [self class], @selector(_touchesBegan:withEvent:));
//    ExchangeImplementationsInTwoClasses(NSClassFromString(@"WKCompositingView"), @selector(gestureRecognizerShouldBegin:), [self class], @selector(_gestureRecognizerShouldBegin:));
}

//- (BOOL)_gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
//{
//    return NO;
//}

//- (void)_touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
//{
//    NSLog(@"_touchesBegan");
//    [super touchesBegan:touches withEvent:event];
//}

//- (UIView *)_hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01) {
//            return nil;
//        }
//    if ([self pointInside:point withEvent:event]) {
//        for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
//            CGPoint convertedPoint = [subview convertPoint:point fromView:self];
//            UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
//            if (hitTestView) {
//                return hitTestView;
//            }
//        }
//        return self;
//    }
//    return nil;
//}

//- (UIResponder *)_nextResponder
//{
//    for (UIView *view in self.superview.subviews) {
//        if ([view isKindOfClass:NSClassFromString(@"WAContainerView")]) {
//            return view;
//        }
//    }
//    return self.superview;
//}

//- (UIResponder *)nextResponder
//{
//    if ([self isKindOfClass:NSClassFromString(@"WKCompositingView")]) {
//        return self.superview;
//    }
//    return self.superview;
//}

@end


@implementation UIScrollView (WKChildScrollVIew)



//
//- (UIView *)_hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    if (!self.isUserInteractionEnabled || self.isHidden || self.alpha <= 0.01) {
//            return nil;
//        }
//        if ([self pointInside:point withEvent:event]) {
//            for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
//                CGPoint convertedPoint = [subview convertPoint:point fromView:self];
//                UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
//                if (hitTestView) {
//                    return hitTestView;
//                }
//            }
//            return self;
//        }
//        return nil;
//}
//
//+ (void)load
//{
//    BOOL success = ExchangeImplementationsInTwoClasses([self class], @selector(_hitTest:withEvent:), NSClassFromString(@"WKChildScrollView"), @selector(hitTest:withEvent:));
//    WALOG(@"success:%d",success);
//}



- (void)setBoundsChangeBlock:(BoundsChangeBlock)boundsChangeBlock
{
    objc_setAssociatedObject(self, @selector(boundsChangeBlock), boundsChangeBlock, OBJC_ASSOCIATION_COPY);
}

- (BoundsChangeBlock)boundsChangeBlock
{
    return objc_getAssociatedObject(self, @selector(boundsChangeBlock));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if ([self isKindOfClass:NSClassFromString(@"WKChildScrollView")]) {
        if (self.boundsChangeBlock) {
            self.boundsChangeBlock(self.bounds);
        }
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
}



@end
