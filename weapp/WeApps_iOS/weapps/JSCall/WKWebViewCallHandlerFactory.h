//
//  WKWebViewMessageHandlerFactory.h
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSAsyncCallBaseHandler.h"
NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewCallHandlerFactory : NSObject

+ (JSAsyncCallBaseHandler *)handlerByEvent:(JSAsyncEvent *)event;

@end

NS_ASSUME_NONNULL_END
