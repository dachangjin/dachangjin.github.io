//
//  AudioCategoryModel.h
//  AudioSessionTest
//
//  Created by xuepingwu on 17/2/20.
//  Copyright © 2017年 czh. All rights reserved.
//
#import <Foundation/Foundation.h>
//这里只定义几种常用的，够用即可。如果需要新增，得发邮件申请，得改音频类型管理器代码。
typedef enum QQAudioSessionCategory
{
    QQAudioSessionStart = 0,
    QQAudioSessionPlayMusicSolo = 1,                //播放音乐，打断
    QQAudioSessionPlayMusicMix,                     //播放音乐，混合播放
    QQAudioSessionPlayMusicSoloAmbient,             //播放音乐，打断播放，静音键控制
    QQAudioSessionPlayVideoSolo,                    //播放视频，打断
    QQAudioSessionPlayVideoMixMute,                 //静音播放视频，混合
    QQAudioSessionPlayVoiceSoloAmbient,             //播放声音，打断播放，静音键控制，不需要恢复
    QQAudioSessionPlayVoiceSpeaker,                 //播放语音，打断，默认扬声器
    QQAudioSessionPlayVoiceReceiver,                //播放语音，打断，默认听筒
    QQAudioSessionPlayAndRecordVideoSolo,           //录制视频，打断，默认扬声器
    QQAudioSessionPlayAndRecordVideoMixSpeaker,     //录制视频，混合录制，默认扬声器
    QQAudioSessionRecordVoice,                      //录制语音，非“iphone5  ios7.0-7.0.3系统”
    QQAudioSessionWebView,                          //webView音频模式
    QQAudioSessionAVChat,                           //音视频通话中，媒体音量
    QQAudioSessionAVVoiceChat,                      //音视频通话中，通话音量
    QQAudioSessionDeviceChat,                       //智能设备通话中
    QQAudioSessionPlayAudioBackGroundMixMute,       //后台静音播放声音，混合
    QQAudioSessionPlayVoiceAmbient,                 //播放声音，混合，静音键控制
    QQAudioSessionEnd                               //end
}QQAudioSessionCategory;
typedef enum QQInterruptStateCategory
{
    QQInterruptNone = 0,                    //未被打断
    QQInterruptByInner = 1,                 //被内部打断
    QQInterruptByOuter = 2,                 //被外部打断
}QQInterruptStateCategory;
typedef enum QQAVInteruptPriority
{
    QQAVInteruptPriorityStart = 0,
    QQAVInteruptPriorityPlay,                 //播放
    QQAVInteruptPriorityRecord,               //录制
    QQAVInteruptPriorityChat,                 //音视频通话
    QQAVInteruptPriorityEnd
}QQAVInteruptPriority;
typedef enum QQAVSilentCategory
{
    QQAVSilentCategoryControll = 0,                 //受静音控制
    QQAVSilentCategoryNoControll = 1,               //不受静音控制
    QQAVSilentCategoryBothFine = 2,                 //都可以
}QQAVSilentCategory;
@protocol QQAudioSessionManagerDelegate;
@interface AudioCategoryModel : NSObject
/*
 参数说明：
 category:参考QQAudioSessionCategory的定义
 interruptPriority:打断优先级，分为3级。音视频通话，音视频录制，音视频播放分别为3，2，1
 businessDelegate:如果category为非混合模式，则businessDelegate不能为空，并且delegate需要实现onAudioSessionActive，onIntterruptBegin。混合模式可以传nil
 */
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate;
/*
 参数说明：
 needRecovery:如果需要恢复调此函数，默认为NO。
 */
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate
                            needRecovery:(BOOL)needRecovery;
/*
 参数说明：
 needRecovery:如果需要恢复调此函数，默认为NO。
 */
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate
                            needRecovery:(BOOL)needRecovery
                          canBackground:(BOOL)canBackground;
-(void)setInterruptState:(QQInterruptStateCategory)interruptState;
-(BOOL)isInterrupting;
@property(nonatomic,assign,readonly)QQAudioSessionCategory qAudioSessionCategory;        //QQ音频类型，700版本上线后若新增，需要申请
@property(nonatomic,assign,readonly)QQAVInteruptPriority  interruptPriority;             //打断优先级，分为3级。音视频通话，音视频录制，音视频播放分别为3，2，1
@property(nonatomic,strong)NSString *businessName;                                       //业务名称
@property(nonatomic,weak,readonly)id<QQAudioSessionManagerDelegate> businessDelegate;    //业务指针
@property(nonatomic,assign,readonly)int64_t businessDelegatePtr;                         //业务指针
@property(nonatomic,assign,readonly)BOOL bVoice;                                         //是否声音，YES.声音 NO.视频
@property(nonatomic,assign,readonly)BOOL mix;                                            //是否混合播放
@property(nonatomic,assign,readonly)QQAVSilentCategory silentControll;                   //静音键控制
@property(nonatomic,assign,readonly)QQInterruptStateCategory  interruptState;            //被打断的状态
@property(nonatomic,assign,readonly)BOOL canInterrptOthers;                              //能否打断别人
@property(nonatomic,assign)BOOL needRecovery;                                            //是否需要恢复，需要监控deactive通知和第三方APP释放audioSession通知。
@property(nonatomic,assign)BOOL autoEarPhoneSwitchSpeakerAndReceive;                     //耳机自动切换扬声器和听筒，主要针对playAndRecord模式，默认为NO
@property(nonatomic,assign)BOOL keepAudioSessionCategoryWhenDeativeWithSystem;           //恢复第三方音频时是否重置为playbackmix模式
@property(nonatomic,assign)BOOL canBackground;                                           //是否支持后台播放或录制
@end
