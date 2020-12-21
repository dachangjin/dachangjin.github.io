//
//  WAWIFIManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/24.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAWIFIManager.h"
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation WAWifiInfo

@end

@interface NEHotspotNetwork (Object)

- (NSDictionary *)toDict;

@end

@implementation NEHotspotNetwork (Object)

- (NSDictionary *)toDict
{
    return @{
        @"SSID"             : self.SSID ?: @"",
        @"BSSID"            : self.BSSID ?: @"",
        @"secure"           : @(self.secure),
        @"signalStrength"   : @(self.signalStrength),
        @"autoJoined"       : @(self.autoJoined),
        @"justJoined"       : @(self.justJoined)
    };
}

@end



@interface WAWIFIManager ()

@property (nonatomic, strong) NSMutableDictionary *onGetWifiListCallbackDict;
@property (nonatomic, strong) NSMutableDictionary *onWifiConnectedCallbackDict;
@property (nonatomic, assign) bool isInit;
@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, strong) NEHotspotHelperCommand *cmd;
@end

@implementation WAWIFIManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _onGetWifiListCallbackDict = [NSMutableDictionary dictionary];
        _onWifiConnectedCallbackDict = [NSMutableDictionary dictionary];
        _condition = [[NSCondition alloc] init];
    }
    return self;
}


/// 初始化 Wi-Fi 模块
/// @param completionHandler 完成回调
- (void)startWifiWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (_isInit) {
        if (completionHandler) {
            completionHandler(YES, nil);
        }
        return;;
    }
    NSMutableDictionary* options = [[NSMutableDictionary alloc] init];
    [options setObject:@"HotspotHelper" forKey: kNEHotspotHelperOptionDisplayName];
    dispatch_queue_t queue = dispatch_queue_create("HotspotHelper", NULL);
    _isInit = [NEHotspotHelper registerWithOptions: options
                                             queue: queue
                                           handler:^(NEHotspotHelperCommand * _Nonnull cmd) {
        //获取系统wifi列表，执行onGetWifiList回调
        if (cmd.commandType == kNEHotspotHelperCommandTypeFilterScanList) {
            NSMutableArray *wifiList = [NSMutableArray array];
            for (NEHotspotNetwork* network  in cmd.networkList) {
                [wifiList addObject:[network toDict]];
            }
            [self doCallbackInCallbackDict:self.onGetWifiListCallbackDict
                                 andResult:@{@"wifiList": wifiList}];
            [self.condition lock];
            self.cmd = cmd;
            //挂起等待setWifiList调用
            [self.condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:3.0]];
            [self.condition unlock];
        }
    }];
    
    if (completionHandler) {
        if (_isInit) {
            completionHandler(YES, nil);
        } else {
            //未配置appId相关
            completionHandler(NO, [NSError errorWithDomain:@"startWifi"
                                                      code:WIFIErrorSystemNotSupport
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey : @"system not support"
                                                  }]);
        }
    }
}

/// 关闭 Wi-Fi 模块
/// @param completionHandler 完成回调
- (void)stopWifiWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

/// 设置 wifiList 中 AP 的相关信息。在 onGetWifiList 回调后调用
/// @param infos wifi细心
/// @param completionHandler 完成回调
- (void)setWifiListWithInfos:(NSArray <WAWifiInfo *>*)infos
           completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (!_isInit) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"setWifiList"
                                                      code:WIFIErrorNotInit
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: @"not init"
                                                  }]);
        }
        return;
    }
    [self.condition lock];
    if (!self.cmd) {
        if (completionHandler) {
            completionHandler(YES, nil);
        }
        [self.condition signal];
        [self.condition unlock];
        return;
    }
    if (completionHandler) {
        completionHandler(YES, nil);
    }
    [self.condition lock];
    for (WAWifiInfo *info in infos) {
        for (NEHotspotNetwork *network in self.cmd.networkList) {
            if (kStringEqualToString(network.SSID, info.ssid)) {
                [network setPassword:info.password];
                [network setConfidence:kNEHotspotHelperConfidenceHigh];
                NEHotspotHelperResponse *response = [self.cmd createResponse:kNEHotspotHelperResultSuccess];
                [response setNetworkList:@[network]];
                [response setNetwork:network];
                [response deliver];
            }
        }
    }
    [self.condition signal];
    [self.condition unlock];
}

/// 请求获取 Wi-Fi 列表。在 onGetWifiList 注册的回调中返回 wifiList 数据 。将跳转到系统的 Wi-Fi 界面
/// iOS 11.0 及 iOS 11.1 两个版本因系统问题，该方法失效。但在 iOS 11.2 中已修复。
/// @param completionHandler 完成回调
- (void)getWifiListWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (!_isInit) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"getWifiList"
                                                      code:WIFIErrorNotInit
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: @"not init"
                                                  }]);
        }
        return;
    }
    if (completionHandler) {
        completionHandler(YES, nil);
    }
    //TODO: 转跳到设置界面
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"prefs:root=WIFI"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=WIFI"]];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-Prefs:root=WIFI"]];
    }
}

