//
//  AudioRouteMonitor.h
//  QQMSFContact
//
//  Created by Zhang Random on 13-8-9.
//  Copyright © 2020 tencent. All rights reserved.
//
//

#import <Foundation/Foundation.h>

enum AudioRouteType
{
    AUDIOROUTETYPE_SPEAKER,
    AUDIOROUTETYPE_RECEIVER,
    AUDIOROUTETYPE_OTHER,
    AUDIOROUTETYPE_RECORDING,
    AUDIOROUTETYPE_INVALID = -1
};
@protocol AudioRouteChangeProtocol <NSObject>
@optional
-(void)onRecordDeviceChanged;
-(void)onOutputDeviceChanged:(int)currentType;
-(void)onOutputWillAutoOverwrite:(BOOL)isSpeaker;
@end
//监控输入输出设备变化的类
@interface AudioRouteMonitor : NSObject
+(AudioRouteMonitor*)getInstance;
-(void)addListener:(id<AudioRouteChangeProtocol>)listener;
-(void)removeListerner:(id<AudioRouteChangeProtocol>)listener;
-(int)getCurrentOutputType;
-(BOOL)isSpeakerOn;
-(BOOL)isTelePhoneCalling;              //当前是否有电话
// 下面两个get方法是直接返回AudioRouteMonitor对象内部的变量，但是这两个内部变量可能会随时变化(返回的值变成野指针).
// 所以如果外部需要持有返回结果，需要自己retain一把，或者copy一份.等用完了再release一次
- (NSString*) getCurrentInputDevice;
- (NSString*) getCurrentOutputDevice;
-(unsigned long)getCurCategory;
//新增接口，返回错误信息
-(void)setPlaybackCategory:(NSError **)error;
-(void)setPlaybackCategoryMix:(NSError **)error;
-(void)setRecordAudioCategory:(NSError **)error;
-(void)setSoloAmbientCategory:(NSError **)error;
-(void)setAmbientCategory:(NSError **)error;
-(void)setPlayAndRecordCategory:(NSError **)error;
-(void)setPlayAndRecordCategoryMix:(NSError **)error;
-(void)setPlayAndRecordCategoryChat:(NSError **)error;
-(BOOL)setAudioSessionMix:(BOOL)mix;
-(void)setDefaultMode;
-(void)setVoiceChatMode;
-(void)autoSwitchAudioOutputRouteForVideo;
-(void)autoSwitchAudioOutputRouteForVoice;
-(void)overrideAudioRouteToSpeaker;
-(void)overrideAudioRouteToNormal;
// *************老接口
//-(void)routeToSpeaker;
//-(void)routeToNormal;
////-(void)setAutoRouteByProximity:(BOOL)autoRoute;
//-(void)setPlayAndRecordCategory;
-(void)setPlaybackCategory;
//-(void)setRecordAudioCategory;
//-(void)setSoloAmbientCategory;
//-(void)setAmbientCategory;
//-(void)setPlayAndRecordCategoryWithInputGain;
//-(void)enableBt;
-(BOOL) setAudioMix:(BOOL) mix;         //设置混合模式 只有在blayback 和playAndRecord Category下有效 hodxiang added for tinyVideo
//- (BOOL) setAudioSessionCategory:(UInt32) category; //设置category
@end
