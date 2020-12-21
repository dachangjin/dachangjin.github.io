//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "BaseNetworkEngine.h"
#import "WXNetworkConfigManager.h"
#import "AFURLSessionManager+JSONRequest.h"
#import "DataModels.h"
#import "RandomKey.h"

static NSString* const defaultHost = @"https://api.weixin.qq.com";

@interface BaseNetworkEngine ()

@property (nonatomic, strong, readwrite) AFURLSessionManager *manager;

@end

@implementation BaseNetworkEngine

#pragma mark - Life Cycle
+ (instancetype)sharedEngine {
    static NSMutableDictionary *instanceMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instanceMap = [NSMutableDictionary dictionary];
    });
    NSString *className = NSStringFromClass([self class]);
    @synchronized(instanceMap) {
        if (instanceMap[className]) {
            return instanceMap[className];
        } else {
            return instanceMap[className] = [[[self class] alloc] initWithHost:defaultHost];
        }
    }
}

- (instancetype)initWithHost:(NSString *)host {
    if (self = [super init]) {
        self.host = host;
    }
    return self;
}

- (instancetype)init {
    return nil;
}

- (instancetype)copy {
    return nil;
}

#pragma mark - Public Methods

- (void)wxLoginForAuthCode:(NSString *)code
                     appId:(NSString *)appId
                    secret:(NSString *)secret
            withCompletion:(WXLoginCallBack)completion {
    NSParameterAssert(code);
    [[self.manager JSONTaskForHost:self.host
                              params:@{
                                     @"appid": appId,
                                     @"secret": secret,
                                     @"code": code,
                                     @"grant_type": @"authorization_code"
                                     }
                     configKeyPath:(NSString *)kAccessTokenName
                    withCompletion:^(NSDictionary *dict, NSError *error)
      {
        if (completion) {
             completion (error == nil ? [WXWXLoginResp modelObjectWithDictionary:dict] : nil);
        }
    }] resume];
}


- (void)checkAccessToken:(NSString *)accessToken
              withOpenId:(NSString *)openId
              completion:(CheckLoginCallBack)completion
{
    NSParameterAssert(accessToken);
    NSParameterAssert(openId);

    [[self.manager JSONTaskForHost:self.host
                              params:@{
                                     @"access_token": accessToken,
                                     @"openid": openId,
                                     }
                     configKeyPath:(NSString *)kCheckTokenName
                    withCompletion:^(NSDictionary *dict, NSError *error) {
                        WXCheckLoginResp *resp = nil;
                        if (error == nil) {
                            resp = [WXCheckLoginResp modelObjectWithDictionary:dict];
                             if (completion) {
                                 completion(resp);
                             }
                        }
                        
                    }] resume];
}


- (void)refreshToken:(NSString *)refreshToken
          withAppId:(NSString *)appId
          completion:(WXLoginCallBack)completion
{
    NSParameterAssert(refreshToken);
    NSParameterAssert(appId);
    [[self.manager JSONTaskForHost:self.host
                                  params:@{
                                         @"refresh_token": refreshToken,
                                         @"appId": appId}
                         configKeyPath:(NSString *)kRefreshTokenName
                        withCompletion:^(NSDictionary *dict, NSError *error)
    {
        if (!error) {
           if (completion) {
                  completion([WXWXLoginResp modelObjectWithDictionary:dict]);
           }
        } else {
            
        }
                        
    }] resume];
}


- (void)getUserInfoWithAccessToken:(NSString *)token
                            openId:(NSString *)openId
                    withCompletion:(GetUserInfoCallBack)completion
{
    NSParameterAssert(token);
    NSParameterAssert(openId);
    [[self.manager JSONTaskForHost:self.host
                              params:@{
                                     @"access_token": token,
                                     @"openid": openId}
                     configKeyPath:(NSString *)kUserinfoName
                    withCompletion:^(NSDictionary *dict, NSError *error)
    {
        WXGetUserInfoResp *resp = [WXGetUserInfoResp modelObjectWithDictionary:dict];
        if (completion) {
            completion(resp);
        }
    }] resume];
}




- (void)makeRefreshTokenExpired:(UInt32)uin
                    loginTicket:(NSString *)loginTicket {
    [[self.manager JSONTaskForHost:self.host
                              params:@{
                                     @"uin": @(uin),
                                     @"req_buffer": @{
                                             @"uin": @(uin),
                                             @"login_ticket": loginTicket
                                             }
                                     }
                     configKeyPath:(NSString *)kMakeExpiredCGIName
                    withCompletion:^(NSDictionary *dict, NSError *error) {
                        WALOG(@"%@",dict);
                    }] resume];
}

#pragma mark - Lazy Initializer
- (AFURLSessionManager *)manager {
    if (_manager == nil) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
        AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        serializer.acceptableContentTypes = [serializer.acceptableContentTypes setByAddingObject:@"text/plain"];
        _manager.responseSerializer = serializer;
    }
    return _manager;
}


@end
