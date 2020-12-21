//
//  WAShareHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAShareHandler.h"
#import "WXApiManager.h"
#import "NSData+Base64.h"

kSELString(shareWebPage)
kSELString(shareImage)
kSELString(shareText)

@implementation WAShareHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            shareWebPage,
            shareImage,
            shareText
        ];
    }
    return methods;
}

JS_API(shareWebPage){
    enum WXScene scence = WXSceneSession;
    NSDictionary *args = event.args;
    NSInteger platform = [args[@"platform"] integerValue];
    switch (platform) {
        case 1:
            scence = WXSceneTimeline;
            break;
        case 2:
            scence = WXSceneSession;
            break;
        case 3:
            scence = WXSceneFavorite;
            break;
            
        default:
            break;
    }
    NSString *base64String = args[@"base64"];
    [[WXApiManager sharedManager] sendLinkContent:args[@"url"]
                                            title:args[@"title"]
                                      description:args[@"description"]
                                        thumbData:[NSData dataWithBase64String:base64String]
                                          atScene:scence
                                    completeBlock:^(BOOL success)
     {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            [self event:event failWithError:nil];
        }
    }];
    return @"";
}

JS_API(shareImage){
    enum WXScene scence = WXSceneSession;
    NSDictionary *args = event.args;
    NSInteger platform = [args[@"platform"] integerValue];
    switch (platform) {
       case 1:
           scence = WXSceneTimeline;
           break;
       case 2:
           scence = WXSceneSession;
           break;
       case 3:
           scence = WXSceneFavorite;
           break;
           
       default:
           break;
    }
    NSString *base64String = args[@"base64"];
    [[WXApiManager sharedManager] sendImage:[NSData dataWithBase64String:base64String]
                                    atScene:scence
                              completeBlock:^(BOOL success)
    {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            [self event:event failWithError:nil];
        }
    }];
    return @"";
}

JS_API(shareText){
    enum WXScene scence = WXSceneSession;
    NSDictionary *args = event.args;
    NSInteger platform = [args[@"platform"] integerValue];
    switch (platform) {
       case 1:
           scence = WXSceneTimeline;
           break;
       case 2:
           scence = WXSceneSession;
           break;
       case 3:
           scence = WXSceneFavorite;
           break;
           
       default:
           break;
    }
    
    [[WXApiManager sharedManager] sendText:args[@"text"]
                                   atScene:scence
                             completeBlock:^(BOOL success)
    {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            [self event:event failWithError:nil];
        }
    }];
    return @"";
}

@end
