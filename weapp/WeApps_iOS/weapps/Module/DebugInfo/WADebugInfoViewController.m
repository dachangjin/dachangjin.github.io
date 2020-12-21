//
//  WADebugInfoViewController.m
//  weapps
//
//  Created by tommywwang on 2020/8/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WADebugInfoViewController.h"
#import "Masonry.h"
#import "AppInfo.h"
#import "AppConfig.h"

@interface WADebugInfoViewController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation WADebugInfoViewController



- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (UIColor *)titleViewTintColor
{
    return [UIColor blackColor];
}

- (UIColor *)navigationBarTintColor
{
    return [self titleViewTintColor];
}


- (void)viewDidLoad
{
    self.title = @"debug信息";
    self.view.backgroundColor = [UIColor whiteColor];
    NSString *debug = @"false";
#if DEBUG
    debug = @"true";
#endif
    NSMutableString *debugInfo = [NSMutableString stringWithFormat:@"debug: %@",debug];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"appid: %@",[AppInfo appId]]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"app名称: %@",[AppInfo appName]]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"版本号: %@",[AppInfo appVersion]]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"动画显示时间: %d",kSplashTime]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"动画转跳链接: %@",kSplashJumpURL]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"动画远程加载链接: %@",kSplashURL]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"微信appId: %@",kWechatId]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"微信appSecret: %@",kWechatKey]];
    [debugInfo appendString:@"\n"];
    [debugInfo appendString:[NSString stringWithFormat:@"UniversalLink: %@",kWechatUL]];
    self.textView.text = debugInfo;
    self.textView.font = [UIFont systemFontOfSize:17];
}


- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        [self.view addSubview:_textView];
        [_textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
    }
    return _textView;
}

@end
