//
//  WKWebViewHelper.m
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WKWebViewHelper.h"
#import "NSDate+ToString.h"

static NSString *const timeFormat = @"yyyy-MM-dd HH:mm:ss";

@implementation WKWebViewHelper


+ (NSString *)jsonStringWithData:(NSDictionary *)data
{
    if (!data) {
        return nil;
    }
    NSString *messageJSON = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:data
                                                                                           options:0
                                                                                             error:NULL]
                                                  encoding:NSUTF8StringEncoding];;

    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\f" withString:@"\\f"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    messageJSON = [messageJSON stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];

    return messageJSON;
}


//+ (void)callbackWithResult:(NSString *)result resultData:(NSDictionary *)resultData message:(WKScriptMessage *)message callback:(NSString *)callback
//{
//    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
//    resultDictionary[@"result"] = result;
//    
//    if ([result isEqualToString:@"success"]) {
//        [resultDictionary addEntriesFromDictionary:@{
//            @"status": @{
//                    @"code": @(0),
//                    @"msg": @"请求成功"
//            }
//        }];
//        if (resultData) {
//            [resultDictionary addEntriesFromDictionary:@{
//                @"data": resultData
//            }];
//        }
//        NSString *resultDataString = [self jsonStringWithData:resultDictionary];
//        [self successWithResult:resultDataString webView:message.webView callback:callback];
//    }else if ([result isEqualToString:@"fail"]) {
//        [resultDictionary addEntriesFromDictionary:@{
//            @"status": @{
//                    @"code": @(1),
//                    @"msg": @"请求失败"
//            }
//        }];
//        NSString *resultDataString = [self jsonStringWithData:resultDictionary];
//        [self failWithResult:resultDataString webView:message.webView callback:callback];
//    }else {
////        [self completeWithWebView:message.webView callback:callback];
//    }
//}


+ (void)successWithResultData:(nullable NSDictionary *)resultData
                      webView:(nonnull WKWebView *)webView
                     callback:(nonnull NSString *)callback
{
//    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
//
//    [resultDictionary addEntriesFromDictionary:@{
//        @"status": @{
//                @"code": @(0),
//                @"msg": @"操作成功"
//        },
//        @"timestamp": [[NSDate date] stringByFormat:timeFormat]
//    }];
//    if (resultData) {
//        [resultDictionary addEntriesFromDictionary:@{
//            @"data": resultData
//        }];
//    }
    NSString *resultDataString = [self jsonStringWithData:resultData];
    if (!resultDataString) {
        resultDataString = @"{}";
    }
    if ([[NSThread currentThread] isMainThread]) {
        [self handleWithData:resultDataString webView:webView callback:callback];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handleWithData:resultDataString webView:webView callback:callback];
        });
    }
}

+ (void)failWithError:(nullable NSError *)error
              webView:(nonnull WKWebView *)webView
             callback:(nonnull NSString *)callback
{
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *errorString = error ? [NSString stringWithFormat:@"%@:fail %@",error.domain,error.userInfo[NSLocalizedDescriptionKey]] : @"操作失败";
    if (!errorString) {
        errorString = @"操作失败";
    }
//    [resultDictionary addEntriesFromDictionary:@{
//        @"status": @{
//                    @"code": [NSNumber numberWithInteger:error.code],
//                    @"msg": errorString
//                    },
//        @"timestamp": [[NSDate date] stringByFormat:timeFormat]
//    }];
    [resultDictionary addEntriesFromDictionary:@{
                                                @"errCode": [NSNumber numberWithInteger:error.code],
                                                @"errMsg": errorString
    }];
    NSString *resultDataString = [self jsonStringWithData:resultDictionary];
    if ([[NSThread currentThread] isMainThread]) {
//        [self handleWithResult:resultDataString webView:message.webView callback:callback];
        [self handleWithError:resultDataString webView:webView callback:callback];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self handleWithError:resultDataString webView:webView callback:callback];
        });
    }}

