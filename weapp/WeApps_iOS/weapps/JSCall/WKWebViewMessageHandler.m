//
//  WKWebViewMessageHandler.m
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WKWebViewMessageHandler.h"
#import "WKWebViewHelper.h"
#import "JSAsyncEvent.h"
#import "WKWebViewCallHandlerFactory.h"
#import "JSONHelper.h"

@implementation WKWebViewMessageHandler


#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSDictionary *params = [JSONHelper exchangeStringToDictionary:message.body];
    if (![params isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *method = params[@"method"];
    if (!method.length) {
        return;
    }
    id callback = params[@"callback"];
    NSDictionary *args = params;
    if (params[@"data"]) {
        args = params[@"data"];
    }
    JSAsyncEvent *event = [[JSAsyncEvent alloc] init];
    event.funcName = method;
    event.args = args;
    event.webView = (WebView *)message.webView;
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
    } else if ([callback isKindOfClass:[NSString class]] && ![((NSString *)callback) isEqualToString:@"null"] && ((NSString *)callback).length) {
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
                 webView:message.webView
                callback:callback];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [WKWebViewHelper successWithResultData:result
                     webView:message.webView
                    callback:callback];
                });
            }
        };
        //失败回调
        event.fail = ^(NSError *_Nullable error){
            if ([[NSThread currentThread] isMainThread]) {
                [WKWebViewHelper failWithError:error
                 webView:message.webView
                callback:callback];
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [WKWebViewHelper failWithError:error
                     webView:message.webView
                    callback:callback];
                });
            }
        };
        event.callbacak = callback;
    }
    
    JSAsyncCallBaseHandler *handler = [WKWebViewCallHandlerFactory handlerByEvent:event];        
    if (handler) {
        [handler handleEvent:event];
    } else {
        if (event.fail) {
            event.fail([NSError errorWithDomain:event.funcName code:-1 userInfo:@{NSLocalizedDescriptionKey: @"current platform is not supported"}]);
        }
    }
}

@end
