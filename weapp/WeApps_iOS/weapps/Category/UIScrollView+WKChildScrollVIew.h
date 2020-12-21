//
//  UIScrollView+WKChildScrollVIew.h
//  weapps
//
//  Created by tommywwang on 2020/7/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^BoundsChangeBlock)(CGRect rect);

@interface UIScrollView (WKChildScrollVIew)

@property (nonatomic, copy) BoundsChangeBlock boundsChangeBlock;

@end

NS_ASSUME_NONNULL_END
