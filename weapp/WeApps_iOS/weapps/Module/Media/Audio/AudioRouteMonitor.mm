#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "AudioRouteMonitor"
#pragma clang diagnostic pop
//
//  AudioRouteMonitor.m
//  QQMSFContact
//
//  Created by Zhang Random on 13-8-9.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "AudioRouteMonitor.h"
#import <AudioToolBox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <exception>
#import <set>
#import <sys/utsname.h>
typedef std::set<__unsafe_unretained id<AudioRouteChangeProtocol> > listenerSetType;
@interface AudioRouteMonitor ()
{
    listenerSetType _listeners;
    
    //codezip
    NSString* _currentRouteOld;
    NSString* _currentInputDevice;
    NSString* _currentOutputDevice;
//    CZ_DYNAMIC_PROPERTYS_FLAG_VAR
}
@property (nonatomic,strong) NSString* currentRouteOld;
@property (nonatomic,strong) NSString* currentInputDevice;
@property (nonatomic,strong) NSString* currentOutputDevice;
@property (nonatomic,strong) AVAudioSessionRouteDescription *currentRouteDescription;
-(void)routeChange:(NSDictionary*)dic;
-(void)getCurrentDeviceValue;
@end
@implementation AudioRouteMonitor
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
//    if (![[NSThread currentThread] isMainThread])
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Audio session listener call not in main thread",__FUNCTION__);

    NSInteger routeChangeReason = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    self.currentRouteDescription = [AVAudioSession sharedInstance].currentRoute;
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:AVAudioSessionRouteChangeReasonNewDeviceAvailable,Headphone/Line plugged in",__FUNCTION__);
            [self routeChange];
            break;
        }
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:AVAudioSessionRouteChangeReasonOldDeviceUnavailable,Headphone/Line was pulled. Stopping player....",__FUNCTION__);
            [self routeChange];
            break;
        }
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:AVAudioSessionRouteChangeReasonCategoryChange",__FUNCTION__);
            break;
        }
            
        case AVAudioSessionRouteChangeReasonOverride:
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:AVAudioSessionRouteChangeReasonOverride",__FUNCTION__);
            break;
        }
            
    }
}
-(BOOL)isIpod
{
    return [[UIDevice currentDevice].model rangeOfString:@"iPod"].location != NSNotFound;
}
+(AudioRouteMonitor*)getInstance
{
    static AudioRouteMonitor* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [AudioRouteMonitor new];
    });
    return instance;
}
-(id)init
{
    if (self = [super init]) {
        //监控输入输出设备
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:)
                                                     name:AVAudioSessionRouteChangeNotification object:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getCurrentDeviceValue];
        });
    }
    return self;
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(AudioRouteType)getOutputDeviceType:(NSString*)device
{
    if (device.length) {
        if ([device rangeOfString:@"Speaker"].location != NSNotFound)
            return AUDIOROUTETYPE_SPEAKER;
        if ([device rangeOfString:@"Receiver"].location != NSNotFound)
            return AUDIOROUTETYPE_RECEIVER;
    }
    
    return AUDIOROUTETYPE_OTHER;
}
-(NSString*)getDeviceType:(NSArray*)arr
{
    if (arr.count > 0) {
        AVAudioSessionPortDescription* deviceInfo = arr[0];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ;
        return deviceInfo.portType;
    }
    return nil;
}
-(void)getCurrentDeviceValue
{
//    QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, start", __FUNCTION__);
    @synchronized (self) {
        try {
            
            //            //test code
            //            for (AVAudioSessionPortDescription *portDesc in [[[AVAudioSession sharedInstance] currentRoute] outputs ]) {
            //                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:portDesc UID:%s,portDesc portName:%s,portDesc portType:%s,portDesc channels:%s-----",__FUNCTION__,portDesc.UID.UTF8String, portDesc.portName.UTF8String
            //                           , portDesc.portType.UTF8String, CZ_getDescription(portDesc.channels));
            //            }
            
            AVAudioSessionRouteDescription *currentRoute = [AVAudioSession sharedInstance].currentRoute;
            if (currentRoute == nil) {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Error.Get Audio route failed currentRoute == nil",__FUNCTION__);
            }
            else {
                NSArray* inputDevices = currentRoute.inputs;
                NSString *currentInputDevice = [self getDeviceType:inputDevices];
                self.currentInputDevice = currentInputDevice ? [NSString stringWithFormat:@"%s", currentInputDevice.UTF8String] : nil;
                
                NSArray* outputDevices = currentRoute.outputs;
                NSString *currentOutputDevice = [self getDeviceType:outputDevices];
                self.currentOutputDevice = currentOutputDevice ? [NSString stringWithFormat:@"%s", currentOutputDevice.UTF8String] : nil;
                
            }
        } catch (...) {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Error happened in get device value.",__FUNCTION__);
            return;
        }
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Get current output device value:%s",__FUNCTION__,[self.currentOutputDevice UTF8String]);
    }
}
-(void)NotifyRecordDeviceChanged
{
    listenerSetType set = _listeners;
    for(listenerSetType::iterator itor = set.begin(); itor != set.end(); itor++)
    {
        if ([*itor respondsToSelector:@selector(onRecordDeviceChanged)])
            [*itor onRecordDeviceChanged];
    }
}
-(void)NotifyOutputDeviceChanged:(AudioRouteType)type
{
    listenerSetType set = _listeners;
    for(listenerSetType::iterator itor = set.begin(); itor != set.end(); itor++)
    {
        if ([*itor respondsToSelector:@selector(onOutputDeviceChanged:)])
            [*itor onOutputDeviceChanged:type];
    }
}
-(void)routeChange
{
    NSString* lastInputDevice = self.currentInputDevice ? [NSString stringWithFormat:@"%s", self.currentInputDevice.UTF8String] : nil;
    NSString* lastOutDevice = self.currentOutputDevice ? [NSString stringWithFormat:@"%s", self.currentOutputDevice.UTF8String] : nil;
    [self getCurrentDeviceValue];
    
    if (lastInputDevice)
    {
        if (![self.currentInputDevice isEqualToString:lastInputDevice])
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:inputDevice has changed, current inputDevice:%s, lastInputDevice:%s", __FUNCTION__, self.currentInputDevice.UTF8String, lastInputDevice.UTF8String);
            [self NotifyRecordDeviceChanged];
        }
    }
    
    AudioRouteType type = [self getOutputDeviceType:self.currentOutputDevice];
    if (lastOutDevice) {
        if (![lastOutDevice isEqualToString:self.currentOutputDevice])
        {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:outputDevice has changed, current outputDevice:%s, lastOutputDevice:%s", __FUNCTION__, self.currentOutputDevice.UTF8String, lastOutDevice.UTF8String);
            [self NotifyOutputDeviceChanged:type];
        }
    }
}
-(void)addListener:(id<AudioRouteChangeProtocol>)Listener
{
    @synchronized(self)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:addListener:%s, actived count:%lu", __FUNCTION__, [[Listener class] description].UTF8String,_listeners.size());
        if (!Listener)
            return;
        _listeners.insert(Listener);
    }
}
-(void)removeListerner:(id<AudioRouteChangeProtocol>)Listener
{
    @synchronized(self)
    {
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:removeListerner:%s, actived count:%lu", __FUNCTION__, [[Listener class] description].UTF8String, _listeners.size());
        if (Listener)
            _listeners.erase(Listener);
    }
}
-(int)getCurrentOutputType
{
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:Get current output type.", __FUNCTION__);
    if ([AVAudioSession sharedInstance].category == AVAudioSessionCategoryRecord){
        return AUDIOROUTETYPE_RECORDING;
    }
    
    [self getCurrentDeviceValue];
    
    return [self getOutputDeviceType:self.currentOutputDevice];
}
-(BOOL)isSpeakerOn
{
    int currentOutputType = [self getCurrentOutputType];
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:currentOutputType:%d", __FUNCTION__, currentOutputType);
    return (currentOutputType == AUDIOROUTETYPE_SPEAKER);
}
-(BOOL)isTelePhoneCalling{
    CTCallCenter *callCenter = [CTCallCenter new];
    if (callCenter.currentCalls.count > 0) {
        return YES;
    }
    return NO;
}
-(unsigned long)convertCategorytoLong:(NSString *)category
{
    unsigned long longcategory = 0;
    if([category isEqualToString:AVAudioSessionCategoryAmbient])
    {
        longcategory ='ambi';
    }
    else if([category isEqualToString:AVAudioSessionCategorySoloAmbient])
    {
        longcategory ='solo';
    }
    else if([category isEqualToString:AVAudioSessionCategoryPlayback])
    {
        longcategory ='medi';
    }
    else if([category isEqualToString:AVAudioSessionCategoryRecord])
    {
        longcategory ='reca';
    }
    else if([category isEqualToString:AVAudioSessionCategoryPlayAndRecord])
    {
        longcategory ='plar';
    }
    return longcategory;
}
-(NSString *)convertLongtoCategory:(unsigned long)longcategory
{
    NSString *category = nil;
    switch (longcategory) {
        case 'ambi':
            category = AVAudioSessionCategoryAmbient;
            break;
        case 'solo':
            category = AVAudioSessionCategorySoloAmbient;
            break;
        case 'medi':
            category = AVAudioSessionCategoryPlayback;
            break;
        case 'reca':
            category = AVAudioSessionCategoryRecord;
            break;
        case 'plar':
            category = AVAudioSessionCategoryPlayAndRecord;
            break;
            
        default:
            break;
    }
    return category;
}
-(unsigned long)getCurCategory
{
    @synchronized(self)
    {
        unsigned long longcategory = 0;
        NSString *category = [AVAudioSession sharedInstance].category;
        longcategory = [self convertCategorytoLong:category];
        return longcategory;
    }
}
-(void)setVoiceChatMode
{
    NSString *sessionMode = [AVAudioSession sharedInstance].mode;
    if (sessionMode != AVAudioSessionModeVoiceChat) {
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVoiceChat error:nil];
    }
}
-(void)setDefaultMode
{
    NSString *sessionMode = [AVAudioSession sharedInstance].mode;
    if (sessionMode != AVAudioSessionModeDefault) {
        [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:nil];
    }
}
- (void) overrideAudioRouteToSpeaker
{
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideAudioRouteToSpeaker category:%s, categoryOption:%d, mode:%s", __FUNCTION__, [AVAudioSession sharedInstance].category.UTF8String, (int)[AVAudioSession sharedInstance].categoryOptions, [AVAudioSession sharedInstance].mode.UTF8String);
    if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        NSError *error = NULL;
        BOOL ret = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (ret == NO) {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideOutputAudioPort to AVAudioSessionPortOverrideSpeaker error:%s", __FUNCTION__, error.description.UTF8String);
        }
        else{
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideAudioRouteToSpeaker success!!!", __FUNCTION__);
        }
    }
}
- (void) overrideAudioRouteToNormal
{
//    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideAudioRouteToSpeaker category:%s, categoryOption:%d, mode:%s", __FUNCTION__, [AVAudioSession sharedInstance].category.UTF8String, (int)[AVAudioSession sharedInstance].categoryOptions, [AVAudioSession sharedInstance].mode.UTF8String);
    if ([[AVAudioSession sharedInstance].category isEqualToString:AVAudioSessionCategoryPlayAndRecord]) {
        NSError *error = NULL;
        BOOL ret = [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if (ret == NO) {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideOutputAudioPort to AVAudioSessionPortOverrideNone error:%s", __FUNCTION__, error.description.UTF8String);
        }
        else{
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:overrideAudioRouteToNormal success!!!", __FUNCTION__);
        }
    }
}
- (NSString*) getCurrentInputDevice
{
    [self getCurrentDeviceValue];
    return self.currentInputDevice;
}
- (NSString*) getCurrentOutputDevice
{
    return self.currentOutputDevice;
}
- (void) autoSwitchAudioOutputRouteForVideo
{
    @synchronized(self)
    {
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord) {
            return;
        }
        NSString *currentInputRoute = [self getCurrentInputDevice];
        NSString *currentOutputRoute= [self getCurrentOutputDevice];
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"audioInfos on %s, currentInputRoute:%s, currentOutputRoute:%s, mode:%s", __FUNCTION__, currentInputRoute.UTF8String, currentOutputRoute.UTF8String, [AVAudioSession sharedInstance].mode.UTF8String);
        if ([currentOutputRoute isEqualToString:@"Speaker"] || [currentOutputRoute isEqualToString:@"Receiver"]) {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToSpeaker", __FUNCTION__);
            [self overrideAudioRouteToSpeaker];
        }
        else{
            if ([currentInputRoute isEqualToString:@"MicrophoneBuiltIn"]) {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToNormal", __FUNCTION__);
                [self overrideAudioRouteToNormal];
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToNormal", __FUNCTION__);
                [self overrideAudioRouteToNormal];
            }
        }
    }
}
- (void) autoSwitchAudioOutputRouteForVoice
{
    @synchronized(self)
    {
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord) {
            return;
        }
        NSString *currentInputRoute = [self getCurrentInputDevice];
        NSString *currentOutputRoute= [self getCurrentOutputDevice];
//        QLog_Event(MODULE_IMPB_RICHMEDIA,"audioInfos on %s, currentInputRoute:%s, currentOutputRoute:%s, mode:%s", __FUNCTION__, currentInputRoute.UTF8String, currentOutputRoute.UTF8String, [AVAudioSession sharedInstance].mode.UTF8String);
        if ([currentOutputRoute isEqualToString:@"Speaker"] || [currentOutputRoute isEqualToString:@"Receiver"]) {
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToSpeaker", __FUNCTION__);
            [self overrideAudioRouteToSpeaker];
        }
        else
        {
            if ([currentInputRoute isEqualToString:@"MicrophoneBuiltIn"]) {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToNormal", __FUNCTION__);
                [self overrideAudioRouteToNormal];
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"on %s, overrideAudioRouteToNormal", __FUNCTION__);
                [self overrideAudioRouteToNormal];
            }
        }
    }
}
//新增接口，返回错误信息
-(void)setPlaybackCategory:(NSError **)error
{
    @synchronized(self)
    {
        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayback||currentMix) {
            BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:error];
            if(ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to playback success.", __FUNCTION__);
                }
                else
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to playback failed err = %s", __FUNCTION__,(*error).description.UTF8String);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to playback failed.", __FUNCTION__);
            }
        }
    }
}
-(void)setPlaybackCategoryMix:(NSError **)error
{
    @synchronized(self)
    {
        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayback || !currentMix)
        {
            BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:error];
            if(ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play back success.", __FUNCTION__);
                }
                else
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play back failed err = %s", __FUNCTION__,(*error).description.UTF8String);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play back failed.", __FUNCTION__);
            }
        }
    }
}
-(void)setRecordAudioCategory:(NSError **)error
{
    @synchronized(self)
    {
        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        BOOL currentBlueTooth = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth);
        NSString * preferredRoutePortType = [AVAudioSession sharedInstance].preferredInput.portType;
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord || !currentBlueTooth ||currentMix)
        {
            BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:error];
            if (ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory success", __FUNCTION__);
                }
                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
            }
        }
        if(preferredRoutePortType != AVAudioSessionPortBluetoothHFP)
        {
            NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
            for (AVAudioSessionPortDescription* route in routes)
            {
                if (route.portType == AVAudioSessionPortBluetoothHFP)
                {
                    [[AVAudioSession sharedInstance] setPreferredInput:route error:nil];
                }
            }
        }
    }
}
-(void)setSoloAmbientCategory:(NSError **)error
{
    @synchronized(self)
    {
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategorySoloAmbient) {
            BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategorySoloAmbient error:error];
            if (ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory success", __FUNCTION__);
                }
                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
            }
        }
    }
}
-(void)setAmbientCategory:(NSError **)error
{
    @synchronized(self)
    {
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryAmbient) {
            BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryAmbient error:error];
            if (ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory success", __FUNCTION__);
                }
                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:[AVAudioSession sharedInstance]setCategory failed", __FUNCTION__);
            }
        }
    }
}
-(void)setPlayAndRecordCategory:(NSError **)error
{
    @synchronized(self)
    {
        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        BOOL currentBlueTooth = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth);
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord ||currentMix ||!currentBlueTooth) {
            BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:error];
            if(ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record success.", __FUNCTION__);
                }
                else
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed err = %s", __FUNCTION__,(*error).description.UTF8String);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed.", __FUNCTION__);
            }
        }
    }
}
-(void)setPlayAndRecordCategoryMix:(NSError **)error
{
    @synchronized(self)
    {
        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        BOOL currentBlueTooth = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth);
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord || !currentMix ||!currentBlueTooth) {
            BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionMixWithOthers|AVAudioSessionCategoryOptionAllowBluetooth error:error];
            if(ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record success.", __FUNCTION__);
                }
                else
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed err = %s", __FUNCTION__,(*error).description.UTF8String);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed.", __FUNCTION__);
            }
        }
    }
}
-(void)setPlayAndRecordCategoryChat:(NSError **)error
{
    @synchronized(self)
    {
        AVAudioSessionCategoryOptions categoryOptions = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionDuckOthers;
        
        BOOL currentOptionOK = (([AVAudioSession sharedInstance].categoryOptions&categoryOptions) == categoryOptions);
        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord || !currentOptionOK) {
            BOOL ret = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:categoryOptions  error:error];
            if(ret)
            {
                if(!*error)
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record success.", __FUNCTION__);
                }
                else
                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed err = %s", __FUNCTION__,(*error).description.UTF8String);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:change route category to play and record failed.", __FUNCTION__);
            }
        }
    }
}
-(BOOL) setAudioSessionMix:(BOOL) mix         //设置混合模式 只有在blayback 和playAndRecord Category下有效
{
    @synchronized(self)
    {
        NSString *currentCategory = [AVAudioSession sharedInstance].category;
        AVAudioSessionCategoryOptions option  =[AVAudioSession sharedInstance].categoryOptions;
        BOOL currentMix = ((option&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
        if (mix != currentMix) {
            currentMix = mix;
            if (mix) {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:current Category:%zd", __FUNCTION__, currentCategory);
                if ([currentCategory isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
                    [currentCategory isEqualToString:AVAudioSessionCategoryPlayback]) {
                    [[AVAudioSession sharedInstance]setCategory:currentCategory withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
                }
                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:current category is not playback or playAndRecord!!!!", __FUNCTION__);
                }
            }
            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"%s:set no mix mode", __FUNCTION__);
            }
        }
        return YES;
    }
}
#pragma mark- Old API
-(void)enableBt
{
        UInt32 value = kAudioSessionMode_VoiceChat;
        UInt32 size = sizeof(value);
        AudioSessionGetProperty(kAudioSessionProperty_Mode, &size, &value);
        if (value != kAudioSessionMode_VoiceChat) {
            value = kAudioSessionMode_VoiceChat;
            AudioSessionSetProperty(kAudioSessionProperty_Mode, sizeof(value), &value);
        }
}
-(void)setPlayAndRecordCategory
{
    @synchronized(self)
    {
        UInt32 category = kAudioSessionCategory_PlayAndRecord;
        UInt32 size = sizeof(category);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &category);
        if (category != kAudioSessionCategory_PlayAndRecord) {
            category = kAudioSessionCategory_PlayAndRecord;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &category);
//            QLog_InfoP(MODULE_IMPB_RICHMEDIA,"change route category to play and record.");
        }
        [self enableBt];
    }
}
-(void)routeToSpeaker
{
    
    [self setPlayAndRecordCategory];
    UInt32 value = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(value), &value);
}
-(void)routeToNormal
{
    if ([self isIpod])
        return;
    [self setPlayAndRecordCategory];
    UInt32 value = kAudioSessionOverrideAudioRoute_None;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(value), &value);
}
-(void)notifyWillOverwrite:(BOOL)isSpeaker
{
    listenerSetType set = _listeners;
    for(listenerSetType::iterator itor = set.begin(); itor != set.end(); itor++)
    {
        if ([*itor respondsToSelector:@selector(onOutputWillAutoOverwrite:)]) {
            [*itor onOutputWillAutoOverwrite:isSpeaker];
        }
    }
}
//-(void)onSensorStateChange:(NSNotification*)notification
//{
//    if (self.currentRouteOld == nil && self.currentOutputDevice == nil)
//        return;
//
//    if ([[UIDevice currentDevice] proximityState] == YES) {
//        //近距离传感器很近则用耳机
//        if (CZ_StringEqualToString_c(self.currentRouteOld,"SpeakerAndMicrophone") || CZ_StringEqualToString(self.currentOutputDevice, (__bridge NSString*)kAudioSessionOutputRoute_BuiltInSpeaker))
//        {
//            [self notifyWillOverwrite:NO];
//            [self routeToNormal];
//        }
//    }
//    else
//    {
//        //近距离传感器较远则用扬声器
//        if (CZ_StringEqualToString_c(self.currentRouteOld,"ReceiverAndMicrophone") || CZ_StringEqualToString(self.currentOutputDevice, (__bridge NSString*)kAudioSessionOutputRoute_BuiltInReceiver))
//        {
//            [self notifyWillOverwrite:YES];
//            [self routeToSpeaker];
//        }
//    }
//}
/*
//近距离传感器状态改变的通知
-(void)setAutoRouteByProximity:(BOOL)autoRoute
{
    if (autoRoute) {
        [UIDevice currentDevice].proximityMonitoringEnabled = YES;
        CZ_AddObj2DeftNotiCenterNoObj(self, @selector(onSensorStateChange:), UIDeviceProximityStateDidChangeNotification);
    }
    else
    {
        CZ_RemoveObjFromDeftNotiCenterOnly(self);
        [UIDevice currentDevice].proximityMonitoringEnabled = NO;
    }
}
*/
-(void)setPlaybackCategory
{
    @synchronized(self)
    {
        UInt32 category = kAudioSessionCategory_MediaPlayback;
        UInt32 size = sizeof(category);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &category);
        if (category != kAudioSessionCategory_MediaPlayback) {
            category = kAudioSessionCategory_MediaPlayback;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &category);
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"change route category to media play back.");
        }
        [self setAudioMix:NO];
    }
}
-(void)setPlayAndRecordCategoryWithInputGain
{
    [self setPlayAndRecordCategory];
    UInt32 canGain = 0.5;
    UInt32 size = sizeof(canGain);
    AudioSessionGetProperty(kAudioSessionProperty_InputGainAvailable, &size, &canGain);
    if (canGain) {
        Float32 gain = 0.5;
        OSStatus ret = AudioSessionSetProperty(kAudioSessionProperty_InputGainScalar, sizeof(gain), &gain);
        if (ret)
//            QLog_Event(MODULE_IMPB_RICHMEDIA,"set gain level with result : %zd.",(int)ret);
        [self setAudioMix:NO];
    }
}
-(bool)isiPhone5SeriesWithSpecialSystem
{
    static bool isiPhone5Series = false;
    static NSString* device = Nil;
    if (!device) {
        struct utsname systemInfo;
        uname(&systemInfo);
        device = [NSString stringWithUTF8String:systemInfo.machine];
        if ([device rangeOfString:@"iPhone5"].location == 0) {
            NSString* sysver = [[UIDevice currentDevice] systemVersion];
            if ([sysver isEqualToString:@"7.0"] || [sysver isEqualToString:@"7.0.1"] || [sysver isEqualToString:@"7.0.2"] || [sysver isEqualToString:@"7.0.3"]) {
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"Iphone 5 series with special system,set record category to play and record.");
                isiPhone5Series = true;
            }
        }
    }
    return isiPhone5Series;
}
-(void)setRecordAudioCategory
{
    @synchronized(self)
    {
        if ([self isiPhone5SeriesWithSpecialSystem]) {
            return [self setPlayAndRecordCategoryWithInputGain];
        }
        
        UInt32 category = kAudioSessionCategory_RecordAudio;
        UInt32 size = sizeof(category);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &category);
        if (category != kAudioSessionCategory_RecordAudio) {
            category = kAudioSessionCategory_RecordAudio;
            OSStatus ret = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &category);
            if (ret){
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"change route category to record audio with result : %zd.",(int)ret);
            UInt32 enableBt = 1;
            ret = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryEnableBluetoothInput, sizeof(enableBt), &enableBt);
            }
