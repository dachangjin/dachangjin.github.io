//
//  TicketResult.m
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TicketResult.h"

@implementation TicketResult

+ (id)objectWithDic:(NSDictionary *)dic
{
    NSDictionary *resultDic = [dic[@"tickets"] firstObject];
    TicketResult *result = [[TicketResult alloc] init];
    result.expire_in = [resultDic[@"expire_in"] intValue];
    result.ticket = resultDic[@"value"];
    result.expire_time = resultDic[@"expire_time"];
    return result;
}

@end
