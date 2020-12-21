//
//  WAWIFIHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/24.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAWIFIHandler.h"
#import "Weapps.h"

kSELString(startWifi)
kSELString(stopWifi)
kSELString(setWifiList)
kSELString(onWifiConnected)
kSELString(offWifiConnected)
kSELString(onGetWifiList)
kSELString(offGetWifiList)
kSELString(getWifiList)
kSELString(getConnectedWifi)
kSELString(connectWifi)

@implementation WAWIFIHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            startWifi,
            stopWifi,
            setWifiList,
            onWifiConnected,
            offWifiConnected,
            onGetWifiList,
            offGetWifiList,
            getWifiList,
            getConnectedWifi,
            connectWifi
        ];
    }
    return methods;
}

JS_API(startWifi){
    [[Weapps sharedApps].WIFIManager startWifiWithCompletionHandler:^(BOOL success,
                                                                      NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopWifi){
    [[Weapps sharedApps].WIFIManager stopWifiWithCompletionHandler:^(BOOL success,
                                                                     NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setWifiList){
    kBeginCheck
    kEndCheck([NSArray class], @"wifiList", NO)
    NSArray *list = event.args[@"wifiList"];
    
    NSMutableArray *wifiInfos = [NSMutableArray array];
    for (NSDictionary *wifi in list) {
        if (![wifi isKindOfClass:[NSDictionary class]]) {
            NSString *info = [NSString stringWithFormat:@"parameter error: paremeter.wifiList.object should be object instead of %@",
                              [self jsTypeOfObject:wifi]];
            kFailWithErrorWithReturn(@"setWifiList", 01, info)
        }
        WAWifiInfo *wifiInfo = [[WAWifiInfo alloc] init];
        wifiInfo.ssid = wifi[@"SSID"];
        wifiInfo.bssid = wifi[@"BSSID"];
        wifiInfo.password = wifi[@"password"];
        [wifiInfos addObject:wifiInfo];
    }
    [[Weapps sharedApps].WIFIManager setWifiListWithInfos:wifiInfos
                                        completionHandler:^(BOOL success,
                                                            NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onWifiConnected){
    [[Weapps sharedApps].WIFIManager webView:event.webView
                   onWifiConnectWithCallback:event.callbacak];
    return @"";
}

JS_API(offWifiConnected){
    [[Weapps sharedApps].WIFIManager webView:event.webView
                  offWifiConnectWithCallback:event.callbacak];
    return @"";
}

JS_API(onGetWifiList){
    [[Weapps sharedApps].WIFIManager webView:event.webView
                   onGetWifiListWithCallback:event.callbacak];
    return @"";
}

JS_API(offGetWifiList){
    [[Weapps sharedApps].WIFIManager webView:event.webView
                  offGetWifiListWithCallback:event.callbacak];
    return @"";
}

JS_API(getWifiList){
    [[Weapps sharedApps].WIFIManager getWifiListWithCompletionHandler:^(BOOL success,
                                                                        NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(getConnectedWifi){
    [[Weapps sharedApps].WIFIManager getConnectedWifiWithCompletionHandler:^(BOOL success,
                                                                             NSDictionary * _Nonnull result,
                                                                             NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(connectWifi){

    kBeginCheck
    kCheck([NSString class], @"SSID", NO)
    kCheck([NSString class], @"BSSID", YES)
    kEndCheck([NSString class], @"password", NO)
    
    WAWifiInfo *info = [[WAWifiInfo alloc] init];
    info.ssid = event.args[@"SSID"];
    info.bssid = event.args[@"BSSID"];
    info.password = event.args[@"password"];
    
    [[Weapps sharedApps].WIFIManager connectWifi:info
                           withCompletionHandler:^(BOOL success,
                                                   NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}
@end
