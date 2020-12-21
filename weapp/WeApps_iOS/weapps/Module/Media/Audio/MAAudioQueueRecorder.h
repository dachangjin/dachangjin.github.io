//
//  AudioQueueRecorder.h
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/2/28.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MARecordTools;

@class MAAudioQueueRecorder;

@protocol MAAudioQueueRecorderDelegate <NSObject>

@required
- (void)audioQueue:(MAAudioQueueRecorder *)audioQueue error:(NSString *)error;

@end

@interface MAAudioQueueRecorder : NSObject
@property (nonatomic, weak) MARecordTools *recordTools;
@property (nonatomic, strong) NSMutableArray *recordQueue;
@property (nonatomic, assign) BOOL setToStopped;
@property (nonatomic, weak) id<MAAudioQueueRecorderDelegate> delegate;
@property (nonatomic, assign) UInt32 frameSize;
@property (nonatomic, assign) UInt32 encodeBitRate;
@property (nonatomic, readonly) AudioStreamBasicDescription format;
@property (nonatomic, strong) NSString *formatType;

- (instancetype)initWithFormat:(AudioStreamBasicDescription)format
                      duration:(NSTimeInterval)duration
                      delegate:(id<MAAudioQueueRecorderDelegate>)delegate;

- (BOOL)isStarted;

- (BOOL)start;

- (BOOL)pause;

- (BOOL)resume;

- (void)setToStop;

- (BOOL)stop;

- (BOOL)reset;

- (BOOL)dispose;

@end
