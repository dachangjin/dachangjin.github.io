//
//  WADebugViewController.m
//  weapps
//
//  Created by tommywwang on 2020/7/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WADebugViewController.h"
#import "AppConfig.h"
#import "Masonry.h"
#import "WBQRCodeVC.h"
#import "WebViewController.h"
#import "WADebugInfoViewController.h"
#import "AppConfig.h"

@interface WADebugViewController ()
@property (nonatomic, strong) QMUIButton *showConfigButton;
@property (nonatomic, strong) QMUIButton *scanQRCodeButton;
@property (nonatomic, strong) UILabel *versionLabel;
@end

@implementation WADebugViewController


- (BOOL)preferredNavigationBarHidden {
    return NO;
}

- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (BOOL)shouldCustomizeNavigationBarTransitionIfHideable
{
    return YES;
}

- (UIImage *)navigationBarBackgroundImage
{
    return [UIImage qmui_imageWithColor:[UIColor whiteColor]];
}

- (UIColor *)titleViewTintColor
{
    return [UIColor blackColor];
}

- (UIColor *)navigationBarTintColor
{
    return [self titleViewTintColor];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.showConfigButton];
    [self.view addSubview:self.scanQRCodeButton];
    [self.view addSubview:self.versionLabel];
    [self addConstrains];
}

- (void)addConstrains
{
    [self.showConfigButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).inset(20);
        make.right.equalTo(self.view).inset(20);
        make.top.equalTo(self.view).inset(80);
        make.height.mas_equalTo(40);
    }];
    [self.scanQRCodeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).inset(20);
        make.right.equalTo(self.view).inset(20);
        make.top.equalTo(self.showConfigButton.mas_bottom).inset(30);
        make.height.mas_equalTo(40);
    }];
    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).inset(20);
        make.right.equalTo(self.view).inset(20);
        make.top.equalTo(self.scanQRCodeButton.mas_bottom).inset(30);
        make.height.mas_equalTo(40);
    }];
}

- (UIButton *)showConfigButton
{
    if (!_showConfigButton) {
        _showConfigButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [_showConfigButton setTitle:@"查看配置信息" forState:UIControlStateNormal];
        [_showConfigButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _showConfigButton.backgroundColor = [UIColor lightGrayColor];
        _showConfigButton.highlightedBackgroundColor = [UIColor grayColor];
        [_showConfigButton addTarget:self action:@selector(showConfig) forControlEvents:UIControlEventTouchUpInside];
    }
    return _showConfigButton;
}

- (UIButton *)scanQRCodeButton
{
    if (!_scanQRCodeButton) {
        _scanQRCodeButton = [QMUIButton buttonWithType:UIButtonTypeCustom];
        [_scanQRCodeButton setTitle:@"扫码" forState:UIControlStateNormal];
        [_scanQRCodeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _scanQRCodeButton.backgroundColor = [UIColor lightGrayColor];
        _scanQRCodeButton.highlightedBackgroundColor = [UIColor grayColor];
        [_scanQRCodeButton addTarget:self action:@selector(scanQrCode) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scanQRCodeButton;
}

- (UILabel *)versionLabel
{
    if (!_versionLabel) {
        _versionLabel = [[UILabel alloc] init];
        _versionLabel.backgroundColor = [UIColor lightGrayColor];
        _versionLabel.textAlignment = NSTextAlignmentCenter;
        if (IS_DEBUG) {
            _versionLabel.text = [NSString stringWithFormat:@"测试版本: V%@",SDK_VERSION];
        } else {
            _versionLabel.text = [NSString stringWithFormat:@"正式版本: V%@",SDK_VERSION];
        }
    }
    return _versionLabel;
}

- (void)showConfig
{
    WADebugInfoViewController *viewController = [[WADebugInfoViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)scanQrCode
{
    WBQRCodeVC *viewController = [[WBQRCodeVC alloc] init];
    viewController.scanPrams = @{
        @"onlyFromCamera": @YES,
    };
    viewController.scanCodeCallBack = ^(NSDictionary *dic){
        [self.navigationController popViewControllerAnimated:NO];
        NSString *string = dic[@"result"];
        NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:nil];
        
        NSArray *arrayOfAllMatches = [detector matchesInString:string options:0 range:NSMakeRange(0,string.length)];
        if (arrayOfAllMatches.count) {
            NSTextCheckingResult *result = [arrayOfAllMatches firstObject];
            NSString *urlString = [string substringWithRange:result.range];
            WebViewController *webVC = [[WebViewController alloc] init];
            webVC.URL = [NSURL URLWithString:urlString];
            [self.navigationController pushViewController:webVC animated:YES];
        } else {
            [QMUITips showInfo:string];
        }
    };
    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)dealloc
{
    if (self.deallocBlock) {
        self.deallocBlock();
    }
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
