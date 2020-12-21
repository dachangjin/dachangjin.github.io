//
//  UINavigationBar+Custom.h
//  weapps
//
//  Created by tommywwang on 2020/8/5.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnimationInfo : NSObject

@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, copy) NSString *timingFunc;

@end

@interface UINavigationBar (Custom) <CAAnimationDelegate>


- (void)setBackgroundColor:(UIColor *)backgroundColor withAnimationInfo:(AnimationInfo *_Nullable)info;

@end

NS_ASSUME_NONNULL_END
