//
//  ViewController.m
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WebViewController.h"
#import "WKWebViewMessageHandler.h"
#import "WKWebViewUIDelegate.h"
#import "AppConfig.h"
#import "JSONHelper.h"
#import "WKWebViewHelper.h"
#import "ProURLHandler.h"
#import <AVFoundation/AVAsset.h>
#import "WALocationManager.h"
#import "Weapps.h"
#import "Device.h"
#import "WARefreshAnimateHeader.h"
#import "WAWebViewNetworkManager.h"
#import "WATabBar.h"
#import "MediaPickerAndPreviewHelper.h"
#import "UINavigationBar+Custom.h"
#import "NSString+Base64.h"


typedef NS_ENUM(NSUInteger, WAMoreItemButtonMode) {
    WAMoreItemButtonModeLight = 0,
    WAMoreItemButtonModeDark
};

//只适用于UIControlStateNormal
@interface WAMoreItemButton : UIButton

- (void)setDarkModeImage:(UIImage *)image;
- (void)setLightModeImage:(UIImage *)image;
- (void)setMode:(WAMoreItemButtonMode)mode;

@end

@implementation WAMoreItemButton
{
    UIImage *_darkModeImage;
    UIImage *_lightModeImage;
    WAMoreItemButtonMode _mode;
}

- (void)setDarkModeImage:(UIImage *)image
{
    _darkModeImage = image;
    if (_mode == WAMoreItemButtonModeDark) {
        [self setImage:image forState:UIControlStateNormal];
    }
}

- (void)setLightModeImage:(UIImage *)image
{
    _lightModeImage = image;
    if (_mode == WAMoreItemButtonModeLight) {
        [self setImage:image forState:UIControlStateNormal];
    }
}

- (void)setMode:(WAMoreItemButtonMode)mode
{
    if (_mode != mode) {
        UIImage *image = mode == WAMoreItemButtonModeDark ? _darkModeImage : _lightModeImage;
        [self setImage:image forState:UIControlStateNormal];
    }
    _mode = mode;
}


@end


#pragma mark - WebViewController

@interface WebViewController ()<WKNavigationDelegate,
WALocationManagerProtocol,
WeappsReachabilityProtocol,
WeappsConfigDelegate>
{

    
}
@property (nonatomic, strong) WebView *webView;
@property (nonatomic, strong) WATabBar *tabBar;
@property (nonatomic, strong) WKWebViewUIDelegate *uiDelegate;
@property (nonatomic, strong) ProURLHandler *URLHandler;

@property (nonatomic, strong) NSMutableArray<NSString *> *keyboardChangeCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *locationCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *appShowCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *appHideCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *reachibilityCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *pullDownRefreshCallbacks;
@property (nonatomic, strong) NSMutableArray<NSString *> *userCaptureScreenCallbacks;
@property (nonatomic, strong) UIBarButtonItem *backItem;
@property (nonatomic, strong) WAMoreItemButton *moreButton;
@property (nonatomic, strong) MediaPickerAndPreviewHelper *mediaHelper;

@end

@implementation WebViewController


- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (BOOL)shouldCustomizeNavigationBarTransitionIfHideable
{
    return YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationConfigs:[Weapps sharedApps].config];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.webView viewDidAppear];
    if (self.webView.state == WebViewStateLoadFinished) {
        if ([self syncCheckIfBecomeBlank]) {
            [self restoreFromIndex];
        } else {
            [self blankBodyCheck];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.webView viewWillDisappear];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor whiteColor];
    //setting在创建webView之前
    [self setting];
    [self initNavigationBar];
    [self.view addSubview:self.webView];
    [self.view addSubview:self.tabBar];
    //处理媒体相关
    self.mediaHelper = [[MediaPickerAndPreviewHelper alloc] init];
    self.mediaHelper.viewController = self;
}

- (void)setting
{
    //键盘
    _keyboardChangeCallbacks = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardHeightChange:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onKeyboardHeightChange:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    //定位
    _locationCallbacks = [NSMutableArray array];
    [[WALocationManager sharedManager] addLocationListener:self];
    
    //APP life circle
    _appHideCallbacks = [NSMutableArray array];
    _appShowCallbacks = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppShow)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppHide)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    //网络变化
    _reachibilityCallbacks = [NSMutableArray array];
    [[Weapps sharedApps].networkManager addReachabilityStatusChangeListener:self];
    self.URLHandler = [[ProURLHandler alloc] init];
    
    //屏幕
    _userCaptureScreenCallbacks = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onScreenCapture) name:UIApplicationUserDidTakeScreenshotNotification object:nil];
    //下拉刷新
    _pullDownRefreshCallbacks = [NSMutableArray array];
    
    //config
    [Weapps sharedApps].configDelegate = self;
    
}


