//
//  LoginService.m
//  weapps
//
//  Created by tommywwang on 2020/5/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "LoginService.h"
#import "WechatAuthSDK.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import "WXApiManager.h"
#import "WXUserInfo.h"
#import "WXNetworkEngine.h"
#import "WXWXLoginResp.h"
#import "WXCheckLoginResp.h"
#import "WXGetUserInfoResp.h"
#import "WXBaseResp.h"
#import "AppConfig.h"

@interface LoginService ()<WechatAuthAPIDelegate,WXAuthDelegate>

@property (nonatomic, copy)ArgsCallBlock success;
@property (nonatomic, copy)ErrorBlok fail;

@end

@implementation LoginService


#pragma mark - Life Cycle
+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    static LoginService *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)loginWithSuccess:(ArgsCallBlock)success
                       fail:(ErrorBlok)fail
        inViewController:(UIViewController *)viewController;
{
    self.success = success;
    self.fail = fail;
    
    //登录
    [self login];
}


- (void)login
{
    [[WXApiManager sharedManager] sendAuthRequestWithController:nil
    delegate:self];
}


-(void)sendAuthRequest
{
    //开启微信log
    [WXApi startLogByLevel:WXLogLevelDetail logBlock:^(NSString * _Nonnull log) {
        WALOG(@"%@",log);
    }];
    
    //发送微信认证请求
    [[WXApiManager sharedManager] sendAuthRequestWithController:nil
    delegate:self];
}



#pragma mark WXAuthDelegate
- (void)wxAuthSucceed:(NSString*)code
{
    [[WXNetworkEngine sharedEngine] wxLoginForAuthCode:code
                                                 appId:kWechatId
                                                secret:kWechatKey
                                        withCompletion:^(WXWXLoginResp *resp)
    {
        if (resp.baseResp.errcode == WXErrorCodeNoError) {
            [self handleWXLoginResponse:resp];
        } else {
            [self failWithResp:resp.baseResp];
        }
    }];
}

- (void)wxAuthDenied
{
    WXBaseResp *resp = [[WXBaseResp alloc] init];
    resp.errcode = WXErrorCodeAuthDenied;
    resp.errmsg = @"用户拒绝";
    [self failWithResp:resp];
}

- (void)wxAuthCancel
{
    WXBaseResp *resp = [[WXBaseResp alloc] init];
    resp.errcode = WXErrorCodeAuthCancel;
    resp.errmsg = @"用户取消";
    [self failWithResp:resp];
}

#pragma mark - Network Handlers


- (void)handleWXLoginResponse:(WXWXLoginResp *)loginResp {
    [[WXNetworkEngine sharedEngine] checkAccessToken:loginResp.accessToken
                                          withOpenId:loginResp.openId
                                          completion:^(WXCheckLoginResp *resp)
    {
        if (resp && resp.baseResp.errcode == WXErrorCodeNoError) {
            //获取用户信息
            [self getUserInfo:loginResp];
        } else {
            WALOG(@"access_token expired");
            //TODO refreshToken
            [[WXNetworkEngine sharedEngine] refreshToken:loginResp.refreshToken
                                               withAppId:kWechatId
                                              completion:^(WXWXLoginResp * _Nullable resp) {
                if (resp && resp.baseResp.errcode == WXErrorCodeNoError) {
                    [self getUserInfo:loginResp];
                } else if (resp && resp.baseResp.errcode == WXErrorCodeInvalidRefreshToken){
                    //重新拉取微信登录
                    [self login];
                } else {
                    [self failWithResp:resp.baseResp];
                }
            }];
        }
    }];
}



/// 获取用户信息
/// @param resp 请求回复信息
- (void)getUserInfo:(WXWXLoginResp *)resp {
    WALOG(@"Check Login Success");
    [[WXNetworkEngine sharedEngine] getUserInfoWithAccessToken:resp.accessToken
                                                        openId:resp.openId
                                                withCompletion:^(WXGetUserInfoResp *resp) {
        WALOG(@"userInfo:%@",resp.dictionaryRepresentation);
        if (resp.baseResp.errcode == WXErrorCodeNoError) {
            if (self.success) {
                self.success(resp.originalData);
            }
        } else {
            [self failWithResp:resp.baseResp];
        }
    }];
}



/// 失败
/// @param resp 失败信息
- (void)failWithResp:(WXBaseResp *)resp
{
    if (self.fail) {
        self.fail([NSError errorWithDomain:[WXNetworkEngine sharedEngine].host
                                      code:(NSInteger)resp.errcode
                                  userInfo:[resp dictionaryRepresentation]]);
    }
}

@end
