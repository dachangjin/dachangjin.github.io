//
//  WANetworkManager.h
//  weapps
//
//  Created by tommywwang on 2020/7/6.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebView.h"
#import "AFNetworkReachabilityManager.h"

@class Weapps;

NS_ASSUME_NONNULL_BEGIN

@protocol WeappsReachabilityProtocol <NSObject>

- (void)weappsReachabilityStatusDidChange:(AFNetworkReachabilityStatus)status;

@end

//专门负责webView网络相关，以及监听相关。耦合较高

/// webView网络请求类
@interface WAWebViewNetworkManager : NSObject

- (id)initWithApp:(Weapps *)app;


/// 创建dataTask
/// @param request request
/// @param responseType 响应的数据类型
/// @param webView 当前请求webView，会被弱引用
/// @param completionHandler 请求完成回调。result的key包括data、statusCode、header、cookies
- (NSNumber *)dataTaskWithRequest:(NSURLRequest *)request
                     responseType:(NSString *)responseType
                          webView:(WebView *)webView
                completionHandler:(void (^)(BOOL success,
                                            NSDictionary *_Nullable result,
                                            NSError * _Nullable error))completionHandler;


/// 创建downloadTask
/// @param request request
/// @param webView 当前请求webView
/// @param completionHandler  下载完成回调
- (NSNumber *)downloadTaskWithRequest:(NSURLRequest *)request
                                 path:(NSString *)path
                              webView:(WebView *)webView
                    completionHandler:(void (^)(BOOL success,
                                                NSDictionary *_Nullable result,
                                                NSError * _Nullable error))completionHandler;


/// 创建uploadTask
/// @param request request
/// @param URL 本地文件url路径
/// @param webView 当前请求webView，会被弱引用
/// @param completionHandler 上传完成回调
- (NSNumber *)uploadTaskWithRequest:(NSURLRequest *)request
                               from:(NSURL *)URL
                            webView:(WebView *)webView
                  completionHandler:(void (^)(BOOL success,
                                              NSDictionary *_Nullable result,
                                              NSError * _Nullable error))completionHandler;

/// 创建uploadTask
/// @param request request
/// @param fromData 上传的文件
/// @param webView 当前请求webView，会被弱引用
/// @param completionHandler 上传完成回调
- (NSNumber *)uploadTaskWithRequest:(NSURLRequest *)request
                           fromData:(NSData *)fromData
                            webView:(WebView *)webView
                  completionHandler:(void (^)(BOOL success,
                                              NSDictionary *_Nullable result,
                                              NSError * _Nullable error))completionHandler;

/// 终止请求
/// @param identifier task标识
/// @param completionHandler 完成回调
- (void)abortDataTaskWithIdentifier:(NSNumber *)identifier
                  completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;

/// 终止下载任务
/// @param identifier task标识
/// @param completionHandler 完成回调
- (void)abortDownloadTaskWithIdentifier:(NSNumber *)identifier
                      completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;

/// 中指上传
/// @param identifier task标识
/// @param completionHandler 完成回调
- (void)abortUploadTaskWithIdentifier:(NSNumber *)identifier
                    completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completionHandler;


/// 添加webView监听RequestHeadersReceived回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
onRequestHeadersReceived:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;

/// 删除webView监听RequestHeadersReceived回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
offRequestHeadersReceived:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;;

/// 添加webView监听DownloadTaskProgress回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
onDownloadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;

/// 删除webView监听DownloadTaskProgress回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
offDownloadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;

/// 添加webView监听UploadTaskProgress回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
onUploadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;

/// 删除webView监听UploadTaskProgress回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
/// @param identifier task对应identifier
- (void)webView:(WebView *)webView
offUploadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier;

/// 添加网络变化监听者
/// @param listener 监听者
- (void)addReachabilityStatusChangeListener:(id <WeappsReachabilityProtocol>)listener;

/// 移除网络变化监听者
/// @param listener 监听者
- (void)removeReachabilityStatusChangeListener:(id <WeappsReachabilityProtocol>)listener;


@end

NS_ASSUME_NONNULL_END
