//
//  WAFaceVerifyViewController.h
//  weapps
//
//  Created by tommywwang on 2020/6/23.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUICommonViewController.h"

NS_ASSUME_NONNULL_BEGIN


@interface WAFaceVerifyViewController : QMUICommonViewController

@property (nonatomic, copy) void(^completion)(NSDictionary * _Nullable result,NSError *_Nullable error);

@end

NS_ASSUME_NONNULL_END
