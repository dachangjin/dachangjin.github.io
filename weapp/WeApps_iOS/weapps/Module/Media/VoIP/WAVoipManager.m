//
//  WAVoipManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/10.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVoipManager.h"
#import "AppConfig.h"
#import "TRTCCalling.h"
#import "TRTCCalling+Signal.h"
#import "WKWebViewHelper.h"
#import "GenerateTestUserSig.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "TRTCCallingHeader.h"
#import "JSONHelper.h"
#import "QMUITips.h"
#import "WAContainerView.h"

#define kCodeNoError 0
#define kUserId @"123456"
#define kUserSig @""

@interface WAVoipManager() <TRTCCallingDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *VoIPVideoMembersChangedCallbacks;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *VoIPChatSpeakersChangedCallbacks;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *VoIPChatMembersChangedCallbacks;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSMutableArray<NSString *> *> *VoIPChatInterruptedCallbacks;
@property (nonatomic, strong) NSMutableArray <NSString *>* videoOnMembers;
@property (nonatomic, strong) NSMutableArray <NSString *>* audioOnMembers;
@property (nonatomic, assign) BOOL isInRoom;
@property (nonatomic, strong) TRTCCalling *calling;

@end

@implementation WAVoipManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _VoIPChatInterruptedCallbacks = [NSMutableDictionary dictionary];
        _VoIPChatMembersChangedCallbacks = [NSMutableDictionary dictionary];
        _VoIPChatSpeakersChangedCallbacks = [NSMutableDictionary dictionary];
        _VoIPVideoMembersChangedCallbacks = [NSMutableDictionary dictionary];
        _videoOnMembers = [NSMutableArray array];
        _audioOnMembers = [NSMutableArray array];
        [self.calling addDelegate:self];
    }
    return self;
}


- (TRTCCalling *)calling
{
    return [TRTCCalling shareInstance];
}

- (void)createVoIPViewWithUserId:(NSString *)userId
                            mode:(NSString *)mode
                  devicePosition:(NSString *)devicePosition
                       binderror:(NSString *)binderror
                        position:(NSDictionary *)position
                       inWebView:(WebView *)webView
               completionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler
{
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webView
                                                           withParams:position];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createVoIPView" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find VoIPView container in webView"
            }]);
        }
        if (binderror) {
            [WKWebViewHelper successWithResultData:@{
                @"errCode"  : @(-1),
                @"errMsg"   : @"can not find VoIPView container in webView"
            }
                                           webView:webView
                                          callback:binderror];
        }
        return;
    }
    WAContainerView *view = [[WAContainerView alloc] initWithFrame:container.bounds];
    //自动适配camera DOM节点的大小
    container.boundsChangeBlock = ^(CGRect rect) {
        view.frame = rect;
    };
    [container insertSubview:view atIndex:0];
    if (kStringEqualToString(@"camera", mode)) {
        [self.calling openCamera:YES view:view];
        if (kStringEqualToString(devicePosition, @"back")) {
            [self.calling switchCamera:NO];
        }
    } else {
        [self.calling startRemoteView:userId view:view];
    }
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

- (void)joinVoIPChatRoom:(UInt32)roomId
                  userId:(NSString *)userId
                roomType:(NSString *)roomType
          muteMicrophone:(BOOL)muteMicrophone
            muteEarphone:(BOOL)muteEarphone
   withCompletionHandler:(void(^)(BOOL success,
                                  NSDictionary * _Nullable resultDictionary,
                                  NSError * _Nullable error))completionHandler
{
    @weakify(self)
    [self.calling enterRoom:roomId
               withSdkAppId:TRTCSDK_APP_ID
                     userId:userId
                    userSig:[GenerateTestUserSig genTestUserSig:userId]
                   callback:^(NSInteger code, NSString * _Nullable message) {
        @strongify(self)
        if (code == kCodeNoError) {
            NSArray *list = [self.calling getUserInfoList];
            if (completionHandler) {
                completionHandler(YES, @{
                @"openIdList"   : list,
                @"errCode"      : @(kCodeNoError),
                @"errMsg"       : @"sucess"
                                   } ,nil);
            }
        } else {
            if (completionHandler) {
                completionHandler(NO, nil, [NSError errorWithDomain:@"joinVoIPChat" code:code userInfo:@{
                    NSLocalizedDescriptionKey: message ?: @"fail to join VoIP chat"
                }]);
            }
        }
    }];
}


