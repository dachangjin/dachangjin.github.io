//
//  JSEvent.h
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WebView;

@interface JSEvent : NSObject


/// 方法名
@property (nonatomic, copy) NSString *funcName;

/// 参数，funcName带有sync的为数组，否则为字典
@property (nonatomic, copy, nullable) id args;

/// 事件所发生所在webView
@property (nonatomic, strong) WebView *webView;


@end

NS_ASSUME_NONNULL_END