- (void)initNavigationBar
{
    //导航栏
    self.titleView.needsLoadingView = YES;
    self.titleView.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.navigationItem.leftBarButtonItem = self.backItem;
}

- (void)goBack
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
//        WAConfig *config = [Weapps sharedApps].config;
//        [self updateTabBarWithConfig:config];
//        [self updatePageWithConfig:config];
//        [self updateNavigationConfigs:config];
//        [self updateWebViewFrameWithAnimation:NO];
    } else {
        if (self.navigationController && ![self.navigationController.viewControllers.firstObject isEqual:self]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

- (void)showMore
{
    
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateWebViewFrameWithAnimation:NO];
}


- (void)updateWebViewFrameWithAnimation:(BOOL)animation
{
    //根据是否显示自定义tabBar和navigationBar决定webViewFrame
    WAConfig *config = [Weapps sharedApps].config;
    
    CGFloat tabBarHeight = [config tabBarConfigContainItemOfHash:
                            [self.webView getCurrentUrlHash]] ? [self.tabBar hintHeight] : 0;
    WANavigationStyle style = [config getNavigationStyleByHash:
                               [self.webView getCurrentUrlHash]];
    CGFloat marginTop = style == WANavigationStyleDefault ? 44 + [Device statusBarHeight] : 0;
    
    
    void(^frameBlock)(CGFloat, CGFloat) = ^(CGFloat tabBarHeight, CGFloat marginTop){
        if (self.tabBar.config.position == WATabBarPositionBottom) {
            self.webView.frame = CGRectMake(0,
                                            marginTop,
                                            self.view.frame.size.width,
                                            self.view.frame.size.height - tabBarHeight - marginTop);
            self.tabBar.frame = CGRectMake(0,
                                           self.view.frame.size.height - tabBarHeight,
                                           self.view.frame.size.width,
                                           tabBarHeight);
        } else {
            self.tabBar.frame = CGRectMake(0,
                                           marginTop,
                                           self.view.frame.size.width,
                                           tabBarHeight);
            self.webView.frame = CGRectMake(0,
                                            tabBarHeight + marginTop,
                                            self.view.frame.size.width,
                                            self.view.frame.size.height - tabBarHeight - marginTop);
        }
    };
    if (animation) {
        [UIView animateWithDuration:.3 animations:^{
            frameBlock(tabBarHeight, marginTop);
        }];
    } else {
        frameBlock(tabBarHeight, marginTop);
    }
}

- (WKWebViewUIDelegate *)uiDelegate
{
    if (!_uiDelegate) {
        _uiDelegate = [[WKWebViewUIDelegate alloc] init];
    }
    return _uiDelegate;
}


- (UIBarButtonItem *)backItem
{
    if (!_backItem) {
        _backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"bar_item_back"]
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    }
    return _backItem;;
}

- (WAMoreItemButton *)moreButton
{
    if (!_moreButton) {
        _moreButton = [[WAMoreItemButton alloc] initWithFrame:CGRectMake(315.5, [Device statusBarHeight] + 8, 43.5, 28)];
        [_moreButton setDarkModeImage:[UIImage imageNamed:@"more_dark"]];
        [_moreButton setLightModeImage:[UIImage imageNamed:@"more_light"]];
    }
    return _moreButton;
}

- (WATabBar *)tabBar
{
    if (!_tabBar) {
        _tabBar = [[WATabBar alloc] init];
        @weakify(self)
        [_tabBar setSelectBlock:^(NSString * _Nonnull urlHash, NSUInteger index) {
            @strongify(self)
            [self webViewNavigateToHash:urlHash];
        }];
    }
    return _tabBar;
}

- (WebView *)webView
{
    if (!_webView) {
        //注入js代码
        
        NSString *bridgeJSString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle]
                                                                             pathForResource:@"JSBridge" ofType:@"js"] encoding:NSUTF8StringEncoding error:NULL];
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:bridgeJSString
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                       forMainFrameOnly:NO];
        
        WKWebViewConfiguration *webviewConfiguration = [[WKWebViewConfiguration alloc] init];
        webviewConfiguration.userContentController = [[WKUserContentController alloc] init];
        [webviewConfiguration.userContentController addUserScript:userScript];
//        [webviewConfiguration.preferences setValue:@(YES) forKey:@"allowFileAccessFromFileURLs"];

        
        //添加js handler
        [webviewConfiguration.userContentController addScriptMessageHandler:[[WKWebViewMessageHandler alloc] init] name:@"jsBridge"];
        
        //解决音乐播放问题
        webviewConfiguration.allowsInlineMediaPlayback = YES;
