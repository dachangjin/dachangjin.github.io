//
//  QMUITips+Mask.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface QMUITips (Mask)

+ (QMUITips *)showLoading:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay;


+ (QMUITips *)showWithText:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay;

+ (QMUITips *)showSucceed:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay;

+ (QMUITips *)showError:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay;

+ (QMUITips *)showInfo:(NSString *)text mask:(BOOL)mask inView:(UIView *)view hideAfterDelay:(NSTimeInterval)delay;

@end

NS_ASSUME_NONNULL_END
