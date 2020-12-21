//
//  FaceIdResult.m
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "FaceIdResult.h"

@implementation FaceIdResult

+ (id)objectWithDic:(NSDictionary *)dic
{
    FaceIdResult *result = [[FaceIdResult alloc] init];
    result.bizSeqNo = dic[@"bizSeqNo"];
    result.orderNo = dic[@"orderNo"];
    result.faceId = dic[@"faceId"];
    return result;
}

@end
