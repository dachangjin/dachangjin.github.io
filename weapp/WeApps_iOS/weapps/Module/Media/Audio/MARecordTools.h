
//
//  MARecordTools.h
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/3/1.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "MAAudioQueueRecorder.h"
#import "MAMp3EncodeOperation.h"
NS_ASSUME_NONNULL_BEGIN

@protocol MARecordToolsDelegate <NSObject>

/// 开始录音回调
- (void)onStart;

/// 停止录音回调
- (void)onStopWithDuration:(NSTimeInterval)duration tempFilePath:(NSString *)filePath fileSize:(unsigned long long)fileSize;

/// 恢复录音回调
- (void)onResume;

/// 暂停录音回调
- (void)onPause;

/// 录音被打断开始回调
- (void)onInterruptionBegin;

/// 录音被打断完成回调
- (void)onInterruptionEnd;

/// 录音帧回调
- (void)onFrameRecorded:(BOOL)isLastFrame frameBuffer:(NSData *)frameBuffer;

/// 录音错误回调
- (void)onError:(NSString *)msg;

@end

@interface MARecordTools : NSObject

/// 是否到最好一帧
@property (nonatomic, assign) BOOL isLastFrame;

@property (nonatomic, weak) id<MARecordToolsDelegate> delegate;

/// 初始化
- (id)initWithDelegate:(id<MARecordToolsDelegate> )deleagte;

/// 设置参数
- (void)setupWithDuration:(NSTimeInterval)duration
               formatType:(NSString *)formatType
            encodeBitRate:(UInt32)encodeBitRate
                frameSize:(UInt32)frameSize
              audioSource:(NSString *)audioSource
               sampleRate:(Float64)sampleRate
         numberOfChannels:(UInt32)numberOfChannels;

/// 启动录音
- (void)startWithCompletionHandler:(void (^)(BOOL, NSDictionary * _Nullable, NSError * _Nullable))completionHandler;

/// 暂停录音
- (void)pause;

/// 恢复录音
- (void)resume;

/// 停止录音
- (void)stop;

/// 内部调用
- (void)forceStop;

- (void)finish;

- (void)stopWithError:(NSString *)msg;

- (void)mp3dataEncoded:(NSDictionary *)dictionary;

- (void)inputQueue:(NSData *)data;

- (NSData *)popQueueIsLastData:(BOOL *)isLastData;

@end

NS_ASSUME_NONNULL_END