//一般回调改为callback(error,data)
+ (void)handleWithError:(NSString *)errorString
                  webView:(WKWebView *)webView
                 callback:(NSString *)callback
{
    NSString *callbackString = [NSString stringWithFormat:@"window.%@('%@','null')", callback, errorString];
    [self runScript:callbackString inWebView:webView];
}

+ (void)handleWithData:(NSString *)dataString
                  webView:(WKWebView *)webView
                 callback:(NSString *)callback
{
    NSString *callbackString = [NSString stringWithFormat:@"window.%@('null','%@')", callback, dataString];
    [self runScript:callbackString inWebView:webView];
}



//+ (void)completeWithWebView:(WKWebView *)webView
//                   callback:(NSString *)callback
//{
//    NSString *callbackString = [NSString stringWithFormat:@"window.complete('%@')", callbackId];
//    [self runScript:callbackString InWebView:webView];
//}

+ (void)webViewDidStartLoading:(WKWebView *)webView
{
    NSString *callbackString = @"window.onStartLoading()";
    [self runScript:callbackString inWebView:webView];
}

+ (void)webViewDidFinishLoading:(WKWebView *)webView;
{
//    NSString *callbackString = @"window.onFinishLoading()";
//    [self runScript:callbackString inWebView:webView];
}


+ (void)runScript:(NSString *)script inWebView:(WKWebView *)webView
{
    if ([[NSThread currentThread] isMainThread]) {
        [webView evaluateJavaScript:script completionHandler:^(id _Nullable objc, NSError * _Nullable error) {
            WALOG(@"%@",error.userInfo.description);
        }];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [webView evaluateJavaScript:script completionHandler:^(id _Nullable objc, NSError * _Nullable error) {
                WALOG(@"%@",error.userInfo.description);
            }];
        });
    }
}

+ (UIScrollView *)findContainerInWebView:(WKWebView *)webView
                              withParams:(NSDictionary *)params
{
    NSDictionary *positionDict = params[@"position"] ? : params;
    CGFloat x = [positionDict[@"left"] floatValue];
    CGFloat y = [positionDict[@"top"] floatValue];
    CGFloat width = [positionDict[@"width"] floatValue];
    CGFloat height = [positionDict[@"height"] floatValue];
    CGFloat scrollHeight = [positionDict[@"scrollHeight"] floatValue];
    
    CGRect targetRect = CGRectMake(x, y, width, height);
    UIScrollView *targetView = [self findTargetView:targetRect
                                 scrollHeight:scrollHeight
                                    superView:webView
                                    inWebView:webView];
    targetView.scrollEnabled = NO;
    return targetView;
}


+ (UIScrollView *)findTargetView:(CGRect)targetRect
              scrollHeight:(CGFloat)scrollHeight
                 superView:(UIView *)superView
                 inWebView:(WKWebView *)webView
{
    UIScrollView *targetView = nil;
    for (UIView *subView in superView.subviews) {
        if (subView.subviews.count > 0) {
            targetView = [self findTargetView:targetRect
                                 scrollHeight:scrollHeight
                                    superView:subView
                                    inWebView:webView];
            if (targetView) {
                break;
            }
        }
        if ([subView isKindOfClass:[UIScrollView class]] && subView.tag == 0) {
            CGRect rect = [subView convertRect:subView.frame toView:webView.scrollView];
            CGPoint roundPoint = CGPointMake((int)rect.origin.x, (int)rect.origin.y);
            CGPoint roundTargetPoint = CGPointMake((int)targetRect.origin.x, (int)targetRect.origin.y);
            if (CGPointEqualToPoint(roundPoint, roundTargetPoint)
                && CGSizeEqualToSize(rect.size, targetRect.size)
//                && ((UIScrollView *)subView).contentSize.height == scrollHeight
                ) {
                targetView = (UIScrollView *)subView;
                targetView.scrollEnabled = NO;
                break;
            }
        }
    }
    return targetView;
}
@end
