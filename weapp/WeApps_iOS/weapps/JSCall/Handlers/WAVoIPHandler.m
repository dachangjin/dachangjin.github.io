//
//  WAVoIPHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/10.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVoIPHandler.h"
#import "Weapps.h"

kSELString(createVoIPRoom)
kSELString(updateVoIPChatMuteConfig)
kSELString(subscribeVoIPVideoMembers)
kSELString(setEnable1v1Chat)
kSELString(onVoIPVideoMembersChanged)
kSELString(onVoIPChatSpeakersChanged)
kSELString(onVoIPChatMembersChanged)
kSELString(onVoIPChatInterrupted)
kSELString(offVoIPVideoMembersChanged)
kSELString(offVoIPChatSpeakersChanged)
kSELString(offVoIPChatMembersChanged)
kSELString(offVoIPChatInterrupted)
kSELString(joinVoIPChat)
kSELString(join1v1Chat)
kSELString(exitVoIPChat)


@implementation WAVoIPHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createVoIPRoom,
            updateVoIPChatMuteConfig,
            subscribeVoIPVideoMembers,
            setEnable1v1Chat,
            onVoIPVideoMembersChanged,
            onVoIPChatSpeakersChanged,
            onVoIPChatMembersChanged,
            onVoIPChatInterrupted,
            offVoIPVideoMembersChanged,
            offVoIPChatSpeakersChanged,
            offVoIPChatMembersChanged,
            offVoIPChatInterrupted,
            joinVoIPChat,
            join1v1Chat,
            exitVoIPChat
        ];
    }
    return methods;
}

