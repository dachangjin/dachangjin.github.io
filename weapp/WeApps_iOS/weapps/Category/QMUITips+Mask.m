//
//  QMUITips+Mask.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUITips+Mask.h"

@implementation QMUITips (Mask)

+ (QMUITips *)showLoading:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay
{
    QMUITips *tips = [self createTipsToView:view];
    if (!mask) {
        tips.userInteractionEnabled = NO;
    }
    [tips showLoading:text detailText:nil hideAfterDelay:delay];
    return tips;
}


+ (QMUITips *)showWithText:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay
{
    QMUITips *tips = [self createTipsToView:view];
    if (!mask) {
        tips.userInteractionEnabled = NO;
    }
    [tips showWithText:text detailText:nil hideAfterDelay:delay];
    return tips;
}

+ (QMUITips *)showSucceed:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay
{
    QMUITips *tips = [self createTipsToView:view];
    if (!mask) {
        tips.userInteractionEnabled = NO;
    }
      [tips showSucceed:text detailText:nil hideAfterDelay:delay];
      return tips;
}

+ (QMUITips *)showError:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay
{
    QMUITips *tips = [self createTipsToView:view];
    if (!mask) {
        tips.userInteractionEnabled = NO;
    }
    [tips showError:text detailText:nil hideAfterDelay:delay];
    return tips;
}

+ (QMUITips *)showInfo:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay
{
    QMUITips *tips = [self createTipsToView:view];
    if (!mask) {
        tips.userInteractionEnabled = NO;
    }
    [tips showInfo:text detailText:nil hideAfterDelay:delay];
    return tips;
}

@end
