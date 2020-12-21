//
//  NSString+Base64.m
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NSString+Base64.h"
#import "Base64Common.h"
#import "CommonCrypto/CommonDigest.h"


@implementation NSString (Base64)

-(NSString *)base64String
{
    NSData *utf8encoding = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [Base64Common base64StringFromData:utf8encoding];
}
- (NSString *)base64UrlEncodedString
{
    return [Base64Common base64UrlEncodedStringFromBase64String:[self base64String]];
}
+ (NSString *)stringFromBase64String:(NSString *)base64String
{
    NSData *utf8encoding = [Base64Common dataFromBase64String:base64String];
    return [[NSString alloc] initWithData:utf8encoding encoding:NSUTF8StringEncoding];
}
+( NSString *)stringFromBase64UrlEncodedString:(NSString *)base64UrlEncodedString
{
    return [self stringFromBase64String:[Base64Common base64StringFromBase64UrlEncodedString:base64UrlEncodedString]];
}

- (NSString *)MD5String
{
    
    const char *cStr = self.UTF8String;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    
    NSMutableString *md5Str = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        [md5Str appendFormat:@"%02x", result[i]];
    }
    return md5Str;
    
}

- (NSString *)SHA1String
{
    
    const char *cStr = self.UTF8String;
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cStr, (CC_LONG)strlen(cStr), result);
    
    NSMutableString *sha1Str = [NSMutableString string];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
        [sha1Str appendFormat:@"%02x", result[i]];
    }
    return sha1Str;
    
}


- (NSString *)encodeURIString {
    // 完全对齐js中encodeURI()的实现
    // 参考: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURI
    NSMutableCharacterSet* validSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [validSet formUnionWithCharacterSet:[NSMutableCharacterSet letterCharacterSet]];
    [validSet addCharactersInString:@"!#$&'()*+,-./:;=?@_~"];
    return [self encodeStringWithAllowedCharacters:validSet];
}
- (NSString *)encodeURIComponentString {
    // 完全对齐js中encodeURIComponent()的实现
    // 参考: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent
    NSMutableCharacterSet* validSet = [NSMutableCharacterSet decimalDigitCharacterSet];
    [validSet formUnionWithCharacterSet:[NSMutableCharacterSet letterCharacterSet]];
    [validSet addCharactersInString:@"!'()*-._~"];
    return [self encodeStringWithAllowedCharacters:validSet];
}
- (NSString *)encodeStringWithAllowedCharacters:(NSCharacterSet *)allowedCharacters {
    // 要分段做urlencode
    // 因为低版本iOS（iPhone5 iOS8）的stringByAddingPercentEncodingWithAllowedCharacters在处理中文长字符时会疯狂使用内存导致crash
#define ENCODE_STEP 50
    
    NSMutableString* encodedString = [NSMutableString string];
    
    NSInteger index = 0;
    NSInteger len = self.length;
    while (index < len)
    {
        NSInteger subStringLen = index + ENCODE_STEP < len ? ENCODE_STEP : len - index;
        NSString* subString = [self substringWithRange:NSMakeRange(index, subStringLen)];
        [encodedString appendString:[subString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters] ?: @""];
        index += subStringLen;
    }
    
    return encodedString;
}

- (NSDictionary *)URLQueryToObject
{
    NSArray *array = [self componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *query in array) {
        NSArray *kv = [query componentsSeparatedByString:@"="];
        NSString *key = [kv firstObject];
        NSString *value = [kv lastObject];
        if (key && value) {
            params[key] = value;
        }
    }
    return [params copy];
}


@end
