//
//  ScanQRCodeViewController.h
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QMUICommonViewController.h"

NS_ASSUME_NONNULL_BEGIN


/** 完成回调

 @param codeInfo 二维码信息
 */
typedef void(^CompletionHandler)(NSString *codeInfo);


/**
 扫描二维码视图控制器
 */
@interface ScanQRCodeViewController : QMUICommonViewController

/**
 完成回调
 */
@property (nonatomic ,strong)CompletionHandler handler;

@end

NS_ASSUME_NONNULL_END
