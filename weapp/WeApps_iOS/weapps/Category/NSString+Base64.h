//
//  NSString+Base64.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Base64)

+ (NSString *)stringFromBase64String:(NSString *)base64String;
+ (NSString *)stringFromBase64UrlEncodedString:(NSString *)base64UrlEncodedString;
- (NSString *)base64String;
- (NSString *)base64UrlEncodedString;
- (NSString *)MD5String;
- (NSString *)SHA1String;

// 对齐js的encodeURI()实现，主要用来编码整条url
- (NSString *)encodeURIString;

// 对齐js的encodeURLComponent()实现，主要用来编码query中的参数
- (NSString *)encodeURIComponentString;

//url中query转为字典
- (NSDictionary *)URLQueryToObject;
@end

NS_ASSUME_NONNULL_END
