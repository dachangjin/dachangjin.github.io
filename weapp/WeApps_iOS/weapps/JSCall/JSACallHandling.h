//
//  JSCallHandling.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#ifndef JSCallHandling_h
#define JSCallHandling_h


#import <Foundation/Foundation.h>
#import "JSAsyncEvent.h"



/// 处理JS调用本地无返回值接口 协议
@protocol JSACallHandling <NSObject>

@optional
/// 本地注册方法名
- (NSArray<NSString *> *)callingMethods;


/// 处理事件
/// @param event 事件
- (NSString *)handleEvent:(JSAsyncEvent *)event;

@end

#endif /* JSCallHandling_h */
