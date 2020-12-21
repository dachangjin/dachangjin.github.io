//
//  AccessTokenResult.m
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AccessTokenResult.h"

@implementation AccessTokenResult


+ (id)objectWithDic:(NSDictionary *)dic
{
    AccessTokenResult *result = [[AccessTokenResult alloc] init];
    result.bizSeqNo = dic[@"bizSeqNo"];
    result.transactionTime = dic[@"transactionTime"];
    result.access_token = dic[@"access_token"];
    result.expire_time = dic[@"expire_time"];
    result.expire_in = [dic[@"expire_in"] intValue];
    
    return result;
}

@end