/// 获取已连接中的 Wi-Fi 信息
/// @param completionHandler 完成回调
- (void)getConnectedWifiWithCompletionHandler:(void(^)(BOOL success,
                                                       NSDictionary *result,
                                                       NSError *error))completionHandler
{
    if (!_isInit) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"getConnectedWifi"
                                                           code:WIFIErrorNotInit
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"not init"
                                                       }]);
        }
        return;
    }
    if (@available(iOS 14.0, *)) {
        [NEHotspotNetwork fetchCurrentWithCompletionHandler:^(NEHotspotNetwork * _Nullable currentNetwork) {
            if (completionHandler) {
                if (currentNetwork) {
                    completionHandler(YES, @{
                        @"wifi": [currentNetwork toDict]
                                           }, nil);
                } else {
                    completionHandler(NO, nil, [NSError errorWithDomain:@"getConnectedWifi"
                                                                   code:WIFIErrorSystemNotSupport
                                                               userInfo:@{
                                                                   NSLocalizedDescriptionKey: @"system not support"
                                                               }]);
                }
            }
        }];
    } else {
        NSArray *interfaces = [NEHotspotHelper supportedNetworkInterfaces];
        if (completionHandler) {
            if ([interfaces count] != 0) {
                completionHandler(YES, @{
                    @"wifi": [((NEHotspotNetwork *)[interfaces firstObject]) toDict]
                                       }, nil);
            } else {
                completionHandler(NO, nil, [NSError errorWithDomain:@"getConnectedWifi"
                                                               code:WIFIErrorSystemNotSupport
                                                           userInfo:@{
                                                               NSLocalizedDescriptionKey: @"system not support"
                                                           }]);
            }
        }
    }
}

/// 连接 Wi-Fi。若已知 Wi-Fi 信息，可以直接利用该接口连接。仅 iOS 11 以上版本支持。
/// @param wifi wifi信息
/// @param completionHandler 完成回调
- (void)connectWifi:(WAWifiInfo *)wifi withCompletionHandler:(void(^)(BOOL success,
                                                                      NSError *error))completionHandler
{
    if (!_isInit) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"connectWifi"
                                                           code:WIFIErrorNotInit
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: @"not init"
                                                       }]);
        }
        return;
    }
    if (@available(iOS 11.0, *)) {
        NEHotspotConfiguration *config = [[NEHotspotConfiguration alloc] initWithSSID:wifi.ssid
                                                                           passphrase:wifi.password
                                                                                isWEP:NO];
        [[NEHotspotConfigurationManager sharedManager] applyConfiguration:config
                                                        completionHandler:^(NSError * _Nullable error) {
            if (completionHandler) {
                if (!error) {
                    completionHandler(YES, nil);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //连接成功，获取连接wifi信息，并回调监听callback
                        [self getConnectedWifiWithCompletionHandler:^(BOOL success,
                                                                      NSDictionary * _Nonnull result,
                                                                      NSError * _Nonnull error) {
                            [self doCallbackInCallbackDict:self.onWifiConnectedCallbackDict
                                                 andResult:result];
                        }];
                    });
                    return;
                }
                NSInteger errorCode = WIFIErrorWifiNotTurnedOn;
                NSString *errorMsg = @"";
                switch (error.code) {
                    case NEHotspotConfigurationErrorInvalidWPAPassphrase:
                    case NEHotspotConfigurationErrorInvalidWEPPassphrase:
                        errorCode = WIFIErrorPasswordErrorWIFI;
                        errorMsg = @"password error Wi-Fi";
                        break;
                    case NEHotspotConfigurationErrorAlreadyAssociated:
                        errorCode = WIFIErrorDuplicateRequest;
                        errorMsg = @"duplicate request";
                        break;
                    case NEHotspotConfigurationErrorUserDenied:
                        errorCode = WIFIErrorUserDenied;
                        errorMsg = @"user denied";
                        break;
                    case NEHotspotConfigurationErrorInvalidSSID:
                    case NEHotspotConfigurationErrorInvalid:
                    case NEHotspotConfigurationErrorInvalidSSIDPrefix:
                        errorCode = WIFIErrorInvalidSSID;
                        errorMsg = @"invalid SSID";
                        break;
                    case NEHotspotConfigurationErrorSystemConfiguration:
                        errorCode = WIFIErrorSystemConfigError;
                        errorMsg = @"system config err";
                        break;
                    case NEHotspotConfigurationErrorUnknown:
                    case NEHotspotConfigurationErrorInternal:
                    case NEHotspotConfigurationErrorPending:
                    case NEHotspotConfigurationErrorJoinOnceNotSupported:
                    case NEHotspotConfigurationErrorInvalidHS20DomainName:
                    case NEHotspotConfigurationErrorInvalidHS20Settings:
                    case NEHotspotConfigurationErrorInvalidEAPSettings:
                        errorCode = WIFIErrorSystempInteralError;
                        errorMsg = error.localizedDescription;
                        break;
                    case NEHotspotConfigurationErrorApplicationIsNotInForeground:
                        errorCode = WIFIErrorWeappInBackground;
                        errorMsg = @"weapp in background";
                    default:
                        break;
                }
                completionHandler(NO, [NSError errorWithDomain:@"connectWifi" code:errorCode
                                                       userInfo:@{
                                                           NSLocalizedDescriptionKey: errorMsg
                                                       }]);
            }
        }];
    } else {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"connectWifi"
                                                      code:WIFIErrorSystemNotSupport
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: @"system not support"
                                                  }]);
        }
    }
}

/// 注册wifi连接callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView onWifiConnectWithCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.onWifiConnectedCallbackDict callback:callback];
}

/// 移除wifi连接callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView offWifiConnectWithCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.onWifiConnectedCallbackDict callback:callback];
}

/// 注册获取wifi列表callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView onGetWifiListWithCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.onGetWifiListCallbackDict callback:callback];
}

/// 移除获取wifi列表callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView offGetWifiListWithCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.onGetWifiListCallbackDict callback:callback];
}


@end
