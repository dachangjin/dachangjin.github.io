//
//  Weapps.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>
#import <QMapKit/QMapKit.h>
#import <TXLiteAVSDK_Professional/TXLiveBase.h>
#import "Weapps.h"
#import "PathUtils.h"
#import "EventListenerList.h"
#import "QMAAudioSessionHelper.h"
#import "AudioCategoryModel.h"
#import "QQAudioSessionManager.h"
#import "AppConfig.h"

   
static void *gWeappsQueueKey = &gWeappsQueueKey;
dispatch_queue_t dispatch_get_weapps_queue() {
    static dispatch_queue_t serialQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create("com.weapps.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(serialQueue,
                                    gWeappsQueueKey, (__bridge void *)(serialQueue), NULL);
        
    });
    return serialQueue;
}
BOOL isWeappsQueue() {
    return dispatch_get_specific(gWeappsQueueKey) == (__bridge void *)(dispatch_get_weapps_queue());
}

@interface Weapps ()

@property (nonatomic, strong) NSDictionary *launchOptions;

@end


@implementation Weapps

+ (instancetype)sharedApps {
    static dispatch_once_t onceToken;
    static Weapps *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[Weapps alloc] init];
    });
    return instance;
}

- (void)initializeWithLaunchOptions:(NSDictionary *)options
{
    _launchOptions = options;
    _storage = [[MAStorage alloc] initWithFolderPath:[PathUtils storagePath]];
    _networkManager = [[WAWebViewNetworkManager alloc] initWithApp:self];
    _recordManager = [[WARecordManager alloc] initWithWeapps:self];
    _audioManager = [[WAAudioManager alloc] initWithWeapps:self];
    _cameraManager = [[WACameraManager alloc] initWithWeapps:self];
    _mediaContainerManager = [[WAMediaContainerManager alloc] init];
    _videoDecoderManager = [[WAVideoDecoderManager alloc] init];
    _deviceManager = [[WADeviceManager alloc] init];
    _bluetoothManager = [[WABlueToothManager alloc] init];
    _VoIPManager = [[WAVoipManager alloc] init];
    _livePusherManager = [[WALivePusherManager alloc] init];
    _livePlayerManager = [[WALivePlayerManager alloc] init];
    _WIFIManager = [[WAWIFIManager alloc] init];
    _mapManager = [[WAMapManager alloc] init];
    _videoPlayerManager = [[WAVideoPlayerManager alloc] init];
    [QMapServices sharedServices].APIKey = kMapApiKey;
    [TXLiveBase setLicenceURL:kLivePlayerURL key:kLivePlayerKey];
}


- (void)setConfigWithDict:(NSDictionary *)dict
{
    _config = [[WAConfig alloc] initWithDic:dict];
    if ([_configDelegate respondsToSelector:@selector(weappsConfigDidChange:)]) {
        [_configDelegate weappsConfigDidChange:_config];
    }
}


#pragma mark - MAAudioSessionDelegate
- (void)activeAudioSessionForRecordVoice:(NSObject *)helper {
    if (![helper isKindOfClass:[QMAAudioSessionHelper class]]) {
        return;
    }
    QMAAudioSessionHelper *asHelper = (QMAAudioSessionHelper *)helper;
    
    AudioCategoryModel *categoryModel = [AudioCategoryModel createWithCategory:QQAudioSessionPlayAndRecordVideoSolo
                                                             interruptPriority:QQAVInteruptPriorityRecord
                                                              businessDelegate:asHelper
                                                                  needRecovery:YES
                                                                 canBackground:NO];
    NSError *categoryErr = nil;
    if (![[QQAudioSessionManager getInstance] activeCategoryModel:categoryModel error:&categoryErr]) {
        WALOG(@"Weapps unable to active AudioSession for record %s", [categoryErr description].UTF8String ? : "");
    }
}

- (NSObject *)createAudioSessionHelplerResumePlayBlock:(void (^)(void))resumePlayBlock pauseBlock:(void (^)(void))pauseBlock {
    QMAAudioSessionHelper *helper = [QMAAudioSessionHelper new];
    helper.resumePlayBlock = resumePlayBlock;
    helper.pauseBlock = pauseBlock;
    return helper;
}
- (void)activeAudioSessionForAudioPlayer:(NSObject *)helper
                            mixWithOther:(BOOL)mixWithOther
                          obeyMuteSwitch:(BOOL)obeyMuteSwitch {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        if (![helper isKindOfClass:[QMAAudioSessionHelper class]]) {
            return;
        }
        QMAAudioSessionHelper *asHelper = (QMAAudioSessionHelper *)helper;
        
        QQAudioSessionCategory category = QQAudioSessionStart;
        if (mixWithOther && obeyMuteSwitch) {
            category = QQAudioSessionPlayVoiceAmbient;          // 混合，静音键控制
        } else if (mixWithOther && obeyMuteSwitch == NO) {
            category = QQAudioSessionPlayMusicMix;              // 混合，不受静音键控制
        } else if (obeyMuteSwitch && mixWithOther == NO) {
            category = QQAudioSessionPlayMusicSoloAmbient;      // 打断，静音键控制
        } else {
            category = QQAudioSessionPlayMusicSolo;             // 打断，不受静音键控制
        }
        
        AudioCategoryModel *model = [AudioCategoryModel createWithCategory:category
                                                         interruptPriority:QQAVInteruptPriorityPlay
                                                          businessDelegate:asHelper
                                                              needRecovery:YES
                                                             canBackground:NO];
        NSError *categoryErr = nil;
        if (![[QQAudioSessionManager getInstance] activeCategoryModel:model error:&categoryErr]) {
            WALOG(@"QQMiniApp unable to active AudioSession @%s", [categoryErr description].UTF8String ? : "");
        }
    });
}
- (void)deactiveAudioSession:(NSObject *)helper {
    if (![helper isKindOfClass:[QMAAudioSessionHelper class]]) {
        return;
    }
    QMAAudioSessionHelper *asHelper = (QMAAudioSessionHelper *)helper;
    [[QQAudioSessionManager getInstance] deactive:asHelper delay:NO notifyOtherApp:YES];
}


- (void)dealloc
{
    [_reachabilityManager stopMonitoring];
}

@end



