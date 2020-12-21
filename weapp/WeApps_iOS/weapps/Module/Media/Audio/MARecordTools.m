//
//  MARecordTools.m
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/3/1.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MARecordTools.h"
#import <AVFoundation/AVFoundation.h>
#import "PathUtils.h"
#import "Weapps.h"
#import "QMAAudioSessionHelper.h"

@interface MARecordTools () <MAAudioQueueRecorderDelegate> {
    
    MAAudioQueueRecorder *_recorder; // 录音
    NSMutableArray *_recordingQueue; //音频文件数据队列
    
    MAMp3EncodeOperation *_encodeOperation;  //编码
    NSOperationQueue *_opetaionQueue;
    
    NSTimeInterval _duration;
    NSString *_formatType;
    UInt32 _encodeBitRate;
    
    NSLock *_lock;
    
    BOOL _started;
    QMAAudioSessionHelper *_audioSessionHelper;
}

@end

@implementation MARecordTools
- (void)dealloc
{
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)inputQueue:(NSData *)data {
    [_lock lock];
    [_recordingQueue addObject:data];
    [_lock unlock];
}

- (NSData *)popQueueIsLastData:(BOOL *)isLastData {
    NSData *data = nil;
    [_lock lock];
    if (_recordingQueue.count > 0) {
        data = [_recordingQueue objectAtIndex:0];
        [_recordingQueue removeObjectAtIndex:0];
    }
    *isLastData = _recordingQueue.count == 0;
    [_lock unlock];
    return data;
}

- (id)initWithDelegate:(id<MARecordToolsDelegate> )deleagte {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.delegate = deleagte;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    _recordingQueue = [[NSMutableArray alloc] init];
    _opetaionQueue = [[NSOperationQueue alloc] init];
    _lock = [[NSLock alloc] init];
    return self;
}

   - (void)createSessionHelper {
    
    if ([[Weapps sharedApps] respondsToSelector:@selector(createAudioSessionHelplerResumePlayBlock:pauseBlock:)]) {
        @weakify(self);
        _audioSessionHelper = (QMAAudioSessionHelper *)[[Weapps sharedApps] createAudioSessionHelplerResumePlayBlock:^{
            WALOG(@"record interruption end");
            @strongify(self);
            [self resume];
            if ([self.delegate respondsToSelector:@selector(onInterruptionEnd)]) {
                [self.delegate onInterruptionEnd];
            }
        } pauseBlock:^{
            WALOG(@"record interruption begin");
            @strongify(self);
            [self pause];
            if ([self.delegate respondsToSelector:@selector(onInterruptionBegin)]) {
                [self.delegate onInterruptionBegin];
            }
        }];
    }
}

- (void)setupWithDuration:(NSTimeInterval)duration
               formatType:(NSString *)formatType
            encodeBitRate:(UInt32)encodeBitRate
                frameSize:(UInt32)frameSize
              audioSource:(NSString *)audioSource
               sampleRate:(Float64)sampleRate
         numberOfChannels:(UInt32)numberOfChannels {
    if (_started) {
        if ([self.delegate respondsToSelector:@selector(onError:)]) {
            [self.delegate onError:@"正在录音,请先停止录音"];
        }
        return;
    }

    _duration = duration;
    _formatType = formatType;
    _encodeBitRate = encodeBitRate;
    
    AudioStreamBasicDescription streamFormat = {0};
    streamFormat.mSampleRate = sampleRate;
    streamFormat.mChannelsPerFrame = numberOfChannels;
    streamFormat.mBitsPerChannel = 16;
    streamFormat.mBytesPerPacket = streamFormat.mBytesPerFrame = (streamFormat.mBitsPerChannel / 8) * streamFormat.mChannelsPerFrame;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    
    [self formatParams:streamFormat duration:_duration/1000 frameSize:frameSize];
}

- (void)formatParams:(AudioStreamBasicDescription)formatParams duration:(NSTimeInterval)duration frameSize:(UInt32)frameSize {
    
    [_recordingQueue removeAllObjects];
    _duration = duration;
    _recorder = [[MAAudioQueueRecorder alloc] initWithFormat:formatParams duration:duration delegate:self];
    _recorder.frameSize = frameSize;
    _recorder.encodeBitRate = _encodeBitRate;
    _recorder.formatType = _formatType;
    _recorder.recordQueue = _recordingQueue;
    _recorder.recordTools = self;
}