- (void)exitVoIPChatRoomWithCompletionHandler:(void(^)(BOOL success,
                                                       NSDictionary * _Nullable resultDictionary,
                                                       NSError * _Nullable error))completionHandler
{
    [self.calling leaveRoom:^(NSInteger code, NSString * _Nullable message) {
        if (completionHandler) {
            if (code == kCodeNoError) {
                completionHandler(YES, nil, nil);
            } else {
                completionHandler(NO, nil, [NSError errorWithDomain:@"exitVoIPChat" code:code userInfo:@{
                    NSLocalizedDescriptionKey: message?: @"unknown error"
                }]);
            }
        }
    }];
}


- (void)updateVoIPChatMuteConfig:(BOOL)muteMicrophone
                    muteEarphone:(BOOL)muteEarphone
           withCompletionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler
{
    [self.calling setRemoteAudioMute:muteEarphone];
    [self.calling setMicMute:muteMicrophone];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


- (void)setEnable1v1Chat:(BOOL)enable
   withCompletionHandler:(void(^)(BOOL success,
                                  NSDictionary * _Nullable resultDictionary,
                                  NSError * _Nullable error))completionHandler
{
    //TODO: 登录IM，可收到推送提醒接听
    [self.calling login:TRTCSDK_APP_ID
                   user:kUserId
                userSig:kUserSig
                success:^{
        if (completionHandler) {
            completionHandler(YES, nil, nil);
        }
    } failed:^(NSInteger code, NSString * _Nonnull des) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"setEnable1v1" code:code userInfo:@{
                NSLocalizedDescriptionKey: des?: @"fail to login to im"
            }]);
        }
    }];
}


- (void)subscribeVoIPVideoMembers:(NSArray<NSString *>*)members
            withCompletionHandler:(void(^)(BOOL success,
                                           NSDictionary * _Nullable resultDictionary,
                                           NSError * _Nullable error))completionHandler
{
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}


- (void)start1v1ChatRoomByCaller:(TRTCCallingUserModel *)caller
                     toListenner:(TRTCCallingUserModel *)listener
                    withRoomType:(NSString *)roomeType
              disableSwitchVoice:(BOOL)disableSwitchVoice
           withCompletionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler
{
    //先登录im，然后给接收者发送呼叫提醒
    [self.calling login:TRTCSDK_APP_ID
                   user:caller.userId
                userSig:[GenerateTestUserSig genTestUserSig:caller.userId]
                success:^{
       //登录成功后发起呼叫
        [self.calling call:caller.userId type:[roomeType isEqualToString:@"video"] ? CallType_Video : CallType_Audio];
        if (completionHandler) {
            completionHandler(YES, nil, nil);
        }
    } failed:^(NSInteger code, NSString * _Nonnull des) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"join1v1Chat" code:code userInfo:@{
                NSLocalizedDescriptionKey: des?: @"fail to login to im"
            }]);
        }
    }];
}

