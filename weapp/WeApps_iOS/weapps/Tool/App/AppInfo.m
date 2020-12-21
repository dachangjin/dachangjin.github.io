//
//  AppInfo.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AppInfo.h"

@implementation AppInfo

+ (NSString *)appName
{
    NSString *name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBunddleDisplayName"];
    if (!name) {
        name = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    return name;
}

+ (NSString *)appId
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

+ (NSString *)appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)appBuildVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

@end