//            if (ret)
//                QLog_Event(MODULE_IMPB_RICHMEDIA,"Audio session set recordaudio and enable bt failed with result : %zd.",(int)ret);
        }
//        NSError *error = nil;
//        BOOL currentMix = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionMixWithOthers) == AVAudioSessionCategoryOptionMixWithOthers);
//        BOOL currentBlueTooth = (([AVAudioSession sharedInstance].categoryOptions&AVAudioSessionCategoryOptionAllowBluetooth) == AVAudioSessionCategoryOptionAllowBluetooth);
//        NSString * preferredRoutePortType = [AVAudioSession sharedInstance].preferredInput.portType;
//        if ([AVAudioSession sharedInstance].category != AVAudioSessionCategoryPlayAndRecord || !currentBlueTooth ||currentMix)
//        {
//            BOOL ret = [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&error];
//            if (ret)
//            {
//                if(!error)
//                {
//                    QLog_Event(MODULE_IMPB_RICHMEDIA, "[AVAudioSession sharedInstance]setCategory: success");
//                }
//                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA, "[AVAudioSession sharedInstance]setCategory: failed");
//                }
//            }
//            else{
//                QLog_Event(MODULE_IMPB_RICHMEDIA, "[AVAudioSession sharedInstance]setCategory: failed");
//            }
//        }
//        if(preferredRoutePortType != AVAudioSessionPortBluetoothHFP)
//        {
//            NSArray* routes = [[AVAudioSession sharedInstance] availableInputs];
//            uint8_t inputType = 0;
//            AVAudioSessionPortDescription *bt = nil, *headSet = nil;
//
//            for (AVAudioSessionPortDescription* route in routes)
//            {
//                if (CZ_StringEqualToString(route.portType, AVAudioSessionPortBluetoothHFP)) {
//                    inputType |= 2;
//                    bt = route;
//                }
//                else if (CZ_StringEqualToString(route.portType, AVAudioSessionPortHeadsetMic)) {
//                    inputType |= 1;
//                    headSet = route;
//                }
//            }
//            AVAudioSessionPortDescription* route = routes.firstObject;
//            if (inputType & 2) {
//                route = bt;
//            }
//            else if (inputType & 1) {
//                route = headSet;
//            }
//            [[AVAudioSession sharedInstance] setPreferredInput:route error:nil];
//        }
//        NSString *sessionMode = [AVAudioSession sharedInstance].mode;
//        if (sessionMode != AVAudioSessionModeDefault) {
//            [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeDefault error:nil];
//        }
    }
}
-(void)setSoloAmbientCategory
{
    @synchronized(self)
    {
        UInt32 category = kAudioSessionCategory_SoloAmbientSound;
        UInt32 size = sizeof(category);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &category);
        if (category != kAudioSessionCategory_SoloAmbientSound) {
            category = kAudioSessionCategory_SoloAmbientSound;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &category);
//            QLog_InfoP(MODULE_IMPB_RICHMEDIA,"change route category to solo ambient.");
        }
    }
}
-(void)setAmbientCategory
{
    @synchronized(self)
    {
        UInt32 category = kAudioSessionCategory_AmbientSound;
        UInt32 size = sizeof(category);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &category);
        if (category != kAudioSessionCategory_AmbientSound) {
            category = kAudioSessionCategory_AmbientSound;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &category);
//            QLog_InfoP(MODULE_IMPB_RICHMEDIA,"change route category to Ambient ambient.");
        }
    }
}
-(BOOL) setAudioMix:(BOOL) mix         //设置混合模式 只有在blayback 和playAndRecord Category下有效 hodxiang added for tinyVideo
{
    UInt32 currentMix = 0;
    UInt32 outSize = sizeof(currentMix);
    OSStatus ret = AudioSessionGetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, &outSize, &currentMix);
