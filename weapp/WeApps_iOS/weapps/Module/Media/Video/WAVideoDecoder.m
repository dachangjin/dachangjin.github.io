//
//  WAVideoDecoder.m
//  weapps
//
//  Created by tommywwang on 2020/8/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVideoDecoder.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "Heap.h"
#import "NSData+Base64.h"
#import "WAMediaUtils.h"
#import "IdGenerator.h"

@interface WAVideoFrame : NSObject

@property (nonatomic, assign) CGFloat pts;
@property (nonatomic, assign) CGFloat dts;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) NSData *data;


@end

@implementation WAVideoFrame


@end


@protocol WAVideoFrameBufferProtocol <NSObject>

- (BOOL)isEmpty;

- (WAVideoFrame *)getFrame;

- (void)addFrame:(WAVideoFrame *)frame;

- (BOOL)isFull;

- (void)clear;

@end

@interface WAHeapAdapter : NSObject <WAVideoFrameBufferProtocol>
{
    Heap *_heap;
    NSUInteger _maxSize;
    NSCondition *_lock;
}


@end

@implementation WAHeapAdapter

- (instancetype)initWithMaxSize:(NSUInteger)maxSize
                     comparator:(Comparator)comparator
{
    self = [super init];
    if (self) {
        _maxSize = maxSize;
        _heap = [[Heap alloc] initWithComparator:comparator];
        _lock = [[NSCondition alloc] init];
    }
    return self;
}

- (BOOL)isEmpty
{
    BOOL isEmpty;
    [_lock lock];
    isEmpty = [_heap isEmpty];
    [_lock unlock];
    return isEmpty;
}

- (WAVideoFrame *)getFrame
{

    [_lock lock];
    WAVideoFrame *frame = nil;
    if (![_heap isEmpty]) {
        frame = [_heap remove];
    }
    [_lock signal];
    [_lock unlock];
    return frame;
}

- (void)addFrame:(WAVideoFrame *)frame
{
    [_lock lock];
    while (_heap.size >= _maxSize) {
       [_lock wait];
    }
    [_heap add:frame];
    [_lock unlock];
}

- (BOOL)isFull
{
    BOOL isFull;
    [_lock lock];
    isFull = _heap.size >= _maxSize;
    [_lock unlock];
    return isFull;
}

- (void)clear
{
    [_lock lock];
    [_lock signal];
    [_heap clear];
    [_lock unlock];
}

@end


@interface WAArrayAdapter : NSObject <WAVideoFrameBufferProtocol>
{
    NSMutableArray *_array;
    NSUInteger _maxSize;
    NSCondition *_lock;
}
@end

@implementation WAArrayAdapter

- (instancetype)initWithMaxSize:(NSUInteger)maxSize
{
    self = [super init];
    if (self) {
        _maxSize = maxSize;
        _lock = [[NSCondition alloc] init];
        _array = [NSMutableArray arrayWithCapacity:maxSize];
    }
    return self;
}

- (BOOL)isEmpty
{
    BOOL isEmpty;
    [_lock lock];
    isEmpty = _array.count == 0;
    [_lock unlock];
    return isEmpty;
}

- (WAVideoFrame *)getFrame
{
    if ([self isEmpty]) {
        return nil;
    }
    [_lock lock];
    WAVideoFrame *frame = [_array firstObject];
    [_array removeObject:frame];
    [_lock signal];
    [_lock unlock];
    return frame;
}

- (void)addFrame:(WAVideoFrame *)frame
{
    [_lock lock];
    while (_array.count >= _maxSize) {
        [_lock wait];
    }
    [_array addObject:frame];
    [_lock unlock];
}

- (BOOL)isFull
{
    BOOL isFull;
    [_lock lock];
    isFull = _array.count >= _maxSize;
    [_lock unlock];
    return isFull;
}

- (void)clear
{
    [_lock lock];
    [_array removeAllObjects];
    [_lock signal];
    [_lock unlock];
}
@end


typedef NS_ENUM(NSUInteger, WAVideoDecoderBufferType) {
    WAVideoDecoderBufferTypePts,    //以pts顺序储存，使用heap
    WAVideoDecoderBufferTypeDts     //以dts顺序储存，使用array
};

@interface WAVideoFrameBuffer : NSObject

