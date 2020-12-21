//
//  WKWebViewUIDelegate.m
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WKWebViewUIDelegate.h"
#import "JSONHelper.h"
#import "WKWebViewCallHandlerFactory.h"
#import "WKWebViewHelper.h"

@implementation WKWebViewUIDelegate

- (void)webView:(WKWebView *)webView
runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt
    defaultText:(nullable NSString *)defaultText
initiatedByFrame:(WKFrameInfo *)frame
completionHandler:(void (^)(NSString * _Nullable result))completionHandler
{
    NSString *selectorStr = prompt;
    if (!selectorStr) {
        return;
    }
    NSDictionary *params = [JSONHelper exchangeStringToDictionary:defaultText];
    id callback = params[@"callback"];
    id args = params;
    if (params[@"data"]) {
        args = params[@"data"];
    }
    JSAsyncEvent *event = [[JSAsyncEvent alloc] init];
    event.funcName = selectorStr;
    event.args = args;
    event.webView = (WebView *)webView;
    if ([callback isKindOfClass:[NSDictionary class]]) {
        NSDictionary *callbackDic = callback;
        NSString *start = callbackDic[@"start"];
        NSString *progress = callbackDic[@"progress"];
        NSString *success = callbackDic[@"success"];
        NSString *fail = callbackDic[@"fail"];
        if (start.length) {
            event.start = ^{
            };
        }
        if (progress.length) {
            event.progress = ^(int progress) {
                
            };
        }
        if (fail.length) {
            event.fail = ^(NSError * _Nullable error) {
                
            };
        }
        if (success.length) {
            event.success = ^(NSDictionary * _Nullable result) {
                
            };
        }
        //callback为空时，前端可能传null字符串
    } else if ([callback isKindOfClass:[NSString class]] &&
               ![((NSString *)callback) isEqualToString:@"null"]
               && ((NSString *)callback).length) {
        //成功回调
        @weakify(event)
        event.success = ^(NSDictionary *_Nullable result){
            @strongify(event)
            //成功也添加errMsg信息
            if (result) {
                result = [NSMutableDictionary dictionaryWithDictionary:result];
                ((NSMutableDictionary *)result)[@"errMsg"] = [NSString stringWithFormat:@"%@ ok",event.funcName];
            } else {
                result = [NSMutableDictionary dictionary];
                ((NSMutableDictionary *)result)[@"errMsg"] = [NSString stringWithFormat:@"%@ ok",event.funcName];
            }
            if ([[NSThread currentThread] isMainThread]) {
                [WKWebViewHelper successWithResultData:result
                 webView:webView
                callback:callback];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [WKWebViewHelper successWithResultData:result
                     webView:webView
                    callback:callback];
                });
            }
        };
        //失败回调
        event.fail = ^(NSError *_Nullable error){
            if ([[NSThread currentThread] isMainThread]) {
                [WKWebViewHelper failWithError:error
                 webView:webView
                callback:callback];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [WKWebViewHelper failWithError:error
                     webView:webView
                    callback:callback];
                });
            }
        };
    }
    
    JSAsyncCallBaseHandler *handler = [WKWebViewCallHandlerFactory handlerByEvent:event];
    if (handler) {
        completionHandler([handler handleEvent:event]);
    } else {
        if (event.fail) {
            event.fail([NSError errorWithDomain:event.funcName
                                           code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"不支持"}]);
        }
        completionHandler(@"不支持");
    }
}

@end
