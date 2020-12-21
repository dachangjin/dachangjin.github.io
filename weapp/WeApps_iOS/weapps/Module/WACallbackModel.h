//
//  WACallbackModel.h
//  weapps
//
//  Created by tommywwang on 2020/9/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventListenerList.h"
#import "WebView.h"
NS_ASSUME_NONNULL_BEGIN

@interface WACallbackModel : NSObject

//兼容多页面监听
@property (nonatomic, strong) EventListenerList *webViews;
@property (nonatomic, strong) NSLock *lock;

- (void)webView:(WebView *)webView onEventWithDict:(NSMutableDictionary *)dict callback:(NSString *)callback;
- (void)webView:(WebView *)webView offEventWithDict:(NSMutableDictionary *)dict callback:(NSString *)callback;
- (void)doCallbackInCallbackDict:(NSDictionary *)dict andResult:(NSDictionary * _Nullable)result;
- (NSString *)getKeyByWebView:(WebView *)webView;
@end

NS_ASSUME_NONNULL_END