@property (nonatomic, assign) NSUInteger maxSize;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) id<WAVideoFrameBufferProtocol> container;


- (BOOL)isEmpty;

- (WAVideoFrame *)getFrame;

- (void)addFrame:(WAVideoFrame *)frame;

- (BOOL)isFull;

- (void)clear;
@end

@implementation WAVideoFrameBuffer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _maxSize = 10;
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (instancetype)initWithMaxSize:(NSUInteger)maxSize andType:(WAVideoDecoderBufferType)type
{
    self = [super init];
    if (self) {
        _maxSize = maxSize;
        _lock = [[NSLock alloc] init];
        if (type == WAVideoDecoderBufferTypeDts) {
            _container = [[WAArrayAdapter alloc] initWithMaxSize:maxSize];
        } else {
            _container = [[WAHeapAdapter alloc] initWithMaxSize:maxSize comparator:^int(WAVideoFrame  *value1, WAVideoFrame  *value2) {
                return value2.pts - value1.pts;
            }];
        }
    }
    return self;
}


- (BOOL)isEmpty
{
    return [_container isEmpty];
}

- (WAVideoFrame *)getFrame
{
    return [_container getFrame];
}

- (void)addFrame:(WAVideoFrame *)frame
{
    [_container addFrame:frame];
}

- (BOOL)isFull
{
    return [_container isFull];
}

- (void)clear
{
    [_container clear];
}
@end


@interface WAVideoDecoder ()
{
    
    WAVideoFrameBuffer *_buffer;
    dispatch_queue_t _decodeQueue;
}

@property (nonatomic, assign) BOOL isStopped;
@property (nonatomic, assign) BOOL isReset;
@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) WAVideoFrameBuffer *buffer;
@property (nonatomic, strong) AVAssetReaderTrackOutput *videoTrackOutput;
@end

@implementation WAVideoDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isStopped = NO;
        _isReset = NO;
        _lock = [[NSLock alloc] init];
        _decodeQueue = dispatch_queue_create("com.weapps.decode", DISPATCH_QUEUE_SERIAL);
        _decoderId = @([IdGenerator generateIdWithClass:[self class]]);
    }
    return self;
}

- (void)startWithSource:(NSString *)source
                   mode:(WAVideoDecoderMode)mode
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (_reader) {
        [_reader cancelReading];
    }
    NSError *error;
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:source]];
    _reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    _videoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:@{
        (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
    }];
    _videoTrackOutput.alwaysCopiesSampleData = NO;
    [_reader addOutput:_videoTrackOutput];
    _buffer = [[WAVideoFrameBuffer alloc] initWithMaxSize:10
                                                  andType:
               mode == WAVideoDecoderModeDts ? WAVideoDecoderBufferTypeDts : WAVideoDecoderBufferTypePts];
    
    BOOL success = [_reader startReading];
    if (completionHandler) {
        completionHandler(success, _reader.error);
    }
    if (success) {
        [self beginDecode];
        if (_didStartBlock) {
            _didStartBlock([WAMediaUtils queryVideoResolutionWithAssetTrack:track]);
        }
    }
}


- (void)seekTo:(CGFloat)time completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    CMTime cmTime = CMTimeMake(time, 1000);

    if (CMTIME_IS_INDEFINITE(cmTime) ||
        CMTIME_IS_INVALID(cmTime) ||
        time < 0 ||
        time >= CMTimeGetSeconds(_reader.asset.duration) * 1000) { //!OCLINT:bitwise operator in conditional
        WALOG(@"WAVideoDecoder: INDEFINITE TIME ");
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"position is not valid or beyond video duration"
            }]);
        }
        return;
    }
    if (!_isStopped && _videoTrackOutput) {
        //先取消，再seek，然后start
        [_lock lock];
        [_reader cancelReading];
        _isReset = YES;
        [_lock unlock];
        
        NSError *error;
        _reader = [AVAssetReader assetReaderWithAsset:_reader.asset error:&error];
        AVAssetTrack *track = [[_reader.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        _videoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:@{
            (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
        }];
        _videoTrackOutput.alwaysCopiesSampleData = NO;
        [_reader addOutput:_videoTrackOutput];
        [_reader setTimeRange:CMTimeRangeMake(cmTime, kCMTimePositiveInfinity)];
        BOOL success = [_reader startReading];
        if (!success) {
            return;
        }
        if (completionHandler) {
            completionHandler(success, _reader.error);
        }
        //清空seek前的frame
        
        [_buffer clear];
        [self beginDecode];
        if (self.didSeekBlock) {
            self.didSeekBlock(time);
        }
    } else {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"videoDecoder is stopped"
            }]);
        }
    }
}

