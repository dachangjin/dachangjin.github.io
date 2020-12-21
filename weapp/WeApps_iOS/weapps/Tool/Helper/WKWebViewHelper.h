//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebViewHelper : NSObject

///// WebView调用回调
///// @param result 结果：success ｜fail
///// @param resultData 回调结果
///// @param message WKScriptMessage
///// @param callback 回调函数
//+ (void)callbackWithResult:(NSString *)result resultData:(NSDictionary *)resultData message:(WKScriptMessage *)message callback:(NSString *)callback;



/// webView成功回调
/// @param resultData 回调结果
/// @param webView webView
/// @param callback 回调函数
+ (void)successWithResultData:(nullable NSDictionary *)resultData
                      webView:(nonnull WKWebView *)webView
                     callback:(nonnull NSString *)callback;


/// webView失败回调
/// @param error 错误信息
/// @param webView webView
/// @param callback 回调函数
+ (void)failWithError:(nullable NSError *)error
              webView:(nonnull WKWebView *)webView
             callback:(nonnull NSString *)callback;


/// webView开始加载
/// @param webView webView
+ (void)webViewDidStartLoading:(WKWebView *)webView;


/// webView完成加载
/// @param webView webView
+ (void)webViewDidFinishLoading:(WKWebView *)webView;

+ (void)runScript:(NSString *)script inWebView:(WKWebView *)webView;


/// 根据位置找到webView中的子scrollView
+ (UIScrollView *)findContainerInWebView:(WKWebView *)webView
                              withParams:(NSDictionary *)params;
@end

NS_ASSUME_NONNULL_END
