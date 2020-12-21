//
//  WACallbackModel.m
//  weapps
//
//  Created by tommywwang on 2020/9/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WACallbackModel.h"
#import "WKWebViewHelper.h"

@implementation WACallbackModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _webViews = [[EventListenerList alloc] init];
    }
    return self;
}

- (void)webView:(WebView *)webView onEventWithDict:(NSMutableDictionary *)dict callback:(NSString *)callback
{
    if (!callback.length) {
        return;
    }
    NSString *key = [self getKeyByWebView:webView];
    if (![self.webViews containsListener:webView]) {
        [self.webViews addListener:webView];
        @weakify(self)
        [webView addViewWillDeallocBlock:^(WebView * _Nonnull web) {
           @strongify(self)
            [self.webViews removeListener:web];
            [self.lock lock];
            [dict removeObjectForKey:key];
            [self.lock unlock];
        }];
    }
    
    [self.lock lock];
    NSMutableArray *callbacks = dict[key];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
        dict[key] = callbacks;
    }
    [callbacks addObject:callback];
    [self.lock unlock];
}

- (void)webView:(WebView *)webView offEventWithDict:(NSMutableDictionary *)dict callback:(NSString *)callback
{
    if (!callback.length) {
        return;
    }
    if (![self.webViews containsListener:webView]) {
        return;
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = dict[key];
    if (callbacks) {
        [callbacks removeObject:callback];
        if (callbacks.count == 0) {
            [dict removeObjectForKey:key];
        }
    }
    [self.lock unlock];
}

- (void)doCallbackInCallbackDict:(NSDictionary *)dict andResult:(NSDictionary *)result
{
    @weakify(self)
    [self.webViews fireListeners:^(WebView *listener) {
        @strongify(self)
        NSString *key = [self getKeyByWebView:listener];
        [self.lock lock];
        NSArray *callbacks = dict[key];
        if (callbacks.count) {
            for (NSString *callback in callbacks) {
                [WKWebViewHelper successWithResultData:result
                                               webView:listener
                                              callback:callback];
            }
        }
        [self.lock unlock];
    }];
}


//获取webView内存地址
- (NSString *)getKeyByWebView:(WebView *)webView
{
    return [NSString stringWithFormat:@"%p",webView];
}

@end
