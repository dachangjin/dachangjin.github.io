//
//  WALoginHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALoginHandler.h"
#import "LoginService.h"
#import "WAFaceVerifyViewController.h"


static  NSString *const weiXinLogin = @"weiXinLogin";
static  NSString *const faceVerify = @"faceVerify";

@implementation WALoginHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            weiXinLogin,
            faceVerify
        ];
    }
    return methods;
}


JS_API(weiXinLogin){
    [[LoginService sharedService] loginWithSuccess:^(NSDictionary * _Nonnull result) {
        kSuccessWithDic(result)
    } fail:^(NSError * _Nonnull error) {
        [self event:event failWithError:error];
    } inViewController:[event.webView.webHost currentViewController]];
    return @"";
}


JS_API(faceVerify){
    
    WAFaceVerifyViewController *VC = [[WAFaceVerifyViewController alloc] init];
    VC.completion = ^(NSDictionary *dic,NSError *error) {
        if (dic && !error) {
            kSuccessWithDic(dic)
        } else {
            [self event:event failWithError:error];
        }
    };
    UIViewController *webViewVC = [event.webView.webHost currentViewController];
    
    if (webViewVC.navigationController) {
        [webViewVC.navigationController pushViewController:VC animated:YES];
    } else {
        [webViewVC presentViewController:VC animated:YES completion:nil];
    }
    return @"";
}
@end