//        if (@available(iOS 10.0, *)) {
//            webviewConfiguration.mediaTypesRequiringUserActionForPlayback = false;
//        } else {
//            // Fallback on earlier versions
//        }
        
        _webView = [[WebView alloc] initWithFrame:CGRectZero configuration:webviewConfiguration];
//        _webView.scrollView.backgroundColor = [UIColor redColor];
//        _webView.backgroundColor = [UIColor redColor];
        _webView.scrollView.showsVerticalScrollIndicator = YES;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.UIDelegate = self.uiDelegate;
        _webView.navigationDelegate = self;
        _webView.allowsLinkPreview = NO;
        _webView.webHost = self;
        _webView.state = WebViewStateInit;
        //webView代理方法监听不了url的fragment变化，只能通过kvo监听
        [_webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
        [_webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
        //状态栏空白
        if (@available(iOS 11.0, *)) {
//            if (@available(iOS 13.0, *)) {
//                _webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = NO;
//            } else {
//                _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
//            }
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        if (self.URL) {
            request.URL = self.URL;
        } else {
//            request.URL = [self.URLHandler URLByPath:@"preview/index.html"];
            request.URL = [self.URLHandler URLByPath:@"index.html"];
        }
        request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        [_webView loadRequest:request];

    }
    return _webView;
}


// 设置下拉刷新
- (void)setupMJHeader
{
    if (!self.webView.scrollView.mj_header) {
        @weakify(self)
        WARefreshAnimateHeader *header = [WARefreshAnimateHeader headerWithRefreshingBlock:^{
            @strongify(self)
            [self webViewDidRefresh];
        }];
        
        header.lastUpdatedTimeLabel.hidden = YES;
        header.stateLabel.hidden = YES;
        
        self.webView.scrollView.mj_header = header;
        [self.webView.scrollView bringSubviewToFront:header];
    }
} 


- (void)removeMJHeader
{
    self.webView.scrollView.mj_header = nil;
}



- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (kStringEqualToString(keyPath, @"URL")) {
        WAConfig *config = [Weapps sharedApps].config;
        if (!config) {
            return;
        }
        [self updateTabBarWithConfig:config];
        [self updateNavigationConfigs:config];
        [self updatePageWithConfig:config];
        [self updateWebViewFrameWithAnimation:NO];
    } else if (kStringEqualToString(keyPath, @"loading")) {
        bool loading = [change[NSKeyValueChangeNewKey] boolValue];
        if (!loading) {
            self.webView.state = WebViewStateLoadFinished;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [WKWebViewHelper webViewDidFinishLoading:webView];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macos(10.11), ios(9.0))
{
//    [webView reload];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    if (self.URL) {
        request.URL = self.URL;
    } else {
        request.URL = [self.URLHandler URLByPath:@"index.html"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    [_webView loadRequest:request];
}


- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if ([self.URLHandler handleRequest:navigationAction.request]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
    }
}


//路由到对应hash地址
- (void)webViewNavigateToHash:(NSString *)hash
{
    if (!hash) {
        return;
    }
    NSString *urlString = [self.webView urlStringWithOutHash];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@#%@",urlString, hash]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - WeappsConfigDelegate
//设置配置
- (void)weappsConfigDidChange:(WAConfig *)config
{
    //设置tabBar
    [self setTabarConfigs:config];
    //更新tabBar
    [self updateTabBarWithConfig:config];
    //更新navitationBar
    [self updateNavigationConfigs:config];
    //更新页面
    [self updatePageWithConfig:config];
    //更新view布局
    [self.view setNeedsLayout];
}


//首次设置tabBar
- (void)setTabarConfigs:(WAConfig *)config
{
    if (config.tabBarConfig) {
        [self.tabBar setTabBarConfig:config.tabBarConfig];
    }
}

//更新tabBar
- (void)updateTabBarWithConfig:(WAConfig *)config
{
    //更新tabBar状态
    if (config.tabBarConfig) {
        [self.tabBar setSelectOfUrlHash:[self.webView getCurrentUrlHash] ignoreCallback:YES];
    }
}

//更新页面配置，如背景色，下拉刷新颜色
- (void)updatePageWithConfig:(WAConfig *)config
{
    if (!config) {
        return;
    }
    NSString *colorString = [config getBackgroundColorStringByHash:[self.webView getCurrentUrlHash]];
    UIColor *color = [UIColor qmui_rgbaColorWithHexString:colorString];
    if (!color) {
        color = [UIColor whiteColor];
    }
    NSString *colorStringTop = [config getBackgroundColorTopStringByHash:[self.webView getCurrentUrlHash]];
    UIColor *colorTop = [UIColor qmui_rgbaColorWithHexString:colorStringTop];
    if (!colorTop) {
        colorTop = [UIColor whiteColor];
    }
    NSString *colorStringBottom = [config getBackgroundColorBottomStringByHash:[self.webView getCurrentUrlHash]];
    UIColor *colorBottom = [UIColor qmui_rgbaColorWithHexString:colorStringBottom];
    if (!colorBottom) {
        colorBottom = [UIColor whiteColor];
    }
    WABackgroundTextStyle style = [config getBackgroundTextStyleByHash:[self.webView getCurrentUrlHash]];
    if (self.webView.scrollView.mj_header) {
        WARefreshAnimateHeader *header = (WARefreshAnimateHeader *)self.webView.scrollView.mj_header;
        if (style == WABackgroundTextStyleDark) {
            [header setStyle:WARefreshAnimateHeaderStyleDark];
        } else {
            [header setStyle:WARefreshAnimateHeaderStyleLight];
        }
    }
    [self.webView setScrollViewBackgroundColor:color];
    [self.webView setBackgroundColorTop:colorTop];
    [self.webView setBackgroundColorBottom:colorBottom];

}

//更新导航栏
- (void)updateNavigationConfigs:(WAConfig *)config
{
    if (!config) {
        return;
    }
    NSString *navBGColorString = [config getNavigationBackgroundColorStringByHash:[self.webView getCurrentUrlHash]];
    WANavigationBarTextStyle style = [config getTitleColorStringByHash:[self.webView getCurrentUrlHash]];
    WANavigationStyle navigationStyle = [config getNavigationStyleByHash:[self.webView getCurrentUrlHash]];
    NSString *title = [config getNavigationTitleByHash:[self.webView getCurrentUrlHash]];
    //导航栏背景色
    UIColor *navBGColor = [UIColor qmui_rgbaColorWithHexString:navBGColorString];
    if (!navBGColor) {
        navBGColor = [UIColor blackColor];
    }
    UIColor *titleColor = style == WANavigationBarTextStyleWhite ? [UIColor whiteColor] : [UIColor blackColor];
    if ([config.homeHash isEqualToString:[self.webView getCurrentUrlHash]]) {
        //去掉leftBarItem
        self.navigationItem.leftBarButtonItem = nil;
    } else {
        self.navigationItem.leftBarButtonItem = self.backItem;
    }
    
    [self setNavigationBarBackgroundColor:navBGColor
                             barTintColor:titleColor
                                    style:navigationStyle
                                    title:title];
    
}

//目前只涉及到背景色，标题文字，和文字颜色，保持返回按钮和文字颜色一致
- (void)setNavigationBarBackgroundColor:(UIColor *)bgColor
                           barTintColor:(UIColor *)tintColor
                                  style:(WANavigationStyle)style
                                  title:(NSString *)title
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (!navigationBar) return;
    if (bgColor) {
//        [navigationBar setBackgroundImage:[UIImage qmui_imageWithColor:bgColor] forBarMetrics:UIBarMetricsDefault];
        [navigationBar setBackgroundColor:bgColor withAnimationInfo:nil];
    }
    if (style == WANavigationStyleCustom) {
        //隐藏导航栏，让h5自定义
        [navigationBar setHidden:YES];
        navigationBar.topItem.rightBarButtonItem = nil;
        self.moreButton.frame = CGRectMake(315.5, [Device statusBarHeight] + 8, 43.5, 28);
        [self.view addSubview:self.moreButton];
    } else {
        [navigationBar setHidden:NO];
        [self.moreButton removeFromSuperview];
        navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.moreButton];
    }
    if (tintColor) {
        navigationBar.tintColor = tintColor;
        self.titleView.tintColor = tintColor;
        @weakify(self)
        self.qmui_preferredStatusBarStyleBlock = ^UIStatusBarStyle{
            @strongify(self)
            CGFloat white;
            //白色
            [tintColor getWhite:&white alpha:NULL];
            if (white == 1.0) {
                [self.moreButton setMode:WAMoreItemButtonModeLight];
                return UIStatusBarStyleLightContent;
            } else {
                [self.moreButton setMode:WAMoreItemButtonModeDark];
                if (@available(iOS 13.0, *)) {
                    return UIStatusBarStyleDarkContent;
                } else {
                    return UIStatusBarStyleDefault;
                }
            }
        };
        self.qmui_preferredStatusBarUpdateAnimationBlock = ^UIStatusBarAnimation{
            return UIStatusBarAnimationNone;
        };
        [self setNeedsStatusBarAppearanceUpdate];
    }
    self.titleView.title = title;
}

#pragma mark - WebHost

- (UIViewController *)currentViewController
{
    return self;
}

- (void)openWindowWithPathComponent:(NSString *)pathComponent
                            success:(void(^)(NSDictionary *_Nullable))successBlock
                               fail:(void(^)(NSError *_Nullable))failBlock{
    WebViewController *VC = [[WebViewController alloc] init];
    
    VC.URL = [self.URLHandler URLByPath:pathComponent];

   
    if (self.navigationController) {
        [self.navigationController pushViewController:VC animated:YES];
        if (successBlock) {
            successBlock(nil);
        }
    } else {
        UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:VC];
        VC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:navVC animated:YES completion:^{
            if (successBlock) {
                successBlock(nil);
            }
        }];
    }
}