- (void)onReceiveRemoteCallAPNs:(NSDictionary *)userInfo
{
    // 收到推送普通信息推送（普通消息推送设置代码请参考 TUIMessageController -> sendMessage）
    //普通消息推送格式（C2C）：
    //@"ext" :
    //@"{\"entity\":{\"action\":1,\"chatType\":1,\"content\":\"Hhh\",\"sendTime\":0,\"sender\":\"2019\",\"version\":1}}"
    //普通消息推送格式（Group）：
    //@"ext"
    //@"{\"entity\":{\"action\":1,\"chatType\":2,\"content\":\"Hhh\",\"sendTime\":0,\"sender\":\"@TGS#1PWYXLTGA\",\"version\":1}}"
    
    // 收到推送音视频推送（音视频推送设置代码请参考 TUICall+Signal -> sendAPNsForCall）
    //音视频通话推送格式（C2C）：
    //@"ext" :
    //@"{\"entity\":{\"action\":2,\"chatType\":1,\"content\":\"{\\\"action\\\":1,\\\"call_id\\\":\\\"144115224193193423-1595225880-515228569\\\",\\\"call_type\\\":1,\\\"code\\\":0,\\\"duration\\\":0,\\\"invited_list\\\":[\\\"10457\\\"],\\\"room_id\\\":1688911421,\\\"timeout\\\":30,\\\"timestamp\\\":0,\\\"version\\\":4}\",\"sendTime\":1595225881,\"sender\":\"2019\",\"version\":1}}"
    //音视频通话推送格式（Group）：
    //@"ext"
    //@"{\"entity\":{\"action\":2,\"chatType\":2,\"content\":\"{\\\"action\\\":1,\\\"call_id\\\":\\\"144115212826565047-1595506130-2098177837\\\",\\\"call_type\\\":2,\\\"code\\\":0,\\\"duration\\\":0,\\\"group_id\\\":\\\"@TGS#1BUBQNTGS\\\",\\\"invited_list\\\":[\\\"10457\\\"],\\\"room_id\\\":1658793276,\\\"timeout\\\":30,\\\"timestamp\\\":0,\\\"version\\\":4}\",\"sendTime\":1595506130,\"sender\":\"vinson1\",\"version\":1}}"
    NSDictionary *extParam = [JSONHelper exchangeStringToDictionary:userInfo[@"ext"]];
    NSDictionary *entity = extParam[@"entity"];
    if (!entity) {
        return;
    }
    // 业务，action : 1 普通文本推送；2 音视频通话推送
    NSString *action = entity[@"action"];
    if (!action) {
        return;
    }
    // 聊天类型，chatType : 1 单聊；2 群聊
    NSString *chatType = entity[@"chatType"];
    if (!chatType) {
        return;
    }
    // action : 1 普通消息推送
    if ([action intValue] == APNS_BUSINESS_NORMAL_MSG) {
        if ([chatType intValue] == 1) {   //C2C
//            self.userID = entity[@"sender"];
        } else if ([chatType intValue] == 2) { //Group
//            self.groupID = entity[@"sender"];
        }
        if ([[V2TIMManager sharedInstance] getLoginStatus] == V2TIM_STATUS_LOGINED) {
//            [self onReceiveNomalMsgAPNs];
        }
    }
    // action : 2 音视频通话推送
    else if ([action intValue] == APNS_BUSINESS_CALL) {
        // 单聊中的音视频邀请推送不需处理，APP 启动后，TUIkit 会自动处理
        if ([chatType intValue] == 1) {   //C2C
            return;
        }
        // 内容
        NSDictionary *content = [JSONHelper exchangeStringToDictionary:entity[@"content"]];
        if (!content) {
            return;
        }
        UInt64 sendTime = [entity[@"sendTime"] integerValue];
        uint32_t timeout = [content[@"timeout"] intValue];
        UInt64 curTime = (UInt64)[[NSDate date] timeIntervalSince1970];
        if (curTime - sendTime > timeout) {
            [QMUITips showInfo:@"通话接收超时"];
            return;
        }
        V2TIMSignalingInfo *signalingInfo = [[V2TIMSignalingInfo alloc] init];
        signalingInfo.actionType = (SignalingActionType)[content[@"action"] intValue];
        signalingInfo.inviteID = content[@"call_id"];
        signalingInfo.inviter = entity[@"sender"];
        signalingInfo.inviteeList = content[@"invited_list"];
        signalingInfo.groupID = content[@"group_id"];
        signalingInfo.timeout = timeout;
        signalingInfo.data = [JSONHelper exchengeDictionaryToString:@{
            SIGNALING_EXTRA_KEY_ROOM_ID : content[@"room_id"],
            SIGNALING_EXTRA_KEY_VERSION : content[@"version"],
            SIGNALING_EXTRA_KEY_CALL_TYPE : content[@"call_type"]}];
        if ([[V2TIMManager sharedInstance] getLoginStatus] == V2TIM_STATUS_LOGINED) {
            [self.calling onReceiveGroupCallAPNs:signalingInfo];
        }
    }
}

- (void)onMemberChange
{
    NSArray *list = [self.calling getUserInfoList];
    [self doCallbackInCallbackDict:self.VoIPChatMembersChangedCallbacks andResult:@{
        @"openIdList"   : list,
        @"errCode"      : @(kCodeNoError),
        @"errMsg"       : @"success"
    }];
}

