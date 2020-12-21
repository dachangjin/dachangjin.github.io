//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class AFURLSessionManager;
@class ADConnectResp;
@class WXCheckLoginResp;
@class WXGetUserInfoResp;
@class WXWXLoginResp;

typedef void(^CheckLoginCallBack)(WXCheckLoginResp * _Nullable resp);
typedef void(^GetUserInfoCallBack)(WXGetUserInfoResp * _Nullable resp);
typedef void(^WXLoginCallBack)(WXWXLoginResp * _Nullable resp);
typedef void(^DownloadImageCallBack)(UIImage * _Nullable image);

@interface BaseNetworkEngine : NSObject

@property (nonatomic, strong, readonly, nullable) AFURLSessionManager * manager;

@property (nonatomic, strong, nullable) NSString * host;

/**
 *  严格单例，唯一获得实例的方法.
 *
 *  @return 实例对象.
 */
+ (instancetype _Nonnull)sharedEngine;



/// 获取access_token
/// @param code 微信授权后获得的code
/// @param appId 微信appId
/// @param secret 微信secret
/// @param completion  完成回调
- (void)wxLoginForAuthCode:(nonnull NSString *)code
                     appId:(nonnull NSString *)appId
                    secret:(nonnull NSString *)secret
            withCompletion:(nullable WXLoginCallBack)completion;



/// 检查accessToken是否失效
/// @param accessToken 微信accessToken
/// @param openId 微信openId
/// @param completion 完成回调
- (void)checkAccessToken:(nonnull NSString *)accessToken
              withOpenId:(nonnull NSString *)openId
              completion:(nullable CheckLoginCallBack)completion;



/// 根据refreshToken刷新accessToken
/// @param refreshToken 微信refreshToken
/// @param appId 微信appId
/// @param completion 完成回调
- (void)refreshToken:(nonnull NSString *)refreshToken
          withAppId:(nonnull NSString *)appId
          completion:(nullable WXLoginCallBack)completion;

/// 获取用户信息
/// @param accessToken 微信accessToken
/// @param openId 微信openId
/// @param completion 完成回调
- (void)getUserInfoWithAccessToken:(nonnull NSString *)accessToken
                            openId:(nonnull NSString *)openId
                    withCompletion:(nullable GetUserInfoCallBack)completion;




@end