- (void)popWithDelta:(NSUInteger)delta
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock
{
    if (self.navigationController) {
        NSArray *VCs = self.navigationController.viewControllers;
        if (delta >= VCs.count) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else if (delta <= 0) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            UIViewController *desVC = VCs[VCs.count - delta - 1];
            [self.navigationController popToViewController:desVC animated:YES];
        }
        if (successBlock) {
            successBlock(nil);
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            if (successBlock) {
                successBlock(nil);
            }
        }];
    }
}


#pragma mark - ScreenCapture
//************************************************截屏**************************************
- (void)addUserCaptureScreenCallback:(NSString *)callback
{
    if (callback) {
        [_userCaptureScreenCallbacks addObject:callback];
    }
}

- (void)removeUserCaptureScreenCallback:(NSString *)callback
{
    if ([_userCaptureScreenCallbacks containsObject:callback]) {
        [_userCaptureScreenCallbacks removeObject:callback];
    }
}

- (void)onScreenCapture
{
    for (NSString *func in _userCaptureScreenCallbacks) {
        [WKWebViewHelper successWithResultData:nil
                                       webView:_webView
                                      callback:func];
    }
}

#pragma mark - Keyboard  ****************键盘**************

//************************************************键盘**************************************

- (void)hideKeyboardsuccess:(void(^)(NSDictionary *_Nullable))successBlock
                       fail:(void(^)(NSError *_Nullable))failBlock
{
    [self.view resignFirstResponder];
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)addKeyboardChangeCallback:(NSString *)callback
{
    if (callback) {
        [_keyboardChangeCallbacks addObject:callback];
    }
}

