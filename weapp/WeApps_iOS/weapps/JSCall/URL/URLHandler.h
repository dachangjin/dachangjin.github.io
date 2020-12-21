//
//  URLHandler.h
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface URLHandler : NSObject

/// 根据path获取URL
/// @param path 路径
- (NSURL *)URLByPath:(NSString *)path;

/// 是否处理request
/// @param request url请求
- (BOOL)handleRequest:(NSURLRequest*)request;

@end

NS_ASSUME_NONNULL_END