//    QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, getCurrentMixMode Ret:%zd currentMixMode:%zd, new mode:%d", __FUNCTION__, ret, currentMix, mix);
    if (ret == noErr) {
        if (mix != currentMix) {
            currentMix = mix;
            if (mix) {
                UInt32 currentCategory = (UInt32)[self getCurCategory];
//                QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, current Category:%zd", __FUNCTION__, currentCategory);
                if (currentCategory == kAudioSessionCategory_PlayAndRecord ||
                    currentCategory == kAudioSessionCategory_MediaPlayback) {
                    ret = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(currentMix), &currentMix);
//                    QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, set mix mode ret:%zd", __FUNCTION__, ret);
                }
                else{
//                    QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, current category is not playback or playAndRecord!!!!", __FUNCTION__);
                }
            }
            else{
                ret = AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(currentMix), &currentMix);
//                QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, set no mix mode ret:%zd", __FUNCTION__, ret);
            }
        }
    }
    return (ret == noErr);
}
- (BOOL) setAudioSessionCategory:(UInt32) category //设置category
{
    @synchronized(self)
    {
        UInt32 currentCategory = category;
        UInt32 size = sizeof(currentCategory);
        AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &currentCategory);
//        QLog_Event(MODULE_IMPB_RICHMEDIA, "on %s, currentCategory:%zd, new category:%zd", __FUNCTION__, currentCategory, category);
        if (currentCategory != category) {
            currentCategory = category;
            OSStatus ret = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, size, &currentCategory);
//            QLog_InfoP(MODULE_IMPB_RICHMEDIA,"on %s, change route category to %zd, ret:%zd.", __FUNCTION__, category, ret);
            return (ret == kAudioSessionNoError);
        }
        return YES;
    }
}
@end
