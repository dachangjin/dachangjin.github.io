//
//  WAContainerView.h
//  weapps
//
//  Created by tommywwang on 2020/10/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WAContainerView;

typedef void(^WAContainerViewBlock)(WAContainerView *containerView);


@interface WAContainerView : UIView


/// 不透传事件的范围，由前端传入
@property (nonatomic, assign) CGRect resignRect;

- (void)addViewWillDeallocBlock:(WAContainerViewBlock)viewWillDeallocBlock;

@end

NS_ASSUME_NONNULL_END
