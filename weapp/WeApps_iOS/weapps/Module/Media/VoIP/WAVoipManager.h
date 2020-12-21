//
//  WAVoipManager.h
//  weapps
//
//  Created by tommywwang on 2020/9/10.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WACallbackModel.h"
#import "TRTCCallingModel.h"
#import "TRTCCalling.h"


NS_ASSUME_NONNULL_BEGIN

@interface WAVoipManager : WACallbackModel



/// 创建/查找VoIP视频会话承载视图
/// @param userId 用户id
/// @param params 同层渲染视图相对window的位置参数
/// @param webView 承载的webView
/// @param completionHandler 完成回调
- (void)createVoIPViewWithUserId:(NSString *)userId
                            mode:(NSString *)mode
                  devicePosition:(NSString *)devicePosition
                       binderror:(NSString *)binderror
                        position:(NSDictionary *)params
                       inWebView:(WebView *)webView
               completionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler;

/// 加入房间，没有则创建
/// @param roomId 房间号
/// @param roomType video/voice
/// @param muteMicrophone 是否关闭麦克风
/// @param muteEarphone 是否关闭耳机
/// @param completionHandler 完成回调
- (void)joinVoIPChatRoom:(UInt32)roomId
                  userId:(NSString *)userId
                roomType:(NSString *)roomType
          muteMicrophone:(BOOL)muteMicrophone
            muteEarphone:(BOOL)muteEarphone
   withCompletionHandler:(void(^)(BOOL success,
                                  NSDictionary * _Nullable resultDictionary,
                                  NSError * _Nullable error))completionHandler;


/// 退出房间
/// @param completionHandler 完成回调
- (void)exitVoIPChatRoomWithCompletionHandler:(void(^)(BOOL success,
                                                       NSDictionary * _Nullable resultDictionary,
                                                       NSError * _Nullable error))completionHandler;


/// 设置麦克风/耳机静音
/// @param muteMicrophone 麦克风是否静音
/// @param muteEarphone 耳机是否静音
/// @param completionHandler 完成回调
- (void)updateVoIPChatMuteConfig:(BOOL)muteMicrophone
                    muteEarphone:(BOOL)muteEarphone
           withCompletionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler;


/// 开启双人通话，开启后会登录im，才能收到呼叫通知
/// @param enable 是否开启
/// @param completionHandler 完成回调
- (void)setEnable1v1Chat:(BOOL)enable
   withCompletionHandler:(void(^)(BOOL success,
                                  NSDictionary * _Nullable resultDictionary,
                                  NSError * _Nullable error))completionHandler;


/// 订阅视频画面成员
/// @param members memberIds
/// @param completionHandler 完成回调
- (void)subscribeVoIPVideoMembers:(NSArray<NSString *>*)members
            withCompletionHandler:(void(^)(BOOL success,
                                           NSDictionary * _Nullable resultDictionary,
                                           NSError * _Nullable error))completionHandler;


/// 加入（创建）双人通话
/// @param caller 呼叫着
/// @param listener 接听者
/// @param roomeType 房间类型video/voice
/// @param disableSwitchVoice 是否允许切换到语音通话
/// @param completionHandler 完成回调
- (void)start1v1ChatRoomByCaller:(TRTCCallingUserModel *)caller
                     toListenner:(TRTCCallingUserModel *)listener
                    withRoomType:(NSString *)roomeType
              disableSwitchVoice:(BOOL)disableSwitchVoice
           withCompletionHandler:(void(^)(BOOL success,
                                          NSDictionary * _Nullable resultDictionary,
                                          NSError * _Nullable error))completionHandler;

///  app挂死后收到远程通知需要调用此接口唤起接听界面
- (void)onReceiveRemoteCallAPNs:(NSDictionary *)userInfo;


- (void)webView:(WebView *)webView onVoIPVideoMembersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offVoIPVideoMembersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onVoIPChatSpeakersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offVoIPChatSpeakersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onVoIPChatMembersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offVoIPChatMembersChangedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView onVoIPChatInterruptedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView offVoIPChatInterruptedCallback:(NSString *)callback;

@end


NS_ASSUME_NONNULL_END
