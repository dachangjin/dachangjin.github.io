//
//  WAAppHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAAppHandler.h"
#import "AppInfo.h"
#import "NSData+Base64.h"
#import "JSONHelper.h"
#import "Weapps.h"
#import "UIColor+QMUI.h"

kSELString(getAppName)
kSELString(getAppNameSync)
kSELString(getAppId)
kSELString(getAppIdSync)
kSELString(getAppVersionCode)
kSELString(getAppVersionCodeSync)
kSELString(getAppLogo)
kSELString(getAppLogoSync)
kSELString(onAppShow)
kSELString(offAppShow)
kSELString(onAppHide)
kSELString(offAppHide)
kSELString(onPullDownRefresh)
kSELString(offPullDownRefresh)
kSELString(startPullDownRefresh)
kSELString(stopPullDownRefresh)
kSELString(getLaunchOptionsSync)
kSELString(setConfig)

kSELString(showNavigationBarLoading)
kSELString(hideNavigationBarLoading)
kSELString(setNavigationBarTitle)
kSELString(setNavigationBarColor)
kSELString(hideHomeButton)

kSELString(setBackgroundTextStyle)
kSELString(setBackgroundColor)

kSELString(showTabBarRedDot)
kSELString(hideTabBarRedDot)
kSELString(showTabBar)
kSELString(hideTabBar)
kSELString(setTabBarStyle)
kSELString(setTabBarItem)
kSELString(setTabBarBadge)
kSELString(removeTabBarBadge)

kSELString(getCurrentPageQuery)



@implementation WAAppHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            getAppName,
            getAppNameSync,
            getAppId,
            getAppIdSync,
            getAppVersionCode,
            getAppVersionCodeSync,
            getAppLogo,
            getAppLogoSync,
            onAppShow,
            offAppShow,
            onAppHide,
            offAppHide,
            onPullDownRefresh,
            offPullDownRefresh,
            startPullDownRefresh,
            stopPullDownRefresh,
            getLaunchOptionsSync,
            setConfig,
            
            showNavigationBarLoading,
            hideNavigationBarLoading,
            setNavigationBarTitle,
            setNavigationBarColor,
            hideHomeButton,
            
            setBackgroundTextStyle,
            setBackgroundColor,
            
            showTabBarRedDot,
            hideTabBarRedDot,
            showTabBar,
            hideTabBar,
            setTabBarStyle,
            setTabBarItem,
            setTabBarBadge,
            removeTabBarBadge,
            
            getCurrentPageQuery
            
        ];
    }
    return methods;
}

JS_API(getLaunchOptionsSync){
    return [JSONHelper exchengeDictionaryToString:[Weapps sharedApps].launchOptions];
}

JS_API(getAppName){
    kSuccessWithDic(@{
        @"appName": [AppInfo appName]
                    })
    return @"";
}

JS_API(getAppNameSync){
    return [AppInfo appName];
}

JS_API(getAppId){
    kSuccessWithDic(@{
        @"appId": [AppInfo appId]
                    })
    return @"";
}

JS_API(getAppIdSync){
    return [AppInfo appId];;
}

JS_API(getAppVersionCode){
    kSuccessWithDic(@{
        @"version": [AppInfo appVersion]
                    })
    return @"";
}

JS_API(getAppVersionCodeSync){
    return [AppInfo appVersion];
}


JS_API(getAppLogo){
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    
    //获取app中所有icon名字数组
    NSArray *iconsArr = infoDict[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
    //取最后一个icon的名字
    NSString *iconName = [iconsArr lastObject];
    
    UIImage *image = [UIImage imageNamed:iconName];
    
    if (image) {
        kSuccessWithDic((@{
        @"appLogo": [NSString stringWithFormat:@"data:image/png;base64,%@",[UIImagePNGRepresentation(image) base64String]]
                     }))
    } else {
        kFailWithError(getAppLogo, -1, @"获取appLogo失败")
    }
    
    return @"";
}

JS_API(getAppLogoSync){
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    
    //获取app中所有icon名字数组
    NSArray *iconsArr = infoDict[@"CFBundleIcons"][@"CFBundlePrimaryIcon"][@"CFBundleIconFiles"];
    //取最后一个icon的名字
    NSString *iconName = [iconsArr lastObject];
    
    UIImage *image = [UIImage imageNamed:iconName];
    
    if (image) {
        kSuccessWithDic((@{
        @"appLogo": [NSString stringWithFormat:@"data:image/png;base64,%@",[UIImagePNGRepresentation(image) base64String]]
                     }))
    } else {
        kFailWithError(getAppLogoSync, -1, @"获取appLogo失败")
    }
    
    return [NSString stringWithFormat:@"data:image/png;base64,%@",[UIImagePNGRepresentation(image) base64String]];
}


JS_API(onAppShow){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(onAppShow, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(addAppShowCallback:)]) {
        [event.webView.webHost addAppShowCallback:event.callbacak];
        WALOG(@"onAppShow success")
    } else {
        WALOG(@"onAppShow fail")
    }
    return @"";
}

