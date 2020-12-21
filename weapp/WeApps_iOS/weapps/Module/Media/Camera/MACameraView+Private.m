//
//  MACameraView+Private.m
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/21.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MACameraView+Private.h"

@implementation MACameraView (Private)

- (CGFloat)compressionQualityWithQuality:(NSString *)quality
{
    CGFloat compressionQuality = 0.1;
    if ([quality isEqualToString:@"high"]) {
        compressionQuality = 0.85;
    } else if ([quality isEqualToString:@"normal"]) {
        compressionQuality = 0.65;
    }  else if ([quality isEqualToString:@"low"]) {
        compressionQuality = 0.45;
    }
    return compressionQuality;
}

- (AVCaptureVideoOrientation)orientationForConnection
{
    AVCaptureVideoOrientation videoOrientation = AVCaptureVideoOrientationPortrait;
    switch ([UIDevice currentDevice].orientation) {
        case UIDeviceOrientationLandscapeLeft:
            videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        default:
            videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
    }
    return videoOrientation;
}

- (AVCaptureFlashMode)flashModeWithFlash:(NSString *)flash
{   //auto/on/off
    AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
    if ([@"on" isEqualToString:flash]) {
        flashMode = AVCaptureFlashModeOn;
    } else if ([@"auto" isEqualToString:flash]) {
        flashMode = AVCaptureFlashModeAuto;
    }
    return flashMode;
}

- (AVCaptureDevice *)cameraWithDevicePosition:(NSString *)devicePosition
{
    AVCaptureDevicePosition position = AVCaptureDevicePositionUnspecified;
    if ([devicePosition isEqualToString:@"back"]) {
        position =  AVCaptureDevicePositionBack;
    } else if ([devicePosition isEqualToString:@"front"]){
        position =  AVCaptureDevicePositionFront;
    }
    return [self cameraWithPosition:position];
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position){
            return device;
        }
    }
    // TODO: 这里要不要返回一个默认值???
    return nil;
}

+ (CGImageRef)convertSamepleBufferRefToCGImage:(CMSampleBufferRef)sampleBufferRef
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    CFAutorelease(quartzImage);
    
    return quartzImage;
}

- (UIImage *)cropImage:(UIImage *)image usingPreviewLayer:(AVCaptureVideoPreviewLayer *)previewLayer
{
    if (!image) {
        return nil;
    }
    CGRect previewBounds = previewLayer.bounds;
    CGRect outputRect = [previewLayer metadataOutputRectOfInterestForRect:previewBounds];
    
    CGImageRef takenCGImage = image.CGImage;
    size_t width = CGImageGetWidth(takenCGImage);
    size_t height = CGImageGetHeight(takenCGImage);
    CGRect cropRect = CGRectMake(outputRect.origin.x * width, outputRect.origin.y * height,
                                 outputRect.size.width * width, outputRect.size.height * height);
    
    CGImageRef cropCGImage = CGImageCreateWithImageInRect(takenCGImage, cropRect);
    image = [UIImage imageWithCGImage:cropCGImage scale:1 orientation:image.imageOrientation];
    CGImageRelease(cropCGImage);
    
    return image;
}

@end