JS_API(createVoIPRoom){
    kBeginCheck
    kCheck([NSDictionary class], @"position", NO)
    kEndCheck([NSString class], @"userId", NO)
    
    NSString *userId = event.args[@"userId"];
    NSString *mode = event.args[@"mode"] ?: @"camera";
    if (![@[@"camera", @"video"] containsObject:mode]) {
        kFailWithErrorWithReturn(createVoIPRoom, -1, @"invalid parameter mode")
    }
    NSString *devicePosition = event.args[@"devicePosition"] ?: @"front";
    if (![@[@"front", @"back"] containsObject:devicePosition]) {
        kFailWithErrorWithReturn(createVoIPRoom, -1, @"invalid parameter devicePosition")
    }
    NSString *errorCallback = event.args[@"binderror"];
    [[Weapps sharedApps].VoIPManager createVoIPViewWithUserId:userId
                                                         mode:mode
                                               devicePosition:devicePosition
                                                    binderror:errorCallback
                                                     position:event.args[@"position"]
                                                    inWebView:event.webView
                                            completionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}


JS_API(updateVoIPChatMuteConfig){
    kBeginCheck
    kCheck([NSDictionary class], @"muteConfig", NO)
    kCheckInDict(event.args[@"muteConfig"], [NSNumber class], @"muteMicrophone", YES)
    kEndCheckInDict(event.args[@"muteConfig"], [NSNumber class], @"muteEarphone", YES)
    
    BOOL muteMicrophone = false;
    if ([event.args[@"muteConfig"][@"muteMicrophone"] boolValue]) {
        muteMicrophone = YES;
    }
    BOOL muteEarphone = false;
    if ([event.args[@"muteConfig"][@"muteEarphone"] boolValue]) {
        muteMicrophone = YES;
    }
    [[Weapps sharedApps].VoIPManager updateVoIPChatMuteConfig:muteMicrophone
                                                 muteEarphone:muteEarphone
                                        withCompletionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(subscribeVoIPVideoMembers){
    kBeginCheck
    kEndCheck([NSArray class], @"openIdList", NO)
    
    NSArray *openIdList = event.args[@"openIdList"];
    [[Weapps sharedApps].VoIPManager subscribeVoIPVideoMembers:openIdList
                                         withCompletionHandler:^(BOOL success,
                                                                 NSDictionary * _Nullable resultDictionary,
                                                                 NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setEnable1v1Chat){
    kBeginCheck
    kEndChecIsBoonlean(@"enable", NO)
    //其他两个参数目前不支持（ignoreSelfVersion、minWindowType）https://developers.weixin.qq.com/miniprogram/dev/api/media/voip/wx.setEnable1v1Chat.html
    BOOL enable = [event.args[@"enable"] boolValue];
    [[Weapps sharedApps].VoIPManager setEnable1v1Chat:enable
                                withCompletionHandler:^(BOOL success,
                                                        NSDictionary * _Nullable resultDictionary,
                                                        NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onVoIPVideoMembersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
           onVoIPVideoMembersChangedCallback:event.callbacak];
    return @"";
}

JS_API(onVoIPChatSpeakersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
           onVoIPChatSpeakersChangedCallback:event.callbacak];
    return @"";
}

JS_API(onVoIPChatMembersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
            onVoIPChatMembersChangedCallback:event.callbacak];
    return @"";
}

JS_API(onVoIPChatInterrupted){
    [[Weapps sharedApps].VoIPManager webView:event.webView
               onVoIPChatInterruptedCallback:event.callbacak];
    return @"";
}

JS_API(offVoIPVideoMembersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
          offVoIPVideoMembersChangedCallback:event.callbacak];
    return @"";
}

JS_API(offVoIPChatSpeakersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
          offVoIPChatSpeakersChangedCallback:event.callbacak];
    return @"";
}

JS_API(offVoIPChatMembersChanged){
    [[Weapps sharedApps].VoIPManager webView:event.webView
           offVoIPChatMembersChangedCallback:event.callbacak];
    return @"";
}

JS_API(offVoIPChatInterrupted){
    [[Weapps sharedApps].VoIPManager webView:event.webView
              offVoIPChatInterruptedCallback:event.callbacak];
    return @"";
}

JS_API(joinVoIPChat){
    kBeginCheck
    kCheck([NSString class], @"roomType", YES)
    kCheck([NSString class], @"groupId", NO)
    kCheck([NSString class], @"userId", NO)
    kEndCheck([NSDictionary class], @"muteConfig", YES)
    UInt32 roomId = [event.args[@"groupId"] unsignedIntValue];
    NSString *roomType = @"voice";
    if (event.args[@"roomType"]) {
        roomType = event.args[@"roomType"];
    }
    NSArray *roomTypes = @[@"voice", @"video"];
    if (![roomTypes containsObject:roomType]) {
        kFailWithErrorWithReturn(joinVoIPChat, -1, @"roomType is invalid")
    }
    NSDictionary *config = event.args[@"muteConfig"];
    BOOL muteMic = NO;
    BOOL muteEarphone = NO;
    if (config) {
        if ([config[@"muteMicrophone"] boolValue]) {
            muteMic = YES;
        }
        if ([config[@"muteEarphone"] boolValue]) {
            muteEarphone = YES;
        }
    }
    [[Weapps sharedApps].VoIPManager joinVoIPChatRoom:roomId
                                               userId:event.args[@"userId"]
                                             roomType:roomType
                                       muteMicrophone:muteMic
                                         muteEarphone:muteEarphone
                                withCompletionHandler:^(BOOL success,
                                                        NSDictionary * _Nullable resultDictionary,
                                                        NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(join1v1Chat){
    kBeginCheck
    kCheck([NSDictionary class], @"caller", NO)
    kCheck([NSDictionary class], @"listener", NO)
    kCheckIsBoolean([NSNumber class], @"disableSwitchVoice", YES, YES)
    kCheckInDict(event.args[@"caller"], [NSString class], @"nickname", NO)
    kCheckInDict(event.args[@"caller"], [NSString class], @"headImage", YES)
    kCheckInDict(event.args[@"caller"], [NSString class], @"openid", NO)
    kCheckInDict(event.args[@"listener"], [NSString class], @"nickname", NO)
    kCheckInDict(event.args[@"listener"], [NSString class], @"headImage", YES)
    kCheckInDict(event.args[@"listener"], [NSString class], @"openid", NO)
    kEndCheck([NSString class], @"roomType", YES)
    //参数不支持（minWindowType、ignoreTargetVersion、ignoreSelfVersion）https://developers.weixin.qq.com/miniprogram/dev/api/media/voip/wx.join1v1Chat.html
    NSString *roomType = @"video";
    if (event.args[@"roomType"]) {
        roomType = event.args[@"roomType"];
    }
    NSArray *roomTypes = @[@"voice", @"video"];
    if (![roomTypes containsObject:roomType]) {
        kFailWithErrorWithReturn(joinVoIPChat, -1, @"roomType is invalid")
    }
    TRTCCallingUserModel *caller = [[TRTCCallingUserModel alloc] initWithDict:event.args[@"caller"]];
    TRTCCallingUserModel *listener = [[TRTCCallingUserModel alloc] initWithDict:event.args[@"listener"]];
    BOOL disableSwitchVoice = NO;
    if ([event.args[@"disableSwitchVoice"] boolValue]) {
        disableSwitchVoice = YES;
    }
    [[Weapps sharedApps].VoIPManager start1v1ChatRoomByCaller:caller
                                                  toListenner:listener
                                                 withRoomType:roomType
                                           disableSwitchVoice:disableSwitchVoice
                                        withCompletionHandler:^(BOOL success,
                                                                NSDictionary * _Nullable resultDictionary,
                                                                NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(exitVoIPChat){
    [[Weapps sharedApps].VoIPManager exitVoIPChatRoomWithCompletionHandler:^(BOOL success,
                                                                             NSDictionary * _Nullable resultDictionary,
                                                                             NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(resultDictionary)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

@end
