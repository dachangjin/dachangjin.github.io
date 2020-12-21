//
//  MACameraView+Private.h
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/21.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MACameraView.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface MACameraView (Private)

- (CGFloat)compressionQualityWithQuality:(NSString *)quality;

- (AVCaptureVideoOrientation)orientationForConnection;

- (AVCaptureFlashMode)flashModeWithFlash:(NSString *)flash;

- (AVCaptureDevice *)cameraWithDevicePosition:(NSString *)devicePosition;

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position;

- (UIImage *)cropImage:(UIImage *)image usingPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer;

+ (CGImageRef)convertSamepleBufferRefToCGImage:(CMSampleBufferRef)sampleBufferRef;

@end
NS_ASSUME_NONNULL_END
