//
//  MAAssetWriter.m
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/21.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MAAssetWriter.h"
#import <UIKit/UIKit.h>

@interface MAAssetWriter()
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, assign) CGSize cropSize;
@property (nonatomic, strong) NSURL *recordingURL;
@end

@implementation MAAssetWriter
- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize
{
    if (self = [super init]) {
        
        _recordingURL = URL;
        
        if (cropSize.width == 0 || cropSize.height == 0) {
            _cropSize = [UIScreen mainScreen].bounds.size;
        } else {
            _cropSize = cropSize;
        }
        
        [self prepareRecording];
    }
    return self;
}

- (void)prepareRecording
{
    self.assetWriter = [AVAssetWriter assetWriterWithURL:self.recordingURL fileType:AVFileTypeMPEG4 error:nil];
    
//    // 码率和帧率设置
//    NSInteger bitsPerSecond = _cropSize.width * _cropSize.height * 12.0;
//    NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
//                                             AVVideoExpectedSourceFrameRateKey : @(30),
//                                             AVVideoMaxKeyFrameIntervalKey : @(30),
//                                             AVVideoProfileLevelKey : AVVideoProfileLevelH264MainAutoLevel };
    
    CGFloat width = _cropSize.width * [UIScreen mainScreen].scale;
    CGFloat height = _cropSize.height * [UIScreen mainScreen].scale;
    
    NSDictionary *videoCompressionSettings =  @{ AVVideoCodecKey : AVVideoCodecH264,
                                                 AVVideoWidthKey : @(width),
                                                 AVVideoHeightKey : @(height),
                                                 AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                                 /*AVVideoCompressionPropertiesKey : compressionProperties */
                                                 
                                                 };
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
    self.videoInput.expectsMediaDataInRealTime = YES;
    //        self.assetWriterVideoInput.transform = [self _transformForConnection];
    
    NSDictionary *sourcePixelBufferAttributesDictionary = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)
                                                             };
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor
                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput
                    sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    
    NSDictionary *audioCompressionSettings = @{ AVEncoderBitRateKey: @(64000),
                                                AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                AVNumberOfChannelsKey : @(1),
                                                AVSampleRateKey : @(44100) };
    
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
    self.audioInput.expectsMediaDataInRealTime = YES;
    
    if ([self.assetWriter canAddInput:self.videoInput])
    {
        [self.assetWriter addInput:self.videoInput];
    }
    
    if ([self.assetWriter canAddInput:self.audioInput])
    {
        [self.assetWriter addInput:self.audioInput];
    }
    
    
}

- (void)startRecording:(CMSampleBufferRef)sampleBuffer
{
    if (self.assetWriter.status == AVAssetWriterStatusUnknown) {
        [self.assetWriter startWriting];
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
    }
}

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler
{
    // markAsFinished的时候,assetWriter.status不能是Unknown或Completed，否则会抛异常
    if (self.assetWriter.status == AVAssetWriterStatusUnknown ||
        self.assetWriter.status == AVAssetWriterStatusCompleted) {
        if (handler) {
            handler();
        }
        return;
    }
    
    [self.videoInput markAsFinished];
    
    [self.assetWriter finishWritingWithCompletionHandler:^{
        self.assetWriter = nil;
        self.videoInput = nil;
        self.audioInput = nil;
        if (handler) {
            handler();
        }
    }];
}

- (BOOL)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.audioInput.readyForMoreMediaData) {
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        return [self.audioInput appendSampleBuffer:sampleBuffer];
    }
    
//    if (self.assetWriter.status != AVAssetExportSessionStatusUnknown) {
//       return [self.videoInput appendSampleBuffer:sampleBuffer];
//    }
    return YES;
}

- (BOOL)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.videoInput.readyForMoreMediaData) {
        [self.assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        return [self.videoInput appendSampleBuffer:sampleBuffer];
    }
//    if (self.assetWriter.status != AVAssetExportSessionStatusUnknown) {
//       return [self.audioInput appendSampleBuffer:sampleBuffer];
//    }
    return YES;
}
@end
