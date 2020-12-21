//
//  WATabBar.h
//  weapps
//
//  Created by tommywwang on 2020/7/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WAConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface WATabBar : UIView

@property (nonatomic, strong, readonly) WATabBarConfig *config;

- (void)setTabBarConfig:(WATabBarConfig *)config;

- (void)showRedDotAtIndex:(NSUInteger)index;

- (void)hideRedDotAtIndex:(NSUInteger)index;

- (void)setBadge:(NSString *)badge atIndex:(NSUInteger)index;

- (void)removeBadgeAtIndex:(NSUInteger)index;

- (void)updateTabBarBackgroundColor:(UIColor *)backgroundColor
                          itemColor:(UIColor *)itemColor
                  selectedItemColor:(UIColor *)selectedItemColor
                        borderStyle:(WATabBarBorderStyle)style;

- (void)updateTabBarItemText:(NSString *)text
                    iconPath:(NSString *)iconPath
            selectedIconPath:(NSString *)selectedIconPath
                     atIndex:(NSUInteger)index;


- (void)setSelectAtIndex:(NSUInteger)index ignoreCallback:(BOOL)ignore;

- (void)setSelectOfUrlHash:(NSString *)hash ignoreCallback:(BOOL)ignore;

- (void)setSelectBlock:(void(^)(NSString *urlHash, NSUInteger index))block;

- (CGFloat)hintHeight;

@end

NS_ASSUME_NONNULL_END
