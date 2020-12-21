//
//  AFURLSessionManager+JSONRequest.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AFURLSessionManager.h"

NS_ASSUME_NONNULL_BEGIN


typedef void (^JSONCallBack)(NSDictionary *_Nullable dict, NSError *_Nullable error);

@interface AFURLSessionManager (JSONRequest)

/**
 *  网络请求建立的统一接口.
 *
 *  @param host          请求的Host
 *  @param params          请求的参数
 *  @param configKeyPath 请求的配置ID， 详情阅读WXNetworkConfigManager
 *  @param handler       请求完成时的回调
 *
 */

- (NSURLSessionTask *)JSONTaskForHost:(NSString *)host
                               params:(NSDictionary *)params
                        configKeyPath:(NSString *)configKeyPath
                       withCompletion:(JSONCallBack)handler;


- (NSURLSessionTask *)JSONTaskForURL:(NSString *)URLString
                              method:(NSString *)method
                              params:(NSDictionary *)params
                      withCompletion:(JSONCallBack)handler;
@end

NS_ASSUME_NONNULL_END
