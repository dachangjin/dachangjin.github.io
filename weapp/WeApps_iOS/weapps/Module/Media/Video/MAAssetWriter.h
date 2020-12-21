//
//  MAAssetWriter.h
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/21.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface MAAssetWriter : NSObject
/*
 *
 */
- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize;

- (void)startRecording:(CMSampleBufferRef)sampleBuffer;

- (void)finishRecordingWithCompletionHandler:(void (^)(void))handler;

- (BOOL)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer;

- (BOOL)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer;

@end
NS_ASSUME_NONNULL_END
