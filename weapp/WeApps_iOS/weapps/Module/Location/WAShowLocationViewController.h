//
//  WAShowLocationViewController.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface WAShowLocationViewController : QMUICommonViewController


/// 参数
/*
 latitude：纬度
 longitude：经度
 scale：缩放比例
 name：位置名
 address：地址详细说明
 */
@property (nonatomic, strong) NSDictionary *params;

@end

NS_ASSUME_NONNULL_END
