//
//  AudioCategoryModel.m
//  AudioSessionTest
//
//  Created by xuepingwu on 17/2/20.
//  Copyright © 2017年 czh. All rights reserved.
//
#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif
#import "AudioCategoryModel.h"
#ifndef MODULE_IMPB_RICHMEDIA
#define MODULE_IMPB_RICHMEDIA "IMPB_RichMedia"
#endif
@implementation AudioCategoryModel
-(void)dealloc
{
    _businessName = nil;
}
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate
{
    return [[AudioCategoryModel alloc]initWithCategory:category interruptPriority:priority businessName:NSStringFromClass([(NSObject*)businessDelegate class]) businessDelegate:businessDelegate];
}
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate
                            needRecovery:(BOOL)needRecovery
{
    AudioCategoryModel *model = [AudioCategoryModel createWithCategory:category interruptPriority:priority businessDelegate:businessDelegate];
    model.needRecovery = needRecovery;
    return model;
}
+(AudioCategoryModel*)createWithCategory:(QQAudioSessionCategory)category
                       interruptPriority:(QQAVInteruptPriority)priority
                        businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate
                            needRecovery:(BOOL)needRecovery
                           canBackground:(BOOL)canBackground
{
    AudioCategoryModel *model = [AudioCategoryModel createWithCategory:category interruptPriority:priority businessDelegate:businessDelegate];
    model.needRecovery = needRecovery;
    model.canBackground = canBackground;
    return model;
}
-(id)initWithCategory:(QQAudioSessionCategory)category
    interruptPriority:(QQAVInteruptPriority)priority
         businessName:(NSString*)businessName
     businessDelegate:(id<QQAudioSessionManagerDelegate>)businessDelegate;
{
    if(self = [super init])
    {
        [self setQAudioSessionCategory:category];
        _interruptPriority = priority;
        _businessName = [businessName copy];
        _businessDelegate = businessDelegate;
        _businessDelegatePtr = (unsigned long long)businessDelegate;
        _interruptState = QQInterruptNone;
        
        assert(_qAudioSessionCategory > QQAudioSessionStart && _qAudioSessionCategory < QQAudioSessionEnd);
        assert(_interruptPriority > QQAVInteruptPriorityStart && _interruptPriority < QQAVInteruptPriorityEnd);
        assert(self.mix || self.businessDelegate);//如果category为非混合模式，则businessDelegate不能为空，并且delegate需要实现onAudioSessionActive，onIntterruptBegin。
        //检查恢复参数和混合参数
//        if(self.needRecovery)
//        {
//            assert([(NSObject*)self.businessDelegate respondsToSelector:@selector(onAudioSessionDeactive)]&&[(NSObject*)self.businessDelegate respondsToSelector:@selector(onIntterruptEnd)]);
//        }
        //如果delegate非空，则需要处理打断
//        if(self.businessDelegate)
//        {
            //若不是混合模式，传入delegate必须实现这两个方法
//            assert([(NSObject*)self.businessDelegate respondsToSelector:@selector(onAudioSessionActive)]&&[(NSObject*)self.businessDelegate respondsToSelector:@selector(onIntterruptBegin)]);
//        }
        self.needRecovery = NO;
        self.keepAudioSessionCategoryWhenDeativeWithSystem = NO;
    }
    return self;
}
/*
 参见 enum QQAudioSessionCategory
 */
-(void)setQAudioSessionCategory:(QQAudioSessionCategory)qAudioSessionCategory
{
    _qAudioSessionCategory = qAudioSessionCategory;
    switch (qAudioSessionCategory) {
        case QQAudioSessionPlayMusicSolo:
        {
            _bVoice = YES;
            _needRecovery = YES;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayMusicMix:
        {
            _bVoice = YES;
            _needRecovery = YES;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayVoiceAmbient:
        {
            _bVoice = YES;
            _needRecovery = YES;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayMusicSoloAmbient:
        {
            _bVoice = YES;
            _needRecovery = YES;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayVoiceSoloAmbient:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayVideoSolo:
        {
            _bVoice = NO;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayVideoMixMute:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryBothFine;
            _canInterrptOthers = NO;
        }
            break;
        case QQAudioSessionPlayAudioBackGroundMixMute:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryBothFine;
            _canInterrptOthers = NO;
        }
            break;
        case QQAudioSessionPlayVoiceSpeaker:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = NO;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayVoiceReceiver:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = NO;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayAndRecordVideoSolo:
        {
            _bVoice = NO;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionPlayAndRecordVideoMixSpeaker:
        {
            _bVoice = NO;
            _needRecovery = NO;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive = YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionRecordVoice:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = NO;
            self.autoEarPhoneSwitchSpeakerAndReceive = NO;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionWebView:
        {
            _bVoice = YES;
            _needRecovery = NO;
            _mix = YES;
            self.autoEarPhoneSwitchSpeakerAndReceive =YES;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = NO;
        }
            break;
        case QQAudioSessionAVChat:
        {
            _bVoice = NO;
            _needRecovery = YES;
            _mix = NO;
            _autoEarPhoneSwitchSpeakerAndReceive = NO;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        case QQAudioSessionDeviceChat:
        {
            _bVoice = NO;
            _needRecovery = YES;
            _mix = NO;
            _autoEarPhoneSwitchSpeakerAndReceive = NO;
            _silentControll = QQAVSilentCategoryNoControll;
            _canInterrptOthers = YES;
        }
            break;
        default:
            break;
    }
}
-(void)setInterruptState:(QQInterruptStateCategory)interruptState
{
    _interruptState = interruptState;
}
-(BOOL)isInterrupting
{
    return _interruptState > QQInterruptNone;
}
-(NSString*)description
{
    NSString *string = [NSString stringWithFormat:@"qAudioSessionCategory:%d,interruptPriority:%d,businessName:%@,businessDelegate:%p,bVoice:%d,needRecovery:%d,mix:%d,autoEarPhoneSwitchSpeakerAndReceive:%d,silentControll:%d,interuptState:%d",_qAudioSessionCategory,_interruptPriority,_businessName,_businessDelegate,_bVoice,_needRecovery,_mix,_autoEarPhoneSwitchSpeakerAndReceive,_silentControll,_interruptState];
    return string;
}
@end
