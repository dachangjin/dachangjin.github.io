//
//  TRTCCall.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by xiangzhang on 2020/7/2.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TXLiteAVSDK_Professional/TRTCCloud.h>
#import <ImSDK_Smart/ImSDK_Smart.h>
#import "TRTCCallingModel.h"
#import "TRTCCallingDelegate.h"


NS_ASSUME_NONNULL_BEGIN

typedef void(^CallingActionCallback)(void);
typedef void(^ErrorCallback)(NSInteger code, NSString *des);

@interface TRTCCalling : NSObject<TRTCCloudDelegate,V2TIMSignalingListener>

/// IM APNS推送ID
@property (nonatomic, assign) int imBusinessID;
/// 推送DeviceToken，需要在调用登录之前设置，否则APNS推送会设置失败
@property (nonatomic, strong) NSData *deviceToken;

/// 单例对象
+ (TRTCCalling *)shareInstance;

/// 设置TRTCCallingDelegate回调
/// @param delegate 回调实例
- (void)addDelegate:(id<TRTCCallingDelegate>)delegate;

/// 登录接口
/// @param sdkAppID SDK ID，可在腾讯云控制台获取
/// @param userID 用户ID
/// @param userSig 用户签名
/// @param success 成功回调
/// @param failed 失败回调
- (void)login:(UInt32)sdkAppID
         user:(NSString *)userID
      userSig:(NSString *)userSig
      success:(CallingActionCallback)success
       failed:(ErrorCallback)failed
NS_SWIFT_NAME(login(sdkAppID:user:userSig:success:failed:));


/// 登出接口
/// @param success 成功回调
/// @param failed 失败回调
- (void)logout:(CallingActionCallback)success
        failed:(ErrorCallback)failed
NS_SWIFT_NAME(logout(success:failed:));

/// 发起1v1通话接口
/// @param userID 被邀请方ID
/// @param type 通话类型：视频/语音
- (void)call:(NSString *)userID
        type:(CallType)type
NS_SWIFT_NAME(call(userID:type:));

/// 发起多人通话
/// @param userIDs 被邀请方ID列表
/// @param type 通话类型:视频/语音
/// @param groupID 群组ID，可选参数
- (void)groupCall:(NSArray *)userIDs
             type:(CallType)type
          groupID:(NSString * _Nullable)groupID
NS_SWIFT_NAME(groupCall(userIDs:type:groupID:));

/**
 * 进入会议（其他参会者调用）
 *
 * @param roomId 房间标识，需要由您分配并进行统一管理。
 * @param callback 结果回调，成功时 code 为0.
 */
- (void)enterRoom:(UInt32)roomId
     withSdkAppId:(UInt32)sdkAppId
           userId:(NSString *)userId
          userSig:(NSString *)userSig
         callback:(ErrorCallback)callback;

/**
 * 离开房间（其他参会者调用）
 *
 * @param callback 结果回调，成功时 code 为0.
 */
- (void)leaveRoom:(ErrorCallback)callback;


/**
 * 获取房间内所有的人员列表
 *
 */
- (NSArray<NSString *> *)getUserInfoList;


/// 获取登录id
- (NSString *)loginUserId;


/// 接受当前通话
- (void)accept;

/// 拒绝当前通话
- (void)reject;

/// 主动挂断通话
- (void)hangup;

///开启远程用户视频渲染
- (void)startRemoteView:(NSString *)userId view:(UIView *)view
NS_SWIFT_NAME(startRemoteView(userId:view:));

///关闭远程用户视频渲染
- (void)stopRemoteView:(NSString *)userId
NS_SWIFT_NAME(stopRemoteView(userId:));

///打开摄像头
- (void)openCamera:(BOOL)frontCamera view:(UIView *)view
NS_SWIFT_NAME(openCamera(frontCamera:view:));

///关闭摄像头
- (void)closeCamara;

///切换摄像头
- (void)switchCamera:(BOOL)frontCamera;

///静麦操作
- (void)setMicMute:(BOOL)isMute;

///静音操作
- (void)setRemoteAudioMute:(BOOL)isMute;

///免提操作
- (void)setHandsFree:(BOOL)isHandsFree;

@end



NS_ASSUME_NONNULL_END
