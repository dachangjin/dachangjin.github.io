//
//  WADebugViewController.h
//  weapps
//
//  Created by tommywwang on 2020/7/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface WADebugViewController : QMUICommonViewController

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

NS_ASSUME_NONNULL_END
