//
//  WebView.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN


@protocol WebHost <NSObject>

@optional

- (void)openWindowWithPathComponent:(NSString *)pathComponent
                            success:(void(^)(NSDictionary *_Nullable))successBlock
                               fail:(void(^)(NSError *_Nullable))failBlock;

- (void)popWithDelta:(NSUInteger)delta
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock;


- (void)hideKeyboardsuccess:(void(^)(NSDictionary *_Nullable))successBlock
                       fail:(void(^)(NSError *_Nullable))failBlock;


- (UIViewController *)currentViewController;

- (void)addUserCaptureScreenCallback:(NSString *)callback;

- (void)removeUserCaptureScreenCallback:(NSString *)callback;

- (void)addKeyboardChangeCallback:(NSString *)callback;

- (void)removeKeyboardChangeCallback:(NSString *)callback;

- (void)addLocationChangeCallback:(NSString *)callback;

- (void)removeLocationChangeCallback:(NSString *)callback;

- (void)addAppShowCallback:(NSString *)callback;

- (void)removeAppShowCallback:(NSString *)callback;

- (void)addAppHideCallback:(NSString *)callback;

- (void)removeAppHideCallback:(NSString *)callback;

- (void)addReachibilityChangeCallback:(NSString *)callback;

- (void)removeReachibilityChangeCallback:(NSString *)callback;

- (void)addPullDownRefreshCallback:(NSString *)callback;

- (void)removePullDownRefreshCallback:(NSString *)callback;

- (void)stopPullDownRefresh;

- (void)startPullDownRefresh;

//****************************************媒体**********************************************

- (void)previewImages:(NSArray<NSString *> *)urls withCurrentIndex:(NSUInteger)index;

- (void)takeMediaFromCameraWithParams:(NSDictionary *)params
                    completionHandler:(void(^)(NSDictionary *_Nullable result,
                                               NSError *_Nullable error))completionHandler;

- (void)openPickerControllerWithParams:(NSDictionary *)params
                     completionHandler:(void(^)(NSDictionary *_Nullable result,
                                                NSError *_Nullable error))completionHandler;

- (void)openDocument:(NSString *)path
            showMenu:(BOOL)showMenu
            fileType:(NSString *)fileType
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock;


//****************************************导航栏**********************************************
- (void)showNavigationBarLoadingWithSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                                       fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)hideNavigationBarLoadingWithSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                                       fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)setNavigationBarTitle:(NSString *)title
                  withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                         fail:(void(^)(NSError *_Nullable error))failBlock;


- (void)setNavigationBarBackgroundColor:(UIColor *)color
                             frontColor:(UIColor *)color
                      animationDuration:(CGFloat)animationDuration
                             timingFunc:(NSString *)timingFunc
                            withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                                   fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)hideHomeButtonWithSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                             fail:(void(^)(NSError *_Nullable error))failBlock;

//****************************************背景**********************************************
- (void)setBackgroundTextStyle:(NSString *)style
                   withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                          fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)setBackgroundColor:(UIColor *)backgroundColor
        backgroundColorTop:(UIColor *)backgroundColorTop
     backgroundColorBottom:(UIColor *)backgroundColorBottom
               withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                      fail:(void(^)(NSError *_Nullable error))failBlock;

//****************************************TabBar**********************************************
- (void)showTabBarRedDotAtIndex:(NSUInteger)index
                    withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                           fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)hideTabBarRedDotAtIndex:(NSUInteger)index
                    withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                           fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)showTabBarWithAnimation:(BOOL)animation
                    withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                           fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)hideTabBarWithAnimation:(BOOL)animation
                    withSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                           fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)setTabBarStyleWithColor:(UIColor *)color
                  selectedColor:(UIColor *)selectedColor
                backgroundColor:(UIColor *)backgroundColor
                    borderStyle:(NSString *)borderStyle
                        success:(void(^)(NSDictionary *_Nullable result))successBlock
                           fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)setTabBarItemWithText:(NSString *)text
                     iconPath:(NSString *)iconPath
             selectedIconPath:(NSString *)selectedIconPath
                      atIndex:(NSUInteger )index
                      success:(void(^)(NSDictionary *_Nullable result))successBlock
                         fail:(void(^)(NSError *_Nullable error))failBlock;

- (void)setTabBarBadge:(NSString *)badge
               atIndex:(NSUInteger)index
               success:(void(^)(NSDictionary *_Nullable))successBlock
                  fail:(void(^)(NSError *_Nullable))failBlock;

- (void)removeTabBarBadgeAtIndex:(NSUInteger)index
                         success:(void(^)(NSDictionary *_Nullable result))successBlock
                            fail:(void(^)(NSError *_Nullable error))failBlock;

//*****************************page**********************************
- (void)getCurrentPageQueryWithSuccess:(void(^)(NSDictionary *_Nullable result))successBlock
                                  fail:(void(^)(NSError *_Nullable error))failBlock;
@end

typedef NS_ENUM(NSUInteger, WebViewState) {
    WebViewStateInit,
    WebViewStateLoadFinished,
};

@class WebView;
typedef void(^WebViewBlock)(WebView *webView);

@interface WebView : WKWebView

@property (nonatomic, weak)id <WebHost>webHost;
@property (nonatomic, assign) WebViewState state;

- (NSString *)getCurrentUrlHash;
- (NSString *)urlStringWithOutHash;
#pragma mark webView 生命周期
- (void)addViewWillDisappearBlock:(WebViewBlock)viewDidDisappearBlock;
- (void)addViewDidAppearBlock:(WebViewBlock)viewWillAppearBlock;
- (void)addViewWillDeallocBlock:(WebViewBlock)viewWillDeallocBlock;
- (void)setScrollViewBackgroundColor:(UIColor *)backgroundColor;
- (void)setBackgroundColorTop:(UIColor *)backgroundColorTop;
- (void)setBackgroundColorBottom:(UIColor *)backgroundColorBottom;
- (void)viewDidAppear;
- (void)viewWillDisappear;
@end

NS_ASSUME_NONNULL_END