- (void)startWithCompletionHandler:(void (^)(BOOL, NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    if ([[Weapps sharedApps] respondsToSelector:@selector(activeAudioSessionForRecordVoice:)]) {
        [[Weapps sharedApps] activeAudioSessionForRecordVoice:_audioSessionHelper];
    }
    if (_started) {
        WALOG(@"启动失败, 已经在录音");
        if (completionHandler) {
            completionHandler(NO,nil,[NSError errorWithDomain:@"startRecord" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"正在录音,请先停止录音"}]);
        }
        if ([self.delegate respondsToSelector:@selector(onError:)]) {
            [self.delegate onError:@"正在录音,请先停止录音"];
        }
        return;
    }
    
    _isLastFrame = NO;
    [_recordingQueue removeAllObjects];
    
    if (_encodeOperation) {
        _encodeOperation = nil;
    }
    
    _encodeOperation = [[MAMp3EncodeOperation alloc] init];
    _encodeOperation.recordTools = self;
    _encodeOperation.recordQueue = _recordingQueue;
    _encodeOperation.formatType = _recorder.formatType;
    _encodeOperation.format = _recorder.format;
    _encodeOperation.encodeBitRate = _encodeBitRate;
    _encodeOperation.innerPathFile = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                                      [NSString stringWithFormat:@"%d.%@",
                                       arc4random() % 1000000,
                                       _encodeOperation.formatType]];
    _encodeOperation.currentMp3File = [self createRecordPath];
    
    if (_encodeOperation.currentMp3File.length == 0) {
        [self stopWithError:@"文件路径创建失败"];
        if (completionHandler) {
            completionHandler(NO,nil,[NSError errorWithDomain:@"startRecord" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"文件路径创建失败"}]);
        }
        return;
    }
    
    if ([_formatType isEqualToString:@"aac"] && ![_encodeOperation prepareEncoder]) {
        [self stopWithError:@"encoder fail"];
        if (completionHandler) {
            completionHandler(NO,nil,[NSError errorWithDomain:@"startRecord" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"encoder fail"}]);
        }
        return;
    }
    
    BOOL ret = [_recorder start];
    if (!ret) {
        [self stopWithError:@"recorder start fail"];
        if (completionHandler) {
            completionHandler(NO,nil,[NSError errorWithDomain:@"startRecord" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"recorder start fail"}]);
        }
        return;
    }
    
    
    WALOG(@"recordTools start record")
    
    _started = YES;
    [_opetaionQueue addOperation:_encodeOperation];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRecordView:YES];
    });
    if ([self.delegate respondsToSelector:@selector(onStart)]) {
        [self.delegate onStart];
    }
    if (completionHandler) {
        completionHandler(YES,nil,nil);
    }
}

- (NSString *)createRecordPath {
    return _encodeOperation.innerPathFile;
}

- (void)stop {
    
    if ([_formatType isEqualToString:@"mp3"] && _recorder.frameSize > 0) {
        WALOG(@"frame setToStop record");
        self.isLastFrame = YES;
        [_recorder setToStop];
    } else {
        [self forceStop];
    }
    _started = NO;
}

- (void)forceStop {
    WALOG(@"stop now record")
    BOOL ret = [_recorder stop];
    if (!ret) return;
    [_encodeOperation stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRecordView:NO];
    });
    _started = NO;

}

- (void)pause {
    WALOG(@"pause record")
    BOOL ret = [_recorder pause];
    if (!ret) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRecordView:NO];
    });
    if ([self.delegate respondsToSelector:@selector(onPause)]) {
        [self.delegate onPause];
    }
}

- (void)resume {
    WALOG(@"resume record")
    BOOL ret = [_recorder resume];
    if (!ret) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRecordView:YES];
    });
    if ([self.delegate respondsToSelector:@selector(onResume)]) {
        [self.delegate onResume];
    }
}

