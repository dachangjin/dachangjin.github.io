//
//  MAAudioPlayer.h
//  MiniAppSDK
//
//  Created by wellingjin on 4/12/2018.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>

#define BACKGROUND_AUDIO_ID 0
/*
 PlayerState_Init        = -1,       // 播放器初始化值
 PlayerState_Unknow      = 0,        //
 PlayerState_Opened      = 1,                 // 已初始化数据
 PlayerState_Playing     = 2,                // 播放中
 PlayerState_Buffering   = 3,              // 缓存数据中
 PlayerState_Pause       = 4,                  // 暂停
 PlayerState_WaitSeek    = 5,               // 等待seek
 PlayerState_Seeking     = 6,                // seeking
 PlayerState_Finish      = 7,                 // 播放完成
 PlayerState_Error       = 8,                  // 出错了
 PlayerState_Stop        = 9,                   // 终止
 PlayerState_ErrorNetwork= 10,            // 网络出错
 */
//参考QQ音乐播放的枚举顺序
typedef NS_ENUM(NSInteger, MAPlayerStatus) {
    MAPlayerStatusUnknown           = 0,
    MAPlayerStatusReadyToPlay       = 1,
    MAPlayerStatusPlaying           = 2,
    MAPlayerStatusBuffering         = 3,
    MAPlayerStatusPause             = 4,
    MAPlayerStatusSeeking           = 5,
    MAPlayerStatusSeeked            = 6,
    MAPlayerStatusEnded             = 7,
    MAPlayerStatusFailed            = 8,
    MAPlayerStatusStop              = 9,
    MAPlayerStatusErrorNetwork      = 10,
    
    MAPlayerStatusNext              = 99,       //系统音乐控制面板的下一首
    MAPlayerStatusPrev              = 100,      //系统音乐控制面板的上一首
};

typedef NS_ENUM (NSInteger, MAAudioStopCallBackErrorCode) {
    MAAudioStopCallBackNoError              = 0,
    MAAudioStopCallBackSystemError          = 10001,
    MAAudioStopCallBackNetWorkError         = 10002,
    MAAudioStopCallBackFileError            = 10003,
    MAAudioStopCallBackFormatError          = 10004,
    MAAudioStopCallBackUnknownError         = -1,
};

NS_ASSUME_NONNULL_BEGIN

@class MAAudioManager;

@interface MAAudioPlayer : NSObject
@property(nonatomic, assign, readonly) CGFloat duration;            // 总时长
@property(nonatomic, assign, readonly) MAPlayerStatus status;       // 状态
@property(nonatomic, assign, readonly) CGFloat currentTime;         // 当前播放时长,时间是秒
@property(nonatomic, assign, readonly) NSInteger audioID;
@property(nonatomic, assign, readonly) CGFloat totalBuffer;         // 缓冲长度
@property(nonatomic, strong) NSString* url;
@property(nonatomic, assign) BOOL autoPlay;
@property(nonatomic, assign) BOOL loop;
@property(nonatomic, assign) CGFloat volume;
@property(nonatomic, assign) CGFloat startTime;
@property(nonatomic, strong) NSString* appID;
@property(nonatomic, weak) MAAudioManager *audioManager;
// 用于标记离开页面回来后是否需要恢复播放
@property(nonatomic, assign) BOOL isPausedWhenDisappear;
@property(nonatomic, strong) void(^statusChangedBlock)(MAPlayerStatus status, MAAudioStopCallBackErrorCode errorCode);
@property(nonatomic, strong) void(^playingProgressBlock)(CGFloat currentTime);
@property(nonatomic, strong) void(^playToEndBlock)(void);

+ (dispatch_queue_t)maAudioQueue;

- (instancetype)initWithAudioID:(NSUInteger)audioID;

- (BOOL)manulSeekToTime:(float)time;

- (BOOL)seekToTime:(float)time;

- (void)setRate:(float)rate;

- (float)rate;

- (void)pause;

- (void)stop;

- (void)play;

- (BOOL)isPlaying;

// 打断和恢复
- (void)interruptPlay;

- (void)resumePlay;

@end
NS_ASSUME_NONNULL_END
 