- (void)removeKeyboardChangeCallback:(NSString *)callback
{
    if ([_keyboardChangeCallbacks containsObject:callback]) {
        [_keyboardChangeCallbacks removeObject:callback];
    }
}

- (void)onKeyboardHeightChange:(NSNotification *)noti
{
    CGRect keyboardBounds;
    [[noti.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    NSDictionary *dic = @{@"height": [NSNumber numberWithFloat:keyboardBounds.size.height]};
    for (NSString *callback in _keyboardChangeCallbacks) {
        [WKWebViewHelper successWithResultData:dic
                                       webView:self.webView
                                      callback:callback];
    }
}

#pragma mark - Media  ****************媒体**************
//****************************************媒体**********************************************

- (void)previewImages:(NSArray<NSString *> *)urls withCurrentIndex:(NSUInteger)index
{
    [self.mediaHelper previewImages:urls withCurrentIndex:index];
}

- (void)takeMediaFromCameraWithParams:(NSDictionary *)params
                    completionHandler:(void(^)(NSDictionary *_Nullable result, NSError *_Nullable error))completionHandler
{
    [self.mediaHelper takeMediaFromCameraWithParams:params
                                  completionHandler:completionHandler];
}

- (void)openPickerControllerWithParams:(NSDictionary *)params
                     completionHandler:(void(^)(NSDictionary *_Nullable result, NSError *_Nullable error))completionHandler
{
    [self.mediaHelper openPickerControllerWithParams:params
                                   completionHandler:completionHandler];
}

- (void)openDocument:(NSString *)path
            showMenu:(BOOL)showMenu
            fileType:(NSString *)fileType
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock
{
    [self.mediaHelper openDocument:path
                          showMenu:showMenu
                          fileType:fileType
                           success:successBlock
                              fail:failBlock];
}



#pragma mark - 页面相关
//****************************************导航栏**********************************************
- (void)showNavigationBarLoadingWithSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                                       fail:(void(^)(NSError *_Nullable))failBlock
{
    if (self.navigationController) {
        self.titleView.loadingViewHidden = NO;
    }
    if (successBlock) {
        successBlock(nil);
    }
    
}

- (void)hideNavigationBarLoadingWithSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                                       fail:(void(^)(NSError *_Nullable))failBlock
{
    if (self.navigationController) {
        self.titleView.loadingViewHidden = YES;
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)setNavigationBarTitle:(NSString *)title
                  withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                         fail:(void(^)(NSError *_Nullable))failBlock
{
    if (self.navigationController) {
        self.titleView.title = title;
    }
    if (successBlock) {
        successBlock(nil);
    }
}


- (void)setNavigationBarBackgroundColor:(UIColor *)color
                             frontColor:(nonnull UIColor *)frontColor
                      animationDuration:(CGFloat)animationDuration
                             timingFunc:(NSString *)timingFunc
                            withSuccess:(nonnull void (^)(NSDictionary * _Nullable))successBlock
                                   fail:(nonnull void (^)(NSError * _Nullable))failBlock
{
    if (self.navigationController) {
        AnimationInfo *info;
        if (animationDuration) {
            info = [[AnimationInfo alloc] init];
            info.duration = animationDuration;
            info.timingFunc = timingFunc;
        }
        [self.navigationController.navigationBar setBackgroundColor:color withAnimationInfo:info];
        [self.navigationController.navigationBar setTintColor:frontColor];
        @weakify(self)
        self.qmui_preferredStatusBarStyleBlock = ^UIStatusBarStyle{
            @strongify(self)
            CGFloat white;
            //白色
            [frontColor getWhite:&white alpha:NULL];
            if (white > 0.5) {
                [self.moreButton setMode:WAMoreItemButtonModeLight];
                return UIStatusBarStyleLightContent;
            } else {
                [self.moreButton setMode:WAMoreItemButtonModeDark];
                if (@available(iOS 13.0, *)) {
                    return UIStatusBarStyleDarkContent;
                } else {
                    return UIStatusBarStyleDefault;
                }
            }
        };
        self.qmui_preferredStatusBarUpdateAnimationBlock = ^UIStatusBarAnimation{
            return UIStatusBarAnimationFade;
        };
        [self setNeedsStatusBarAppearanceUpdate];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)hideHomeButtonWithSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                             fail:(void(^)(NSError *_Nullable))failBlock
{
    //TODO: 影藏homeButton
}

//****************************************背景**********************************************
- (void)setBackgroundTextStyle:(NSString *)style
                   withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                          fail:(void(^)(NSError *_Nullable))failBlock
{
    WABackgroundTextStyle textStyle = WABackgroundTextStyleDark;
    if (kStringEqualToString(style, @"light")) {
        textStyle = WABackgroundTextStyleLight;
    }
    if (self.webView.scrollView.mj_header) {
        WARefreshAnimateHeader *header = (WARefreshAnimateHeader *)self.webView.scrollView.mj_header;
        if (textStyle == WABackgroundTextStyleDark) {
            [header setStyle:WARefreshAnimateHeaderStyleDark];
        } else {
            [header setStyle:WARefreshAnimateHeaderStyleLight];
        }
    }
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
        backgroundColorTop:(UIColor *)backgroundColorTop
     backgroundColorBottom:(UIColor *)backgroundColorBottom
               withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                      fail:(void(^)(NSError *_Nullable))failBlock
{
    if (backgroundColor) {
        [self.webView setScrollViewBackgroundColor:backgroundColor];
    }
    if (backgroundColorBottom) {
        [self.webView setBackgroundColorBottom:backgroundColorBottom];
    }
    if (backgroundColorTop) {
        [self.webView setBackgroundColorTop:backgroundColorTop];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

//****************************************TabBar**********************************************
- (void)showTabBarRedDotAtIndex:(NSUInteger)index
                    withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                           fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        [_tabBar showRedDotAtIndex:index];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)hideTabBarRedDotAtIndex:(NSUInteger)index
                    withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                           fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        [_tabBar hideRedDotAtIndex:index];
        if (successBlock) {
            successBlock(nil);
        }
    } else if (failBlock) {
        failBlock([NSError errorWithDomain:@"hideTabBarRedDot" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"tabBar not exsit"
        }]);
    }
    
}

- (void)showTabBarWithAnimation:(BOOL)animation
                    withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                           fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        _tabBar.config.hiden = NO;
        [self updateWebViewFrameWithAnimation:animation];
    } else if (failBlock) {
        failBlock([NSError errorWithDomain:@"showTabBar" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"tabBar not exsit"
        }]);
    }
}

