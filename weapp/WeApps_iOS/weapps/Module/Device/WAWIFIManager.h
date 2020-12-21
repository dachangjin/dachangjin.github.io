//
//  WAWIFIManager.h
//  weapps
//
//  Created by tommywwang on 2020/9/24.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WACallbackModel.h"

@class WebView;

typedef NS_ENUM(NSUInteger, WIFIError) {
    WIFIErrorNotInit = 12000,
    WIFIErrorSystemNotSupport = 12001,
    WIFIErrorPasswordErrorWIFI = 12002,
    WIFIErrorConnectionTimeout = 12003,
    WIFIErrorDuplicateRequest = 12004,
    WIFIErrorWifiNotTurnedOn = 12005,
    WIFIErrorGPSNotTurnedOn = 12006,
    WIFIErrorUserDenied = 12007,
    WIFIErrorInvalidSSID = 12008,
    WIFIErrorSystemConfigError = 12009,
    WIFIErrorSystempInteralError = 12010,
    WIFIErrorWeappInBackground = 12011,
    WIFIErrorWIFIConfigMayBeExpired = 12013
};

NS_ASSUME_NONNULL_BEGIN

@interface WAWifiInfo : NSObject

@property (nonatomic, copy) NSString * _Nullable ssid;

@property (nonatomic, copy) NSString * _Nullable bssid;

@property (nonatomic, copy) NSString * _Nullable password;

@end


@interface WAWIFIManager : WACallbackModel

/// 初始化 Wi-Fi 模块
/// @param completionHandler 完成回调
- (void)startWifiWithCompletionHandler:(void(^)(BOOL success,
                                                NSError *error))completionHandler;

/// 关闭 Wi-Fi 模块
/// @param completionHandler 完成回调
- (void)stopWifiWithCompletionHandler:(void(^)(BOOL success,
                                               NSError *error))completionHandler;

/// 设置 wifiList 中 AP 的相关信息。在 onGetWifiList 回调后调用
/// @param infos wifi细心
/// @param completionHandler 完成回调
- (void)setWifiListWithInfos:(NSArray <WAWifiInfo *>*)infos
           completionHandler:(void(^)(BOOL success,
                                      NSError *error))completionHandler;

/// 请求获取 Wi-Fi 列表。在 onGetWifiList 注册的回调中返回 wifiList 数据 。将跳转到系统的 Wi-Fi 界面
/// iOS 11.0 及 iOS 11.1 两个版本因系统问题，该方法失效。但在 iOS 11.2 中已修复。
/// @param completionHandler 完成回调
- (void)getWifiListWithCompletionHandler:(void(^)(BOOL success,
                                                  NSError *error))completionHandler;

/// 获取已连接中的 Wi-Fi 信息
/// @param completionHandler 完成回调
- (void)getConnectedWifiWithCompletionHandler:(void(^)(BOOL success,
                                                       NSDictionary *result,
                                                       NSError *error))completionHandler;

/// 连接 Wi-Fi。若已知 Wi-Fi 信息，可以直接利用该接口连接。仅 iOS 11 以上版本支持。
/// @param wifi wifi信息
/// @param completionHandler 完成回调
- (void)connectWifi:(WAWifiInfo *)wifi withCompletionHandler:(void(^)(BOOL success,
                                                                      NSError *error))completionHandler;

/// 注册wifi连接callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView onWifiConnectWithCallback:(NSString *)callback;

/// 移除wifi连接callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView offWifiConnectWithCallback:(NSString *)callback;

/// 注册获取wifi列表callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView onGetWifiListWithCallback:(NSString *)callback;

/// 移除获取wifi列表callback
/// @param webView 当前注册的webView
/// @param callback callback名
- (void)webView:(WebView *)webView offGetWifiListWithCallback:(NSString *)callback;

@end

NS_ASSUME_NONNULL_END
