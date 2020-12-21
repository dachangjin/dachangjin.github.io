//
//  WBQRCodeVC.h
//  SGQRCodeExample
//
//  Created by kingsic on 2018/2/8.
//  Copyright © 2018年 kingsic. All rights reserved.
//
#import "QMUICommonViewController.h"


@interface WBQRCodeVC : QMUICommonViewController
@property (nonatomic, copy) void(^scanCodeCallBack)(NSDictionary *codeInfo);
@property (nonatomic, strong) NSDictionary *scanPrams;
@end
 
