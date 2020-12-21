//
//  WAConfig.m
//  weapps
//
//  Created by tommywwang on 2020/7/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAConfig.h"

@implementation WAWindowConfig


- (id)initWithDic:(NSDictionary *)dict;
{
    
    self = [super init];
    if (self) {
        self.navigationBarBackgroundColor = dict[@"navigationBarBackgroundColor"];
        self.navigationBarTextStyle = kStringEqualToString(@"black", dict[@"navigationBarTextStyle"]) ? WANavigationBarTextStyleBlack : WANavigationBarTextStyleWhite;
        self.navigationBarTitleText = dict[@"navigationBarTitleText"] ?: @"";
        self.backgroundColor = dict[@"backgroundColor"];
        self.backgroundColorBottom = dict[@"backgroundColorBottom"];
        self.backgroundColorTop = dict[@"backgroundColorTop"];
        self.backgroundTextStyle = kStringEqualToString(@"light", dict[@"backgroundTextStyle"]) ? WABackgroundTextStyleLight : WABackgroundTextStyleDark;
        self.navigationStyle = kStringEqualToString(@"custom", dict[@"navigationStyle"]) ? WANavigationStyleCustom : WANavigationStyleDefault;
    }
    return self;
}

@end

@implementation WAPageConfig

- (id)initWithDic:(NSDictionary *)dict;
{
    self = [super initWithDic:dict];
    if (self) {
        self.pageHash = dict[@"pagePath"];
    }
    return self;
}

@end


@implementation WATabBarItemConfig

- (id)initWithDic:(NSDictionary *)dict;
{
    if (self = [super init]) {
        self.pageHash = dict[@"pagePath"];
        self.text = dict[@"text"];
        self.iconPath = dict[@"iconPath"];
        self.selectedIconPath = dict[@"selectedIconPath"];
    }
    return self;
}

@end


@implementation WATabBarConfig

- (id)initWithDic:(NSDictionary *)dict;
{
    if (self = [super init]) {
        self.borderStyle = kStringEqualToString(dict[@"borderStyle"], @"white") ? WATabBarBorderStyleWhite : WATabBarBorderStyleBlack;
        self.position = kStringEqualToString(dict[@"position"], @"top") ? WATabBarPositionTop : WATabBarPositionBottom;
        self.color = dict[@"color"];
        self.selectedColor = dict[@"selectedColor"];
        self.backgroundColor = dict[@"backgroundColor"];
        
        NSMutableArray *array = [NSMutableArray array];
        NSArray *items = dict[@"list"];
        for (NSDictionary *item in items) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                WATabBarItemConfig *config = [[WATabBarItemConfig alloc] initWithDic:item];
                if (self.position == WATabBarPositionBottom) {
                    config.hasIcon = YES;
                }
                [array addObject:config];
            }
        }
        self.tabBarItems = [array copy];
        self.hiden = NO;
    }
    return self;
}

@end


@implementation WANetworkConfig

- (id)initWithDic:(NSDictionary *)dict;
{
    if (self = [super init]) {
        self.requsetTimeout = 60000;
        self.downloadFileTimeout = 60000;
        self.uploadFileTimeout = 60000;
        if (dict[@"request"]) {
            self.requsetTimeout = [dict[@"request"] doubleValue];
        }
        if (dict[@"downloadFile"]) {
            self.downloadFileTimeout = [dict[@"downloadFile"] doubleValue];
        }
        if (dict[@"uploadFile"]) {
            self.uploadFileTimeout = [dict[@"uploadFile"] doubleValue];
        }
    }
    return self;
}

@end

@implementation WAConfig

- (id)initWithDic:(NSDictionary *)dict;
{
    if (self = [super init]) {
        _windowConfig = [[WAWindowConfig alloc] initWithDic:dict[@"window"]];
        NSMutableDictionary *pageDict = [NSMutableDictionary dictionary];
        NSArray *pages = dict[@"pages"];
        if ([pages isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in pages) {
                WAPageConfig *page = [[WAPageConfig alloc] initWithDic:dict];
                if (page.pageHash) {
                    pageDict[page.pageHash] = page;
                }
            }
        }
        _pages = [pageDict copy];
        _tabBarConfig = [[WATabBarConfig alloc] initWithDic:dict[@"tabBar"]];
        _isDebug = [dict[@"debug"] boolValue];
        _homeHash = dict[@"home"];
    }
    return self;
}

- (NSString *)getNavigationTitleByHash:(NSString *)hash
{
    if (!hash.length) {
        return nil;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig) {
        return pageConfig.navigationBarTitleText;
    }
    return self.windowConfig.navigationBarTitleText;
}

- (NSString *)getNavigationBackgroundColorStringByHash:(NSString *)hash
{
    if (!hash.length) {
        return nil;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig) {
        return pageConfig.navigationBarBackgroundColor;
    }
    return self.windowConfig.navigationBarBackgroundColor ?: @"#000000";
}

- (WANavigationBarTextStyle)getTitleColorStringByHash:(NSString *)hash
{
    if (!hash.length) {
        return WANavigationBarTextStyleWhite;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig) {
        return pageConfig.navigationBarTextStyle;
    }
    return self.windowConfig.navigationBarTextStyle;
}

- (NSString *)getBackgroundColorTopStringByHash:(NSString *)hash
{
    if (!hash.length) {
        return nil;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig && pageConfig.backgroundColorTop) {
        return pageConfig.backgroundColorTop;
    }
    return self.windowConfig.backgroundColorTop ?: @"#ffffff";
}

- (NSString *)getBackgroundColorBottomStringByHash:(NSString *)hash
{
    if (!hash.length) {
        return nil;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig && pageConfig.backgroundColorBottom) {
        return pageConfig.backgroundColorBottom;
    }
    return self.windowConfig.backgroundColorBottom ?: @"#ffffff";
}

- (NSString *)getBackgroundColorStringByHash:(NSString *)hash
{
    if (!hash.length) {
        return nil;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig && pageConfig.backgroundColor) {
        return pageConfig.backgroundColor;
    }
    return self.windowConfig.backgroundColor ?: @"#ffffff";
}

- (WANavigationStyle)getNavigationStyleByHash:(NSString *)hash
{
    if (!hash.length) {
        return WANavigationStyleDefault;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig) {
        return pageConfig.navigationStyle;
    }
    return self.windowConfig.navigationStyle;
}

- (WABackgroundTextStyle)getBackgroundTextStyleByHash:(NSString *)hash
{
    if (!hash.length) {
        return WABackgroundTextStyleDark;
    }
    WAPageConfig *pageConfig = [self getPageConfigByHash:hash];
    if (pageConfig) {
        return pageConfig.backgroundTextStyle;
    }
    return self.windowConfig.backgroundTextStyle;
}

- (BOOL)tabBarConfigContainItemOfHash:(NSString *)hash
{
    if (!_tabBarConfig.tabBarItems.count) {
        return NO;
    }
    for (WATabBarItemConfig *config in _tabBarConfig.tabBarItems) {
        if (kStringEqualToString(config.pageHash, hash)) {
            return YES;
        }
    }
    return NO;
}

- (WAPageConfig *)getPageConfigByHash:(NSString *)hash
{
    if (!hash) {
        return nil;
    }
    return self.pages[hash];
}


@end