JS_API(offAppShow){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(offAppShow, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(removeAppShowCallback:)]) {
        [event.webView.webHost removeAppShowCallback:event.callbacak];
        WALOG(@"offAppShow success")
    } else {
        WALOG(@"offAppShow fail")
    }
    return @"";
}

JS_API(onAppHide){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(onAppHide, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(addAppHideCallback:)]) {
        [event.webView.webHost addAppHideCallback:event.callbacak];
        WALOG(@"onAppHide success")
    } else {
        WALOG(@"onAppHide fail")
    }
    return @"";
}

JS_API(offAppHide){
    
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(offAppHide, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(removeAppHideCallback:)]) {
        [event.webView.webHost removeAppHideCallback:event.callbacak];
        WALOG(@"offAppHide success")
    } else {
        WALOG(@"offAppHide fail")
    }
    return @"";
}

JS_API(onPullDownRefresh){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(onPullDownRefresh, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(addPullDownRefreshCallback:)]) {
        [event.webView.webHost addPullDownRefreshCallback:event.callbacak];
        WALOG(@"onPullDownRefresh success")
    } else {
        WALOG(@"onPullDownRefresh fail")
    }
    return @"";
}

JS_API(offPullDownRefresh){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(offPullDownRefresh, -1, @"callback invalid")
    }
    if ([event.webView.webHost respondsToSelector:@selector(removePullDownRefreshCallback:)]) {
        [event.webView.webHost removePullDownRefreshCallback:event.callbacak];
        WALOG(@"offPullDownRefresh success")
    } else {
        WALOG(@"offPullDownRefresh fail")
    }
    return @"";
}

JS_API(startPullDownRefresh){
    if ([event.webView.webHost respondsToSelector:@selector(startPullDownRefresh)]) {
        [event.webView.webHost startPullDownRefresh];
        WALOG(@"startPullDownRefresh success")
    } else {
        WALOG(@"startPullDownRefresh fail")
    }
    return @"";
}

JS_API(stopPullDownRefresh){
    if ([event.webView.webHost respondsToSelector:@selector(stopPullDownRefresh)]) {
        [event.webView.webHost stopPullDownRefresh];
        WALOG(@"stopPullDownRefresh success")
    } else {
        WALOG(@"stopPullDownRefresh fail")
    }
    return @"";
}

JS_API(setConfig){
    kBeginCheck
    kCheck([NSDictionary class], @"window", YES)
    kCheck([NSArray class], @"pageConfig", YES)
    kCheck([NSDictionary class], @"tabBar", YES)
    kCheck([NSDictionary class], @"networkTimeout", YES)
    kEndCheck([NSNumber class], @"debug", YES)
    [[Weapps sharedApps] setConfigWithDict:event.args];
    return @"";
}