- (void)webView:(WebView *)webView onVoIPVideoMembersChangedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.VoIPVideoMembersChangedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView offVoIPVideoMembersChangedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.VoIPVideoMembersChangedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView onVoIPChatSpeakersChangedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.VoIPChatSpeakersChangedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView offVoIPChatSpeakersChangedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.VoIPChatSpeakersChangedCallbacks callback:callback];
}


- (void)webView:(WebView *)webView onVoIPChatMembersChangedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.VoIPChatMembersChangedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView offVoIPChatMembersChangedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.VoIPChatMembersChangedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView onVoIPChatInterruptedCallback:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.VoIPChatInterruptedCallbacks callback:callback];
}

- (void)webView:(WebView *)webView offVoIPChatInterruptedCallback:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.VoIPChatInterruptedCallbacks callback:callback];
}

#pragma mark - *************************TRTCCallingDelegate********************************
-(void)onError:(int)code msg:(NSString * _Nullable)msg
{
    _isInRoom = NO;
    [self doCallbackInCallbackDict:self.VoIPChatInterruptedCallbacks andResult:@{
        @"errCode"  : @(code),
        @"errMsg"   : msg ?: @"unknown error"
    }];
}

/// 被邀请通话回调 | invitee callback
/// - Parameter userIds: 邀请列表 (invited list)
-(void)onInvited:(NSString *)sponsor
         userIds:(NSArray<NSString *> *)userIds
     isFromGroup:(BOOL)isFromGroup
        callType:(CallType)callType
{
    //TODO: 唤起接听页面
}
   
///// 群聊更新邀请列表回调 | update current inviteeList in group calling
///// - Parameter userIds: 邀请列表 | inviteeList
//-(void)onGroupCallInviteeListUpdate:(NSArray *)userIds
//{
//
//}
   
- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available
{
    if (available) {
        [self.videoOnMembers addObject:userId];
    } else {
        [self.videoOnMembers removeObject:userId];
    }
    [self doCallbackInCallbackDict:self.VoIPVideoMembersChangedCallbacks andResult:@{
        @"openIdList"   : self.videoOnMembers,
        @"errCode"      : @(kCodeNoError),
        @"errMsg"       : @"success"
    }];
}

- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available
{
    if (available) {
        [self.audioOnMembers addObject:userId];
    } else {
        [self.audioOnMembers removeObject:userId];
    }
    [self doCallbackInCallbackDict:self.VoIPChatSpeakersChangedCallbacks andResult:@{
        @"openIdList"   : self.audioOnMembers,
        @"errCode"      : @(kCodeNoError),
        @"errMsg"       : @"success"
    }];
}

/// 进入通话回调 | user enter room callback
/// - Parameter uid: userid
-(void)onUserEnter:(NSString *)uid
{
    [self onMemberChange];

}
   
/// 离开通话回调 | user leave room callback
/// - Parameter uid: userid
-(void)onUserLeave:(NSString *)uid
{
   [self onMemberChange];

}

   
/// 拒绝通话回调-仅邀请者受到通知，其他用户应使用 onUserEnter |
/// reject callback only worked for Sponsor, others should use onUserEnter)
/// - Parameter uid: userid
-(void)onReject:(NSString *)uid
{
    
}
   
/// 无回应回调-仅邀请者受到通知，其他用户应使用 onUserEnter |
/// no response callback only worked for Sponsor, others should use onUserEnter)
/// - Parameter uid: userid
-(void)onNoResp:(NSString *)uid
{
    
}
   
/// 通话占线回调-仅邀请者受到通知，其他用户应使用 onUserEnter |
/// linebusy callback only worked for Sponsor, others should use onUserEnter
/// - Parameter uid: userid
-(void)onLineBusy:(NSString *)uid
{
    
}

/// 当前通话被取消回调 | current call had been canceled callback
-(void)onCallingCancel:(NSString *)uid
{
    
}
   
/// 通话超时的回调 | timeout callback
-(void)onCallingTimeOut
{
    
}
   
/// 通话结束 | end callback
-(void)onCallEnd
{
    _isInRoom = NO;
}



@end