- (void)stopWithCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    [_lock lock];
    if (_isStopped) {
        [_lock unlock];
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:@"stop" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"videoDecoder is stopped"
            }]);
        }
        return;
    }
    _isStopped = YES;
    [_reader cancelReading];
    [_lock unlock];
    [_buffer clear];
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}


- (NSDictionary *)getFrameData
{
    WAVideoFrame *frame = [self.buffer getFrame];
    if (!frame) {
        return nil;
    }
    return @{
        @"width"    : @(frame.width),
        @"height"   : @(frame.height),
        @"data"     : [frame.data base64String] ?: @"",
        @"pkPts"    : @(frame.pts),
        @"pkDts"    : @(frame.dts)
    };
}


#pragma mark - private

- (void)beginDecode
{
    @weakify(self)
    dispatch_async(_decodeQueue, ^{
        @strongify(self)
        [self.buffer clear];
        [self.lock lock];
        self.isReset = NO;
        [self.lock unlock];
        while ([self.reader status] == AVAssetReaderStatusReading) {
            
            // 读取 video sample
            [self.lock lock];
            if (self.isStopped || self.isReset) {
                [self.lock unlock];
                break;
            }
            
            if ([self.reader status] == AVAssetReaderStatusCancelled) {
                return;
            }
            //锁住copyNextSampleBuffer方法，防止cancel后调用
            CMSampleBufferRef videoBuffer = [self.videoTrackOutput copyNextSampleBuffer];
            [self.lock unlock];
            if (videoBuffer == NULL) {
                
                if (self.reader.status == AVAssetReaderStatusCompleted) {
                    if (self.didEndBlock) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.didEndBlock();
                        });
                    }
                    break;
                } else if (self.reader.status == AVAssetReaderStatusCancelled) {
                    //手动停止或seek（seek需要取消后重新start）
                    [self.lock lock];
                    if (self.isStopped) {
                        //手动停止
                        if (self.didStopBlock) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.didStopBlock();
                            });
                        }
                    }
                    [self.lock unlock];
                    break;
                } else if (self.reader.status == AVAssetReaderStatusFailed) {
                    WALOG(@"WAVideoDecoder beginDecode:error: %@",self.reader.error.description);
                    break;
                }
            } else {
                [self addFrameToBuffer:videoBuffer];
            }
        }
        [self.lock lock];
        if (self.isStopped) {
            //手动停止
            if (self.didStopBlock) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.didStopBlock();
                });
            }
        }
        [self.lock unlock];
    });
}

- (void)addFrameToBuffer:(CMSampleBufferRef)sampleBufferRef
{
    [self.lock lock];
    if (!self.isStopped) {
        [self.lock unlock];
        WAVideoFrame *videoframe = [[WAVideoFrame alloc] init];
        // 为媒体数据设置一个CMSampleBufferRef
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
        // 锁定 pixel buffer 的基地址
        CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
        NSData *data = [NSData dataWithBytes:baseAddress length:bufferSize];
        videoframe.data = data;
        videoframe.width = CVPixelBufferGetWidth(imageBuffer);
        videoframe.height = CVPixelBufferGetHeight(imageBuffer);
        CMTime dts = CMSampleBufferGetDecodeTimeStamp(sampleBufferRef);
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBufferRef);
        if (CMTIME_IS_VALID(dts)) {
            videoframe.dts = CMTimeGetSeconds(dts) * 1000;
        } else {
            videoframe.dts = 0;
        }
        if (CMTIME_IS_VALID(pts)) {
            videoframe.pts = CMTimeGetSeconds(pts) * 1000;
        } else {
            videoframe.pts = 0;
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
        CFRelease(sampleBufferRef);
        [self.buffer addFrame:videoframe];
    } else {
        [self.lock unlock];
    }
}

@end

