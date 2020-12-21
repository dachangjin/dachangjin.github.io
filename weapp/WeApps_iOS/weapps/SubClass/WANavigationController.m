//
//  WANavigationController.m
//  weapps
//
//  Created by tommywwang on 2020/6/23.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WANavigationController.h"
#import "WebViewController.h"
@interface WANavigationController ()

@end

@implementation WANavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[WebViewController class]]) {
        viewController.navigationItem.hidesBackButton = YES;
    }
    [super pushViewController:viewController animated:animated];
}

@end
