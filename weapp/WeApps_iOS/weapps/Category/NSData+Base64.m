//
//  NSData+Base64.m
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NSData+Base64.h"
#import "Base64Common.h"

@implementation NSData (Base64)

+(NSData *)dataWithBase64String:(NSString *)base64String
{
    if (!base64String) {
        return nil;
    }
    if ([base64String containsString:@","]) {
        base64String = [[base64String componentsSeparatedByString:@","] lastObject];
    }
    return [Base64Common dataFromBase64String:base64String];
}

+(NSData *)dataWithBase64UrlEncodedString:(NSString *)base64UrlEncodedString
{
    if (!base64UrlEncodedString) {
        return nil;
    }
    return [self dataWithBase64String:[Base64Common base64StringFromBase64UrlEncodedString:base64UrlEncodedString]];
}

-(NSString *)base64String
{
    return [Base64Common base64StringFromData:self];
}

-(NSString *)base64UrlEncodedString
{
    return [Base64Common base64UrlEncodedStringFromBase64String:[self base64String]];
}


- (NSArray<NSNumber *> *)byteArray
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.length];
    for (NSUInteger index = 0; index < self.length; index ++) {
        char byte;
        [self getBytes:&byte range:NSMakeRange(index, 1)];
        [array addObject:@(byte)];
    }
    return array;
}
@end
