//
//  QQAudioSessionManager.h
//  QQMSFContact
//
//  Created by xuepingwu on 17-3-2.
//  Copyright © 2020 tencent. All rights reserved.
//
//
#import <Foundation/Foundation.h>
#import "AudioCategoryModel.h"
#define ACTICE_CATEGORY_MODEL_ERROR_CODE_LOW_PRIORITY 1000
#define ACTICE_CATEGORY_MODEL_ERROR_INVALID_CATRGORY 1001
extern NSString *const ActiveCategoryModelErrorDomain;
@protocol QQAudioSessionManagerDelegate <NSObject>
@required
//被内部业务打断回调
-(void)onAudioSessionActive;
//被第三方APP打断回调
-(void)onIntterruptBegin;
@optional
//被内部业务恢复回调
-(void)onAudioSessionDeactive;
//释放音频使用权，恢复第三方app回调
-(void)onDeactiveWithSystem;
//被第三方app恢复回调
-(void)onIntterruptEnd;
@end
@protocol QQAudioSessionManagerWebViewDelegate <NSObject>
@required
//被内部业务打断回调
-(BOOL)webViewOnTop;
@end
/*
    QQAudioSessionManager
    音频管理器，处理内部，外部中断与恢复，设置音频行为
 */
@class AudioCategoryModel;
@interface QQAudioSessionManager : NSObject
@property (nonatomic,readonly,assign) NSTimeInterval mediaServicesLostTime;
@property (nonatomic,readonly,assign) NSTimeInterval mediaServicesResetTime;
@property (atomic,assign) BOOL deactiveWhenBackgroundDpc;
@property (atomic,assign) BOOL interruptOtherAudioWhenBackgroundDpc;
@property (nonatomic,weak) id<QQAudioSessionManagerWebViewDelegate>delegate;
+(QQAudioSessionManager*)getInstance;
//外部调用接口
//第三方音乐是否在播放
-(BOOL)getOtherAppIsPlayingFlag;
//尽量不要调用，用activeCategoryModel替代。请求权限，仅判断优先级。
-(BOOL)requestDeviceWithModel:(AudioCategoryModel*)categoryModel;
//是否有声音正在播放
-(BOOL)isAudioSessionIdle;
//判断优先级，设置音频行为,激活，中断，设置输出设备
-(BOOL)activeCategoryModel:(AudioCategoryModel*)categoryModel error:(NSError **)error;
//业务释放权限
-(void)deactive:(id<QQAudioSessionManagerDelegate>)obj delay:(BOOL)delay notifyOtherApp:(BOOL)notifyOtherApp;
@end
 
