//
//  JSONHelper.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "JSONHelper.h"

@implementation JSONHelper

+ (NSString *)exchengeDictionaryToString:(id)dic
{
    if (!dic) {
        return nil;
    }
    if ([dic isKindOfClass:[NSString class]]) {
        return dic;
    }
    if ([dic isKindOfClass:[NSNumber class]]) {
        return [dic stringValue];
    }
    @try {
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
        NSLog(@"%@",error);
        if (!data || error) {
            return nil;
        }
        NSString *messageJSON = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
//        messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
        return messageJSON;
    } @catch (NSException *exception) {
        WALOG(@"error:JSONHelper::exchengeDictionaryToString {%@}",exception.description);
        return nil;
    }
}


+ (id)exchangeStringToDictionary:(NSString *)string
{
    if (!string) {
        return nil;
    }
    if ([string isKindOfClass:[NSDictionary class]] || [string isKindOfClass:[NSArray class]]){
        return string;
    }
    NSError *error = nil;
    id dic = [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]
                                             options:NSJSONReadingAllowFragments error:&error];
    if (error != nil) {
        return nil;
    }
    return dic;
}

@end