- (void)hideTabBarWithAnimation:(BOOL)animation
                    withSuccess:(void(^)(NSDictionary *_Nullable))successBlock
                           fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        _tabBar.config.hiden = YES;
        [self updateWebViewFrameWithAnimation:animation];
    } else if (failBlock) {
        failBlock([NSError errorWithDomain:@"hideTabBar" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"tabBar not exsit"
        }]);
    }
}

- (void)setTabBarStyleWithColor:(UIColor *)color
                  selectedColor:(UIColor *)selectedColor
                backgroundColor:(UIColor *)backgroundColor
                    borderStyle:(NSString *)borderStyle
                        success:(void(^)(NSDictionary *_Nullable))successBlock
                           fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        WATabBarBorderStyle style = WATabBarBorderStyleBlack;
        if (kStringEqualToString(borderStyle, @"white")) {
            style = WATabBarBorderStyleWhite;
        }
        [_tabBar updateTabBarBackgroundColor:backgroundColor
                                   itemColor:color
                           selectedItemColor:selectedColor
                                 borderStyle:style];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)setTabBarItemWithText:(NSString *)text
                     iconPath:(NSString *)iconPath
             selectedIconPath:(NSString *)selectedIconPath
                      atIndex:(NSUInteger )index
                      success:(void(^)(NSDictionary *_Nullable))successBlock
                         fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        [_tabBar updateTabBarItemText:text
                             iconPath:iconPath
                     selectedIconPath:selectedIconPath
                              atIndex:index];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)setTabBarBadge:(NSString *)badge
               atIndex:(NSUInteger)index
               success:(void(^)(NSDictionary *_Nullable))successBlock
                  fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        [_tabBar setBadge:badge
                  atIndex:index];
    }
    if (successBlock) {
        successBlock(nil);
    }
}

