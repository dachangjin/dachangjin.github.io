//
//  AudioQueueRecorder.m
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/2/28.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MAAudioQueueRecorder.h"
#import <Foundation/Foundation.h>
#import "MARecordTools.h"
#import <AVFoundation/AVFoundation.h>

//设置码率，需要注意，AAC并不是随便的码率都可以支持。比如如果PCM采样率是44100KHz，那么码率可以设置64000bps，如果是16K，可以设置为32000bps。
const int MAAudioQueueBufferCount = 3;
const float kBufferDurationSeconds = 0.5;// 每次的音频输入队列缓存区所保存的是多少秒的数据
@interface MAAudioQueueRecorder () {
    __weak id<MAAudioQueueRecorderDelegate> _delegate;
    
    BOOL _started;
    
    AudioQueueRef _audioQueue;
    AudioQueueBufferRef _audioBuffers[MAAudioQueueBufferCount];
    
    NSMutableData *_buffer;
    UInt32 _subBufferSize;            // 单个subBuffer最大长度
    NSInteger _subBufferMaxCount;     // 最多生成多少个subBuffer的数据
    NSInteger _subBufferIndex;
    NSTimeInterval _maxDuration;      // 录音最长时长
}
@end


@implementation MAAudioQueueRecorder

#pragma mark - init & dealloc
- (instancetype)initWithFormat:(AudioStreamBasicDescription)format
                      duration:(NSTimeInterval)duration
                      delegate:(id<MAAudioQueueRecorderDelegate>)delegate {
    
    self = [super init];
    if (self) {
        _format = format;
        _maxDuration = duration;
        _delegate = delegate;
    }
    return self;
}

- (void)setup {
    _setToStopped = NO;
    _subBufferIndex = 0;
    _subBufferSize = [self computeBufferSize];
    
    _buffer = [[NSMutableData alloc] init];
    _subBufferMaxCount = _maxDuration / kBufferDurationSeconds;
    
    if ([_formatType isEqualToString:@"aac"]) {
        // aac必须是固定2048倍数一帧 不然编码错误
        UInt32 bufferSize = _format.mChannelsPerFrame  * 2048;
        float bufferDurationSeconds = (float)bufferSize / _subBufferSize * kBufferDurationSeconds;
        _subBufferSize = bufferSize;
        _subBufferMaxCount = ceilf(_maxDuration / bufferDurationSeconds);
    }
  
    if ([_formatType isEqualToString:@"mp3"] && self.frameSize > 0) {
        float mp3SubBufferSize = (float)_encodeBitRate / 8 * _maxDuration / (float)_subBufferMaxCount; //计算原pcm分片对应的MP3分片大小
        float scale = (float)self.frameSize * 1024 / mp3SubBufferSize; //原分片和回调分片的比例
        UInt32 bufferSize = ceilf(_subBufferSize * scale / 1152) * 1152; //pcm回调分片大小 以1152个PCM采样值为单位，封装成具有固定长度的MP3数据帧，帧是MP3文件的最小组成单位
        float bufferDurationSeconds = scale * kBufferDurationSeconds;
        _subBufferSize = bufferSize;
        _subBufferMaxCount = ceilf(_maxDuration / bufferDurationSeconds);
    }
}


- (UInt32)computeBufferSize {
    int packets, frames, bytes = 0;
    @try {
        frames = (int)ceil(kBufferDurationSeconds * _format.mSampleRate);
        
        if (_format.mBytesPerFrame > 0) {
            bytes = frames * _format.mBytesPerFrame;
        } else {
            UInt32 maxPacketSize;
            if (_format.mBytesPerPacket > 0){
                maxPacketSize = _format.mBytesPerPacket;    // constant packet size
            } else {
                UInt32 propertySize = sizeof(maxPacketSize);
                WALOG(@"%d, %@",(int)AudioQueueGetProperty(_audioQueue,
                                                           kAudioQueueProperty_MaximumOutputPacketSize,
                                                           &maxPacketSize,
                                                           &propertySize),
                      @"couldn't get queue's maximum output packet size");
            }
            if (_format.mFramesPerPacket > 0){
                packets = frames / _format.mFramesPerPacket;
            } else {
                packets = frames;    // worst-case scenario: 1 frame in a packet
            }
            if (packets == 0){        // sanity check
                packets = 1;
            }
            bytes = packets * maxPacketSize;
        }
    }
    @catch (NSException *exception) {
        WALOG(@"捕获到异常: %@", [exception reason]);
        return 0;
    }
    return bytes;
}


