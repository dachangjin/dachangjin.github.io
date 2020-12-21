//
//  NSDictionary+JSON.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NSDictionary+JSON.h"
#import "JSONHelper.h"

@implementation NSDictionary (JSON)
- (NSString *)toJsonString
{
    return [JSONHelper exchengeDictionaryToString:self];
}
@end