JS_API(showNavigationBarLoading){
    if ([event.webView.webHost respondsToSelector:@selector(showNavigationBarLoadingWithSuccess:fail:)]) {
        [event.webView.webHost showNavigationBarLoadingWithSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(showNavigationBarLoading, -1, @"not support")
    }
    return @"";
}

JS_API(hideNavigationBarLoading){
    if ([event.webView.webHost respondsToSelector:@selector(hideNavigationBarLoadingWithSuccess:fail:)]) {
        [event.webView.webHost hideNavigationBarLoadingWithSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(hideNavigationBarLoading, -1, @"not support")
    }
    return @"";
}

JS_API(setNavigationBarTitle){
    kBeginCheck
    kEndCheck([NSString class], @"title", NO)
    if ([event.webView.webHost respondsToSelector:@selector(setNavigationBarTitle:withSuccess:fail:)]) {
        [event.webView.webHost setNavigationBarTitle:event.args[@"title"] withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setNavigationBarTitle, -1, @"not support")
    }
    return @"";
}


JS_API(setNavigationBarColor){
    kBeginCheck
    kCheck([NSString class], @"frontColor", NO)
    kCheck([NSDictionary class], @"animation", NO)
    kEndCheck([NSString class], @"backgroundColor", NO)
    NSString *frontColorString = event.args[@"frontColor"];
    NSString *bgColorString = event.args[@"backgroundColor"];
    UIColor *frontColor = [UIColor qmui_rgbaColorWithHexString:frontColorString];
    if (!frontColor) {
        kFailWithErrorWithReturn(setNavigationBarColor, -1, @"frontColor: color format not support")
    }
    UIColor *bgColor = [UIColor qmui_rgbaColorWithHexString:[bgColorString qmui_trim]];
    if (!bgColor) {
        kFailWithErrorWithReturn(setNavigationBarColor, -1, @"backgroundColor: color format not support")
    }
    CGFloat duration = [event.args[@"animation"][@"duration"] floatValue] ?: 0;
    NSString *timingFunc = event.args[@"animation"][@"timingFunc"];
    if ([event.webView.webHost respondsToSelector:@selector(setNavigationBarBackgroundColor:frontColor:animationDuration:timingFunc:withSuccess:fail:)]) {
        [event.webView.webHost setNavigationBarBackgroundColor:bgColor
                                                    frontColor:frontColor
                                             animationDuration:duration
                                                    timingFunc:timingFunc
                                                   withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setNavigationBarColor, -1, @"not support")
    }
    return @"";
}

JS_API(hideHomeButton){
    if ([event.webView.webHost respondsToSelector:@selector(hideHomeButtonWithSuccess:fail:)]) {
        [event.webView.webHost hideHomeButtonWithSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(hideHomeButton, -1, @"not support")
    }
    return @"";
}

JS_API(setBackgroundTextStyle){
    kBeginCheck
    kEndCheck([NSString class], @"textStyle", NO)
    if ([event.webView.webHost respondsToSelector:@selector(setBackgroundTextStyle:withSuccess:fail:)]) {
        [event.webView.webHost setBackgroundTextStyle:event.args[@"textStyle"] withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setBackgroundTextStyle, -1, @"not support")
    }
    return @"";
}

JS_API(setBackgroundColor){
    kBeginCheck
    kCheck([NSString class], @"backgroundColor", YES)
    kCheck([NSString class], @"backgroundColorTop", YES)
    kEndCheck([NSString class], @"backgroundColorBottom", YES)
    NSString *bgColorTopString = event.args[@"backgroundColorTop"];
    NSString *bgColorString = event.args[@"backgroundColor"];
    NSString *bgColorBottomString = event.args[@"backgroundColorBottom"];
    UIColor *bgColor = [UIColor qmui_rgbaColorWithHexString:bgColorString];
    if (!bgColor) {
        kFailWithErrorWithReturn(setNavigationBarColor, -1, @"backgroundColor: color format not support")
    }
    UIColor *bgColorTop = [UIColor qmui_rgbaColorWithHexString:bgColorTopString];
    if (!bgColor) {
        kFailWithErrorWithReturn(setNavigationBarColor, -1, @"backgroundColor: color format not support")
    }
    UIColor *bgColorBottom = [UIColor qmui_rgbaColorWithHexString:bgColorBottomString];
    if (!bgColor) {
        kFailWithErrorWithReturn(setNavigationBarColor, -1, @"backgroundColor: color format not support")
    }
    if ([event.webView.webHost respondsToSelector:@selector(setBackgroundColor:backgroundColorTop:backgroundColorBottom:withSuccess:fail:)]) {
        [event.webView.webHost setBackgroundColor:bgColor
                               backgroundColorTop:bgColorTop
                            backgroundColorBottom:bgColorBottom
                                      withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setBackgroundColor, -1, @"not support")
    }
    return @"";
}

JS_API(showTabBarRedDot){
    kBeginCheck
    kEndCheck([NSNumber class], @"index", NO)
    NSUInteger index = [event.args[@"index"] unsignedIntegerValue];
    if ([event.webView.webHost respondsToSelector:@selector(showTabBarRedDotAtIndex:withSuccess:fail:)]) {
        [event.webView.webHost showTabBarRedDotAtIndex:index withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error);
        }];
    } else {
        kFailWithError(showTabBarRedDot, -1, @"not support")
    }
    return @"";
}

JS_API(hideTabBarRedDot){
    kBeginCheck
    kEndCheck([NSNumber class], @"index", NO)
    NSUInteger index = [event.args[@"index"] unsignedIntegerValue];
    if ([event.webView.webHost respondsToSelector:@selector(hideTabBarRedDotAtIndex:withSuccess:fail:)]) {
        [event.webView.webHost hideTabBarRedDotAtIndex:index withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error);
        }];
    } else {
        kFailWithError(hideTabBarRedDot, -1, @"not support")
    }
    return @"";
}


