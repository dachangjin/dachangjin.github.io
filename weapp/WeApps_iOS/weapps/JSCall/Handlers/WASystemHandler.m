//
//  WASystemHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WASystemHandler.h"
#import "Device.h"
#import "AppInfo.h"
#import "JSONHelper.h"
#import "NSDate+ToString.h"
#import "NSMutableDictionary+NilCheck.h"
#import "AppConfig.h"

kSELString(getSystemInfo)
kSELString(getSystemInfoSync)
kSELString(getOSVersionCodeSync)
kSELString(getOSVersionCode)

@implementation WASystemHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            getSystemInfo,
            getSystemInfoSync,
            getOSVersionCode,
            getOSVersionCodeSync
        ];
    }
    return methods;
}



JS_API(getSystemInfo){
    NSMutableDictionary *mulDict = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(mulDict, @"brand", @"Apple");
    kWA_DictSetObjcForKey(mulDict, @"model", [Device platformString]);
    kWA_DictSetObjcForKey(mulDict, @"timestamp", [[NSDate date] stringByFormat:@"yyyy-MM-dd HH:mm:ss"]);
    kWA_DictSetObjcForKey(mulDict, @"pixelRatio", @([Device pixelRatio]));
    kWA_DictSetObjcForKey(mulDict, @"screenWidth", @(K_SCREEN_WIDTH));
    kWA_DictSetObjcForKey(mulDict, @"screenHeight", @(K_SCREEN_HEIGHT));
    kWA_DictSetObjcForKey(mulDict, @"windowWidth", @(event.webView.scrollView.frame.size.width));
    kWA_DictSetObjcForKey(mulDict, @"windowHeight", @(event.webView.scrollView.frame.size.height));
    kWA_DictSetObjcForKey(mulDict, @"statusBarHeight", @([Device statusBarHeight]));
    kWA_DictSetObjcForKey(mulDict, @"system", [Device systemName]);
    kWA_DictSetObjcForKey(mulDict, @"version", [AppInfo appVersion]);
    kWA_DictSetObjcForKey(mulDict, @"name", [AppInfo appName]);
    kWA_DictSetObjcForKey(mulDict, @"appId", [AppInfo appId]);
    kWA_DictSetObjcForKey(mulDict, @"sdk-version",SDK_VERSION);
    if (event.success) {
        event.success(mulDict);
    }
    return @"";
}

JS_API(getSystemInfoSync){
    NSMutableDictionary *mulDict = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(mulDict, @"brand", @"Apple");
    kWA_DictSetObjcForKey(mulDict, @"model", [Device platformString]);
    kWA_DictSetObjcForKey(mulDict, @"timestamp", [[NSDate date] stringByFormat:@"yyyy-MM-dd HH:mm:ss"]);
    kWA_DictSetObjcForKey(mulDict, @"pixelRatio", @([Device pixelRatio]));
    kWA_DictSetObjcForKey(mulDict, @"screenWidth", @(K_SCREEN_WIDTH));
    kWA_DictSetObjcForKey(mulDict, @"screenHeight", @(K_SCREEN_HEIGHT));
    kWA_DictSetObjcForKey(mulDict, @"windowWidth", @(event.webView.scrollView.frame.size.width));
    kWA_DictSetObjcForKey(mulDict, @"windowHeight", @(event.webView.scrollView.frame.size.height));
    kWA_DictSetObjcForKey(mulDict, @"statusBarHeight", @([Device statusBarHeight]));
    kWA_DictSetObjcForKey(mulDict, @"system", [Device systemName]);
    kWA_DictSetObjcForKey(mulDict, @"version", [AppInfo appVersion]);
    kWA_DictSetObjcForKey(mulDict, @"name", [AppInfo appName]);
    kWA_DictSetObjcForKey(mulDict, @"appId", [AppInfo appId]);
    kWA_DictSetObjcForKey(mulDict, @"sdk-version",SDK_VERSION);


    return [JSONHelper exchengeDictionaryToString:mulDict];
}

JS_API(getOSVersionCode){
    kSuccessWithDic(@{
        @"version": [Device systemVersion]
                    })
    return @"";
}

JS_API(getOSVersionCodeSync){
    return [Device systemVersion];
}

@end
