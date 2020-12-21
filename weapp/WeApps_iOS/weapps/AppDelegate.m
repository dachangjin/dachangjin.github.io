//
//  AppDelegate.m
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AppDelegate.h"
#import "WXApi.h"
#import "WXApiManager.h"
#import "WXNetworkConfigManager.h"
#import "AppConfig.h"
#import "PathUtils.h"
#import "AppInfo.h"
#import "Weapps.h"
#import "WADebugInfo.h"
#import "WADebugViewController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self registerWXApi];
    [[Weapps sharedApps] initializeWithLaunchOptions:launchOptions];
#ifdef DEBUG
    [[WADebugInfo sharedInstance] show];
    [[WADebugInfo sharedInstance] setButtonClickBlock:^(__kindof UIControl * _Nonnull sender) {
        [[WADebugInfo sharedInstance] hide];
        WADebugViewController *VC = [[WADebugViewController alloc] init];
        VC.deallocBlock = ^{
            [[WADebugInfo sharedInstance] show];
        };
        
        UINavigationController *nav = (UINavigationController *)[[[UIApplication sharedApplication].windows firstObject] rootViewController];
        [nav pushViewController:VC animated:YES];
    }];
#endif
    return YES;
}


- (void)registerWXApi
{
    [WXApi registerApp:kWechatId
         universalLink:kWechatUL];
    /* Setup Network */
    [[WXNetworkConfigManager sharedManager] setup];
}






- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [WXApi handleOpenURL:url delegate:[WXApiManager sharedManager]];
}

- (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [WXApi handleOpenUniversalLink:userActivity delegate:[WXApiManager sharedManager]];

}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[Weapps sharedApps].deviceManager onReceiveMemoryWarning];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    [[Weapps sharedApps].VoIPManager onReceiveRemoteCallAPNs:userInfo];
}

@end