JS_API(showTabBar){
    kBeginCheck
    kEndChecIsBoonlean(@"animation", YES)
    BOOL animation = NO;
    animation = [event.args[@"animation"] boolValue];
    if ([event.webView.webHost respondsToSelector:@selector(showTabBarWithAnimation:withSuccess:fail:)]) {
        [event.webView.webHost showTabBarWithAnimation:animation
                                          withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(showTabBar, -1, @"not support")
    }
    return @"";
}

JS_API(hideTabBar){
    kBeginCheck
    kEndChecIsBoonlean(@"animation", YES)
    BOOL animation = NO;
    animation = [event.args[@"animation"] boolValue];
    if ([event.webView.webHost respondsToSelector:@selector(hideTabBarWithAnimation:withSuccess:fail:)]) {
        [event.webView.webHost hideTabBarWithAnimation:animation
                                          withSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(showTabBar, -1, @"not support")
    }
    return @"";
}

JS_API(setTabBarStyle){
    kBeginCheck
    kCheck([NSString class], @"color", YES)
    kCheck([NSString class], @"selectedColor", YES)
    kCheck([NSString class], @"backgroundColor", YES)
    kEndCheck([NSString class], @"borderStyle", YES)
    
    NSString *colorString = event.args[@"color"];
    NSString *selectedColorString = event.args[@"selectedColor"];
    NSString *backgroundColorString = event.args[@"backgroundColor"];
    NSString *borderStyle = event.args[@"borderStyle"];

    UIColor *color = [UIColor qmui_rgbaColorWithHexString:colorString];
    UIColor *selectedColor = [UIColor qmui_rgbaColorWithHexString:selectedColorString];
    UIColor *bgColor = [UIColor qmui_rgbaColorWithHexString:backgroundColorString];
    
    if ([event.webView.webHost respondsToSelector:@selector(setTabBarStyleWithColor:selectedColor:backgroundColor:borderStyle:success:fail:)]) {
        [event.webView.webHost setTabBarStyleWithColor:color
                                         selectedColor:selectedColor
                                       backgroundColor:bgColor
                                           borderStyle:borderStyle
                                               success:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setTabBarStyle, -1, @"not support")
    }
    return @"";
}

JS_API(setTabBarItem){
    kBeginCheck
    kCheck([NSNumber class], @"index", NO)
    kCheck([NSString class], @"text", YES)
    kCheck([NSString class], @"iconPath", YES)
    kEndCheck([NSString class], @"selectedIconPath", YES)
    
    NSString *text = event.args[@"text"];
    NSUInteger index = [event.args[@"index"] unsignedIntegerValue];
    NSString *iconPath = event.args[@"iconPath"];
    NSString *selectedIconPath = event.args[@"selectedIconPath"];
    if ([event.webView.webHost respondsToSelector:@selector(setTabBarItemWithText:iconPath:selectedIconPath:atIndex:success:fail:)]) {
        [event.webView.webHost setTabBarItemWithText:text
                                            iconPath:iconPath
                                    selectedIconPath:selectedIconPath
                                             atIndex:index
                                             success:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setTabBarItem, -1, @"not support")
    }
    return @"";
}

JS_API(setTabBarBadge){
    kBeginCheck
    kCheck([NSNumber class], @"index", NO)
    kEndCheck([NSString class], @"text", NO)
    NSUInteger index = [event.args[@"index"] unsignedIntegerValue];
    NSString *text = event.args[@"text"];
    if ([event.webView.webHost respondsToSelector:@selector(setTabBarBadge:atIndex:success:fail:)]) {
        [event.webView.webHost setTabBarBadge:text
                                      atIndex:index
                                      success:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(setTabBarBadge, -1, @"not support")
    }
    return @"";
}

JS_API(removeTabBarBadge){
    kBeginCheck
    kEndCheck([NSNumber class], @"index", NO)
    NSUInteger index = [event.args[@"index"] unsignedIntegerValue];
    if ([event.webView.webHost respondsToSelector:@selector(removeTabBarBadgeAtIndex:success:fail:)]) {
        [event.webView.webHost removeTabBarBadgeAtIndex:index success:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    } else {
        kFailWithError(removeTabBarBadge, -1, @"not support")
    }
    return @"";
}

JS_API(getCurrentPageQuery){
    if ([event.webView.webHost respondsToSelector:@selector(getCurrentPageQueryWithSuccess:fail:)]) {
        [event.webView.webHost getCurrentPageQueryWithSuccess:^(NSDictionary * _Nullable result) {
            kSuccessWithDic(result)
        } fail:^(NSError * _Nullable error) {
            kFailWithErr(error)
        }];
    }
    return @"";
}


@end
