//
//  BaseCommon.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "JSAsyncCallBaseHandler.h"

NS_ASSUME_NONNULL_BEGIN

@interface Base64Common : NSObject

+(NSData *)dataFromBase64String:(NSString *)base64String;
+(NSString *)base64StringFromData:(NSData *)data;
+(NSString *)base64UrlEncodedStringFromBase64String:(NSString *)base64String;
+(NSString *)base64StringFromBase64UrlEncodedString:(NSString *)base64UrlEncodedString;

@end

NS_ASSUME_NONNULL_END
