//
//  WebView.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WebView.h"

@interface WebView ()
{
    UIView *_topView;
    UIView *_bottomView;
    UIColor *_backgroundColorTop;
    UIColor *_backgroundColorBottom;
}

@property (nonatomic, strong) NSMutableArray *viewWillDisappearBlocks;
@property (nonatomic, strong) NSMutableArray *viewDidAppearBlocks;
@property (nonatomic, strong) NSMutableArray *viewWillDeallocBlocks;

@end

@implementation WebView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration
{
    if (self = [super initWithFrame:frame configuration:configuration]) {
        self.viewDidAppearBlocks = [NSMutableArray array];
        self.viewWillDeallocBlocks = [NSMutableArray array];
        self.viewWillDisappearBlocks = [NSMutableArray array];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.viewDidAppearBlocks = [NSMutableArray array];
        self.viewWillDeallocBlocks = [NSMutableArray array];
        self.viewWillDisappearBlocks = [NSMutableArray array];
    }
    return self;
}

- (NSString *)getCurrentUrlHash
{
    return self.URL.fragment;
}

- (NSString *)urlStringWithOutHash
{
    return self.URL.path;
}

#pragma mark webView 生命周期
- (void)addViewWillDisappearBlock:(WebViewBlock)viewWillDisappearBlock {
    @synchronized (self.viewWillDisappearBlocks) {
        [self.viewWillDisappearBlocks addObject:viewWillDisappearBlock];
    }
}
- (void)addViewDidAppearBlock:(WebViewBlock)viewDidAppearBlock {
    @synchronized (self.viewDidAppearBlocks) {
        [self.viewDidAppearBlocks addObject:viewDidAppearBlock];
    }
}
- (void)addViewWillDeallocBlock:(WebViewBlock)viewWillDeallocBlock {
    @synchronized (self.viewWillDeallocBlocks) {
        [self.viewWillDeallocBlocks addObject:viewWillDeallocBlock];
    }
}
- (void)executeViewDidAppearBlocks {
    @synchronized (self.viewDidAppearBlocks) {
        for (NSInteger i = 0; i < self.viewDidAppearBlocks.count; i++) {
            WebViewBlock block = self.viewDidAppearBlocks[i];
            block(self);
        }
    }
}
- (void)executeViewWillDisappearBlocks {
    @synchronized (self.viewWillDisappearBlocks) {
        for (NSInteger i = 0; i < self.viewWillDisappearBlocks.count; i++) {
            WebViewBlock block = self.viewWillDisappearBlocks[i];
            block(self);
        }
    }
}


- (void)setScrollViewBackgroundColor:(UIColor *)backgroundColor
{
    if (backgroundColor) {
        self.scrollView.backgroundColor = backgroundColor;
    }
}

- (void)setBackgroundColorTop:(UIColor *)backgroundColorTop
{
    if (backgroundColorTop) {
        _backgroundColorTop = backgroundColorTop;
        // 下拉刷新组件现在太复杂,所以就自己创建了一个view，后续实现一个新的下拉刷新组件
        if (!_topView) {
            _topView = [[UIView alloc] init];
            [self.scrollView insertSubview:_topView atIndex:0];
        }
        _topView.frame = CGRectMake(0, -200, self.bounds.size.width, 200);
        _topView.backgroundColor = _backgroundColorTop;
    }
}

- (void)setBackgroundColorBottom:(UIColor *)backgroundColorBottom
{
    if (backgroundColorBottom) {
        _backgroundColorBottom = backgroundColorBottom;
        if (!_bottomView) {
            _bottomView = [[UIView alloc] init];
            [self.scrollView insertSubview:_bottomView atIndex:0];
        }
        _bottomView.backgroundColor = _backgroundColorBottom;
        // kvo监听url改变，webView还未完成路由，只能等待路由完成后获取准确的contentSize
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            self-> _bottomView.frame = CGRectMake(0, self.scrollView.contentSize.height , self.bounds.size.width, 1000);
        });
    }
}

#pragma mark webView 生命周期
- (void)viewDidAppear
{
    [self executeViewDidAppearBlocks];
}
- (void)viewWillDisappear
{
    [self executeViewWillDisappearBlocks];
}


- (void)dealloc
{
    @synchronized (self.viewWillDeallocBlocks) {
        for (NSInteger i = 0; i < self.viewWillDeallocBlocks.count; i++) {
            WebViewBlock block = self.viewWillDeallocBlocks[i];
            block(self);
        }
    }
    WALOG(@"webView die ++++++++++++");
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    
    UIView *view = [super hitTest:point withEvent:event];
    return view;
}

@end