- (void)mp3dataEncoded:(NSDictionary *)dictionary {
    if (_recorder.frameSize > 0 && [_formatType isEqualToString:@"mp3"] && [dictionary objectForKey:@"frameBuffer"]) {
        BOOL isLastFrame = self.isLastFrame && [dictionary[@"isLastFrame"] boolValue];
        WALOG(@"录音最后一帧 %c",isLastFrame);
        if ([self.delegate respondsToSelector:@selector(onFrameRecorded:frameBuffer:)]) {
            [self.delegate onFrameRecorded:isLastFrame frameBuffer:[dictionary objectForKey:@"frameBuffer"]];
        }
    }
}

- (void)clean {
    _started = NO;
    [_recorder dispose];
    if ([[Weapps sharedApps] respondsToSelector:@selector(deactiveAudioSession:)]) {
        [[Weapps sharedApps] deactiveAudioSession:_audioSessionHelper];
    }
}

- (void)stopWithError:(NSString *)msg {
    WALOG(@" stopWithError %@", msg);
    [_recorder stop];
    [_encodeOperation stop];
    [self clean];
    
    WALOG(@"error record");
    if ([self.delegate respondsToSelector:@selector(onError:)]) {
        [self.delegate onError:msg];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showRecordView:NO];
    });
}

- (void)finish {
    WALOG(@"finish record");
    
    if (_encodeOperation.currentMp3File.length == 0) {
        [self stopWithError:@"获取不到录音文件"];
        return;
    }
    
    NSError *attributesError = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_encodeOperation.currentMp3File error:&attributesError];
    unsigned long long fileSize = [fileAttributes fileSize];
    
    
    NSURL *fileUrl = [NSURL fileURLWithPath:_encodeOperation.currentMp3File];
    NSString *file = _encodeOperation.innerPathFile;
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:fileUrl options:nil];
    [audioAsset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus status = [audioAsset statusOfValueForKey:@"duration" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            CMTime duration = audioAsset.duration;
            NSTimeInterval dur = 0;
            if (duration.value > 0 && duration.timescale > 0) {
                dur = duration.value*1000.0f/duration.timescale;
            }
            [self clean];
            if ([self.delegate respondsToSelector:@selector(onStopWithDuration:tempFilePath:fileSize:)]) {
                [self.delegate onStopWithDuration:dur tempFilePath:file fileSize:fileSize];
            }
        } else {
            WALOG(@"load file duration fail error %tu", error.code);
            if ([self.delegate respondsToSelector:@selector(onStopWithDuration:tempFilePath:fileSize:)]) {
                [self.delegate onStopWithDuration:0 tempFilePath:file fileSize:fileSize];
            }
        }
    }];
}

- (void)audioQueue:(MAAudioQueueRecorder *)inputQueue error:(NSString *)error {
    if ([self.delegate respondsToSelector:@selector(onError:)]) {
        [self.delegate onError:error];
    }
}

- (void)handleEnterBackground:(NSNotification *)notification {
    if (!_started) return;
    [self pause];
}


- (void)showRecordView:(BOOL)show {
//    NSAssert([NSThread isMainThread]);
//    UIView *moreView = [[self application].rootViewController.view.window viewWithTag:MAMoreViewTagInRightView];
//    UIView *recordView = [[self application].rootViewController.view.window viewWithTag:MARecordViewTagInRightView];
//    if (moreView == nil || recordView == nil) {
//        return;
//    }
//    moreView.hidden = show;
//    recordView.hidden = !show;
//    [self showAnimation:show];
}

- (void)showAnimation:(BOOL)show {
//    MAAssert([NSThread isMainThread]);
//    UIView *recordView = [[self application].rootViewController.view.window viewWithTag:MARecordViewTagInRightView];
//    if (recordView == nil) {
//        return;
//    }
//    if (show) {
//        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//        animation.fromValue = [NSNumber numberWithFloat:1.0f];
//        animation.toValue = [NSNumber numberWithFloat:0.0f];
//        animation.autoreverses = YES;
//        animation.duration = 1.0;
//        animation.repeatCount = MAXFLOAT;
//        animation.removedOnCompletion = NO;
//        animation.fillMode = kCAFillModeForwards;
//        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//
//        [recordView.layer addAnimation:animation forKey:@"recordAnimate"];
//    } else {
//        [recordView.layer removeAnimationForKey:@"recordAnimate"];
//    }
    
}

@end