#pragma mark - audio queue
- (void)createAudioQueue {
    //new耗时操作中间可能被释放，交给cf框架管理内存，初始化完成才能安全释放
    void * queueRecorder = (__bridge_retained void *)(self);
    OSStatus status = AudioQueueNewInput(&_format, audioQueueInuputCallback, queueRecorder, NULL, NULL, 0, &_audioQueue);
    CFRelease(queueRecorder);
    
    if (![self checkAudioQueueSuccess:status]) {
        return;
    }
    
    for (int i = 0; i < MAAudioQueueBufferCount; ++i){
        if (![self checkAudioQueueSuccess:AudioQueueAllocateBuffer(_audioQueue, _subBufferSize, &_audioBuffers[i])]){
            break;
        }
        
        if (![self checkAudioQueueSuccess:AudioQueueEnqueueBuffer(_audioQueue, _audioBuffers[i], 0, NULL)]){
            break;
        }
    }
}


#pragma mark - error
- (void)errorForOSStatus:(OSStatus)status error:(NSError *__autoreleasing *)outError {
    if (status != noErr && outError != NULL){
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
}

- (BOOL)checkAudioQueueSuccess:(OSStatus)status {
    if (status != noErr){
        if (_audioQueue){
            AudioQueueDispose(_audioQueue, YES);
            _audioQueue = NULL;
        }
        
        NSError *error = nil;
        [self errorForOSStatus:status error:&error];
        if ([_delegate respondsToSelector:@selector(audioQueue:error:)]) {
            [_delegate audioQueue:self error:error.description];
        }
        return NO;
    }
    return YES;
}

#pragma mark - call back
static void audioQueueInuputCallback(void *inClientData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer,
                                       const AudioTimeStamp *inStartTime,
                                       UInt32 inNumberPacketDescriptions,
                                       const AudioStreamPacketDescription *inPacketDescs)
{
    MAAudioQueueRecorder *audioOutputQueue = (__bridge MAAudioQueueRecorder *)inClientData;
    [audioOutputQueue handleAudioQueueOutputCallBack:inAQ
                                              buffer:inBuffer
                                         inStartTime:inStartTime
                          inNumberPacketDescriptions:inNumberPacketDescriptions
                                       inPacketDescs:inPacketDescs];
}
- (void)handleAudioQueueOutputCallBack:(AudioQueueRef)audioQueue
                                buffer:(AudioQueueBufferRef)buffer
                           inStartTime:(const AudioTimeStamp *)inStartTime
            inNumberPacketDescriptions:(UInt32)inNumberPacketDescriptions
                         inPacketDescs:(const AudioStreamPacketDescription *)inPacketDescs {
    if (_started) {
        [_buffer appendBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
        [self checkAudioQueueSuccess:AudioQueueEnqueueBuffer(_audioQueue, buffer, 0, NULL)];
        if ([_buffer length] >= _subBufferSize && !_setToStopped) {
            
            NSData *data = nil;
            if ([_buffer length] >= _subBufferSize) {
                data = [_buffer subdataWithRange:NSMakeRange(0, _subBufferSize)];
            }
            if (data) {
                [_recordTools inputQueue:data];
                NSRange range = NSMakeRange(0, _subBufferSize);
                // NSData清理数据方法
                [_buffer replaceBytesInRange:range withBytes:NULL length:0];
                //MAInfoLog(@"录音第%tu帧",_bufferIndex);
                _subBufferIndex++;
            }
            if (_subBufferIndex > _subBufferMaxCount - 1) {
                _recordTools.isLastFrame = YES;
                [self stop];
            }
        }
        if (_setToStopped){
            while ([_buffer length] >= _subBufferSize) {
                NSData *data = [[NSData alloc] initWithBytes:_buffer.bytes length:_subBufferSize];
                [_recordTools inputQueue:data];
                NSRange range = NSMakeRange(0, _subBufferSize);
                [_buffer replaceBytesInRange:range withBytes:NULL length:0];
            }
            [_recordTools forceStop];
        }
    }
}


#pragma mark - operator
- (BOOL)start {
    [self setup];
    [self createAudioQueue];
    OSStatus status = AudioQueueStart(_audioQueue, NULL);
    WALOG(@"AudioQueueStart status %d",(int)status);
    _started = status == noErr;
    return _started;
}


- (BOOL)resume {
    OSStatus status = AudioQueueStart(_audioQueue, NULL);
    _started = status == noErr;
    WALOG(@"AudioQueueResume status %d",(int)status);
    return _started;
}

- (BOOL)pause{
    OSStatus status = AudioQueuePause(_audioQueue);
    WALOG(@"AudioQueuePause status %d",(int)status);
    return status == noErr;
}

- (BOOL)reset {
    OSStatus status = AudioQueueReset(_audioQueue);
    WALOG(@"AudioQueueReset status %d",(int)status);
    return status == noErr;
}


- (void)setToStop {
    _setToStopped = YES;
}

- (BOOL)stop {
    _started = NO;
    _setToStopped = YES;
    OSStatus status = AudioQueueStop(_audioQueue, true);
    WALOG(@"AudioQueueStop status %d",(int)status);
    return status == noErr;
}

- (BOOL)dispose {
    OSStatus status = AudioQueueDispose(_audioQueue, true);
    WALOG(@"AudioQueueDispose status %d",(int)status);
    return status == noErr;
}


- (BOOL)isStarted {
    return _started;
}

@end
