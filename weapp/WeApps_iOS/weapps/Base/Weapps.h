//
//  Weapps.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAStorage.h"
#import "AFNetworkReachabilityManager.h"
#import "WAWebViewNetworkManager.h"
#import "WARecordManager.h"
#import "WAAudioManager.h"
#import "WACameraManager.h"
#import "WAMediaContainerManager.h"
#import "WAVideoDecoderManager.h"
#import "WADeviceManager.h"
#import "WABluetoothManager.h"
#import "WAVoipManager.h"
#import "WALivePusherManager.h"
#import "WALivePlayerManager.h"
#import "WAWIFIManager.h"
#import "WAMapManager.h"
#import "WAVideoPlayerManager.h"
#import "WAConfig.h"


NS_ASSUME_NONNULL_BEGIN

dispatch_queue_t dispatch_get_weapps_queue(void);
BOOL isWeappsQueue(void);



@protocol MAAudioSessionDelegate <NSObject>
/**
 use QQAudioSessionManager to activeAudio
 @param helper 遵循QQAudioSessionManagerDelegate
 */
- (void)activeAudioSessionForRecordVoice:(NSObject *)helper;
/**
 use QQAudioSessionManager to activeAudio
 @param resumePlayBlock 恢复播放
 @param pauseBlock 暂停播放
 @return helper 遵循QQAudioSessionManagerDelegate
 */
- (NSObject *)createAudioSessionHelplerResumePlayBlock:(void(^ _Nullable)(void))resumePlayBlock
                                            pauseBlock:(void(^ _Nullable)(void))pauseBlock;
/**
 use QQAudioSessionManager to activeAudio
 @param helper 遵循QQAudioSessionManagerDelegate
 @param mixWithOther 是否混播
 @param obeyMuteSwitch 是否受静音键控制
 */
- (void)activeAudioSessionForAudioPlayer:(NSObject *)helper
                            mixWithOther:(BOOL)mixWithOther
                          obeyMuteSwitch:(BOOL)obeyMuteSwitch;
/**
 use QQAudioSessionManager to deactiveAudio
 @param helper 遵循QQAudioSessionManagerDelegate
 */
- (void)deactiveAudioSession:(NSObject *)helper;
@end


/// 配置信息变化协议
@protocol WeappsConfigDelegate <NSObject>

- (void)weappsConfigDidChange:(WAConfig *)config;

@end

@interface Weapps : NSObject <MAAudioSessionDelegate>

@property (nonatomic, strong, readonly) NSDictionary *launchOptions;

@property (nonatomic, strong, readonly) MAStorage *storage;

@property (nonatomic, strong, readonly) AFNetworkReachabilityManager *reachabilityManager;

@property (nonatomic, strong, readonly) WAWebViewNetworkManager *networkManager;

@property (nonatomic, strong, readonly) WARecordManager *recordManager;

@property (nonatomic, strong, readonly) WAAudioManager *audioManager;

@property (nonatomic, strong, readonly) WACameraManager *cameraManager;

@property (nonatomic, strong, readonly) WAMediaContainerManager *mediaContainerManager;

@property (nonatomic, strong, readonly) WAVideoDecoderManager *videoDecoderManager;

@property (nonatomic, strong, readonly) WADeviceManager *deviceManager;

@property (nonatomic, strong, readonly) WABlueToothManager *bluetoothManager;

@property (nonatomic, strong, readonly) WAVoipManager *VoIPManager;

@property (nonatomic, strong, readonly) WALivePusherManager *livePusherManager;

@property (nonatomic, strong, readonly) WALivePlayerManager *livePlayerManager;

@property (nonatomic, strong, readonly) WAWIFIManager *WIFIManager;

@property (nonatomic, strong, readonly) WAMapManager *mapManager;

@property (nonatomic, strong, readonly) WAVideoPlayerManager *videoPlayerManager;

@property (nonatomic, strong, readonly) WAConfig *config;

/// 目前为单页面app，configDelegate只需一个即可
@property (nonatomic, weak) id<WeappsConfigDelegate> configDelegate;

/**
 *  严格单例，唯一获得实例的方法.
 *
 *  @return 实例对象.
 */
+ (instancetype)sharedApps;


/// 初始化并获取LaunchOptions，需要在application:didFinishLaunchingWithOptions:中调用
/// @param options LaunchOptions
- (void)initializeWithLaunchOptions:(NSDictionary *)options;

/// 设置页面配置，配置信息目前先加载webView后有webView调用本地接口传过来。推荐后期改为在webView加载前读取本地json文件
/// 详情见https://ipcrio-113.pdcts.com.cn/docservice/docs/?modId=PqmyfhAfq&nodeId=f29xFdk0T
/// @param dict 配置信息
- (void)setConfigWithDict:(NSDictionary *)dict;

@end

NS_ASSUME_NONNULL_END