- (void)removeTabBarBadgeAtIndex:(NSUInteger)index
                         success:(void(^)(NSDictionary *_Nullable))successBlock
                            fail:(void(^)(NSError *_Nullable))failBlock
{
    if (_tabBar) {
        [_tabBar removeBadgeAtIndex:index];
    }
    if (successBlock) {
        successBlock(nil);
    }
}



#pragma mark - location

- (void)addLocationChangeCallback:(NSString *)callback
{
    if (callback) {
        [_locationCallbacks addObject:callback];
    }
}

- (void)removeLocationChangeCallback:(NSString *)callback
{
    if (callback) {
        [_locationCallbacks removeObject:callback];
    }
}

- (void)onLocationChanged:(WALocationModel *)model
{
    
    CLLocation *location = model.location;
    for (NSString *callback in _locationCallbacks) {
        [WKWebViewHelper successWithResultData:@{
                @"latitude"             : [NSNumber numberWithDouble:location.coordinate.latitude],
                @"longitude"            : [NSNumber numberWithDouble:location.coordinate.longitude],
                @"speed"                : [NSNumber numberWithDouble:location.speed > 0 ? : 0],
                @"accuracy"             : [NSNumber numberWithDouble:MAX(location.verticalAccuracy,
                location.horizontalAccuracy)],
                @"altitude"             : [NSNumber numberWithDouble:location.altitude],
                @"verticalAccuracy"     : [NSNumber numberWithDouble:location.verticalAccuracy],
                @"horizontalAccuracy"   : [NSNumber numberWithDouble:location.horizontalAccuracy]
                    }
                                       webView:self.webView
                                      callback:callback];
    }
}




#pragma mark - APP life circle

- (void)onAppShow
{
    for (NSString *callback in _appShowCallbacks) {
        [WKWebViewHelper successWithResultData:nil
                                       webView:self.webView
                                      callback:callback];
    }
}

- (void)onAppHide
{
    for (NSString *callback in _appHideCallbacks) {
        [WKWebViewHelper successWithResultData:nil
                                       webView:self.webView
                                      callback:callback];
    }
}

- (void)addAppHideCallback:(nonnull NSString *)callback
{
    if (callback) {
        [_appHideCallbacks addObject:callback];
    }
}

- (void)removeAppHideCallback:(nonnull NSString *)callback
{
    if (callback) {
        [_appHideCallbacks removeObject:callback];
    }
}


- (void)addAppShowCallback:(nonnull NSString *)callback
{
    if (callback) {
        [_appShowCallbacks addObject:callback];
    }
}


- (void)removeAppShowCallback:(nonnull NSString *)callback
{
    if (callback) {
        [_appShowCallbacks removeObject:callback];
    }
}


#pragma mark - reachibilityChange
- (void)weappsReachabilityStatusDidChange:(AFNetworkReachabilityStatus)status
{
    for (NSString *callback in _reachibilityCallbacks) {
        [WKWebViewHelper successWithResultData:@{
            @"isConnected"  : @([Device isReachable]),
            @"networkType"  : [Device networkType]
        }
                                       webView:self.webView
                                      callback:callback];
    }
}

