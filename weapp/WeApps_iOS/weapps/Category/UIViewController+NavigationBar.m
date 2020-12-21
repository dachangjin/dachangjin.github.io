//
//  UIViewController+NavigationBar.m
//  weapps
//
//  Created by tommywwang on 2020/6/23.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "UIViewController+NavigationBar.h"
#import "QMUIRuntime.h"


@implementation UIViewController(NavigationBar)

+ (void)load
{
    ExchangeImplementations([UIViewController class], @selector(sw_viewDidLoad), @selector(viewDidLoad));
    ExchangeImplementations([UIViewController class],@selector(sw_viewWillAppear:), @selector(viewWillAppear:));
}

- (void)sw_viewDidLoad
{
    [self sw_viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
}



- (void)sw_viewWillAppear:(BOOL)animated
{
    [self sw_viewWillAppear:animated];
    [self setNeedsStatusBarAppearanceUpdate];
}

@end

@implementation UIButton (webKit)

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.gestureRecognizers containsObject:gestureRecognizer]) {
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    } else {
        return NO;
    }
}

@end


@implementation UISlider (webKit)

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.gestureRecognizers containsObject:gestureRecognizer]) {
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    } else {
        return NO;
    }
}


@end
