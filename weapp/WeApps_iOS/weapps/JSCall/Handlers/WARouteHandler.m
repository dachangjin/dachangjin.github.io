//
//  WARouteHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WARouteHandler.h"

kSELString(openWindow)
kSELString(navigateTo)
kSELString(navigateBack)

@implementation WARouteHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            openWindow,
            navigateTo,
            navigateBack
        ];
    }
    return methods;
}

JS_API(openWindow){
    return [self js_navigateTo:event];
}

JS_API(navigateTo){
    
    kBeginCheck
    kEndCheck([NSString class], @"url", NO)
    
    NSDictionary *dic = event.args;
    NSString *url = dic[@"url"];
    if (url.length && [url isKindOfClass:[NSString class]]) {
        [event.webView.webHost openWindowWithPathComponent:url success:event.success fail:event.fail];
    } else {
        kFailWithError(navigateTo, -1, @"url: params invalid")
    }
    return @"";
}

JS_API(navigateBack){
    NSDictionary *dic = event.args;
    NSUInteger delta = 1;
    if (kWA_DictContainKey(dic, @"delta")) {
        delta = [dic[@"delta"] integerValue];
    }
    [event.webView.webHost popWithDelta:delta
                                     success:event.success
                                        fail:event.fail];
    return @"";
}


@end