- (void)addReachibilityChangeCallback:(NSString *)callback
{
    if (callback) {
        [_reachibilityCallbacks addObject:callback];
    }
}

- (void)removeReachibilityChangeCallback:(NSString *)callback
{
    if (callback) {
        [_reachibilityCallbacks removeObject:callback];
    } else {
        [_reachibilityCallbacks removeAllObjects];
    }
}

- (void)getCurrentPageQueryWithSuccess:(void (^)(NSDictionary * _Nullable))successBlock
                                  fail:(void (^)(NSError * _Nullable))failBlock
{
    NSString *query = self.webView.URL.query;
    if (successBlock) {
        if (!query.length) {
            successBlock(nil);
        } else {
            successBlock([query URLQueryToObject]);
        }
    }
}

#pragma mark - PullDownRefresh


- (void)stopPullDownRefresh
{
    if (self.webView.scrollView.mj_header) {
        [self.webView.scrollView.mj_header endRefreshing];
    }
}

- (void)startPullDownRefresh
{
    if (self.webView.scrollView.mj_header) {
        // 将state设置成MJRefreshStatePulling，启动 ... 动画
        self.webView.scrollView.mj_header.state = MJRefreshStatePulling;
        [self.webView.scrollView.mj_header beginRefreshing];
    }
}

- (void)addPullDownRefreshCallback:(NSString *)callback
{
    if (callback) {
        [_pullDownRefreshCallbacks addObject:callback];
        //有监听才让下拉刷新
        [self setupMJHeader];
    }
}

- (void)removePullDownRefreshCallback:(NSString *)callback
{
    if (callback) {
        [_pullDownRefreshCallbacks removeObject:callback];
        if (_pullDownRefreshCallbacks.count == 0) {
            //无监听，不让下拉刷新
            if ([self.webView.scrollView.mj_header isRefreshing]) {
                //正在下拉刷新，首先停止刷新，然后删除
                [self.webView.scrollView.mj_header endRefreshingWithCompletionBlock:^{
                    [self removeMJHeader];
                }];
            } else {
                //直接删除
                [self removeMJHeader];
            }
        }
    }
}

- (void)webViewDidRefresh
{
    for (NSString *callback in _pullDownRefreshCallbacks) {
        [WKWebViewHelper successWithResultData:nil
                                       webView:self.webView
                                      callback:callback];
    }
}


#pragma mark -白屏检测
// 同步检测
- (BOOL)syncCheckIfBecomeBlank {
    BOOL becomeBlank = ([self hasCompositingView:self.webView] == NO);
    if (becomeBlank) {
        WALOG(@"webView became blank: WKCompositingView");
    }
    return becomeBlank;
}


static Class WKCompositingViewClass() {
    static Class _class = nil;
    static dispatch_once_t _onceToken;
    dispatch_once(&_onceToken, ^{
        _class = NSClassFromString(@"WKCompositingView");
    });
    return _class;
}

// 检测是否有WKCompositingView
- (BOOL)hasCompositingView:(UIView *)view {
    // 如果苹果改了WKCompositingView的名字，这个方法就会有误
    // 所以如果没有这个类就直接return YES，使用别的检测方案
    Class compositingViewClass = WKCompositingViewClass();
    if (!compositingViewClass) {
        return YES;
    }
    if ([view isKindOfClass:compositingViewClass]) {
        return YES;
    }
    for (UIView *subView in view.subviews) {
        if ([self hasCompositingView:subView]) {
            return YES;
        }
    }
    return NO;
}


// 检测body.innerHTML
- (void)blankBodyCheck {
    @weakify(self);
    [self.webView evaluateJavaScript:@"document.body.innerHTML"
                   completionHandler:^(id result, NSError *error) {
        @strongify(self);
        if (!result || ([result isKindOfClass:[NSString class]] && [((NSString *)result) length] == 0)) {
            WALOG(@"webView became blank: bodyCheck");
            [self restoreFromIndex];
        }
    }];
}

//重新加载index页面
- (void)restoreFromIndex
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    if (self.URL) {
        request.URL = self.URL;
    } else {
        request.URL = [self.URLHandler URLByPath:@"index.html"];
    }
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    [self.webView loadRequest:request];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[WALocationManager sharedManager] removeLocationListener:self];
    [[Weapps sharedApps].networkManager removeReachabilityStatusChangeListener:self];
    [self.webView removeObserver:self forKeyPath:@"URL"];
}


@end
