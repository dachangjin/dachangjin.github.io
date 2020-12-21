//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WXApi.h"
#import "WXApiObject.h"

typedef void(^ReqCompleteBlock)(BOOL success);

@protocol WXAuthDelegate <NSObject>

@optional
- (void)wxAuthSucceed:(NSString*)code;
- (void)wxAuthDenied;
- (void)wxAuthCancel;

@end

@interface WXApiManager : NSObject <WXApiDelegate>

@property (nonatomic, assign) id<WXAuthDelegate, NSObject> delegate;

/**
 *  严格单例，唯一获得实例的方法.
 *
 *  @return 实例对象.
 */
+ (instancetype)sharedManager;

/**
 *  发送微信验证请求.
 *
 *  @restrict 该方法支持未安装微信的用户.
 *
 *  @param viewController 发起验证的VC
 *  @param delegate       处理验证结果的代理
 */
- (void)sendAuthRequestWithController:(UIViewController*)viewController
                             delegate:(id<WXAuthDelegate>)delegate;

/**
 *  发送链接到微信.
 *
 *  @restrict 该方法要求用户一定要安装微信.
 *
 *  @param urlString 链接的Url
 *  @param title     链接的Title
 *  @param desc      链接的描述
 *  @param data     缩略图
 *  @param scene     发送的场景，分为朋友圈, 会话和收藏
 *
 */
- (void)sendLinkContent:(NSString *)urlString
                  title:(NSString *)title
            description:(NSString *)desc
              thumbData:(NSData *)data
                atScene:(enum WXScene)scene
          completeBlock:(ReqCompleteBlock)complete;



/// 发送图片到微信
/// @param imageData 图片数据
/// @param scene 场景
/// @param complete 完成回调
- (void)sendImage:(NSData *)imageData
          atScene:(enum WXScene)scene
    completeBlock:(ReqCompleteBlock)complete;



/// 发送文本到微信
/// @param text 文本
/// @param scene 场景
/// @param complete 完成回调
- (void)sendText:(NSString *)text
        atScene:(enum WXScene)scene
   completeBlock:(ReqCompleteBlock)complete;


/**
 *  发送文件到微信.
 *
 *  @restrict 该方法要求用户一定要安装微信.
 *
 *  @param fileData   文件的数据
 *  @param extension  文件扩展名
 *  @param title      文件的Title
 *  @param desc       文件的描述
 *  @param thumbImage 文件缩略图
 *  @param scene      发送的场景，分为朋友圈, 会话和收藏
 *
 */
- (void)sendFileData:(NSData *)fileData
       fileExtension:(NSString *)extension
               title:(NSString *)title
         description:(NSString *)desc
          thumbImage:(UIImage *)thumbImage
             atScene:(enum WXScene)scene
            completeBlock:(ReqCompleteBlock)complete;

@end
