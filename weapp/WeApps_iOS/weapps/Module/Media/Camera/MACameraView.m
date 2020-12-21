//
//  MACameraView.m
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/16.
//  Copyright © 2020 tencent. All rights reserved.
//
#import "MACameraView.h"
#import <AVFoundation/AVFoundation.h>
#import "UIImage+Addition.h"
#import "MAAssetWriter.h"
#import "MACameraView+Private.h"
#import "IdGenerator.h"

@interface MACameraView() <AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureMetadataOutputObjectsDelegate>
@property(nonatomic, strong) AVCaptureSession *session; // 媒体管理会话
@property(nonatomic, strong) AVCaptureDevice *device; // 摄像头设备
@property(nonatomic, strong) AVCaptureStillImageOutput *imageOutput;  // 图片输出流
@property(nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;   // 视频输出流
@property(nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;   // 音频输出流
@property(nonatomic, strong) AVCaptureMetadataOutput *metadataOutput; // 二维码数据
@property(nonatomic, strong) MAAssetWriter *assetWriter;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *captureLayer; // 视频预览图层
@property(nonatomic, strong) dispatch_queue_t videoQueue;
@property(nonatomic, copy) MACameraViewInitResultBlock initResultBlock;
@property(nonatomic, assign) BOOL isShooting; //正在拍摄
@property(nonatomic, assign) BOOL thumbIsExit; // 缩略图
@property(nonatomic, assign) CGSize cropSize;
@property(nonatomic, weak) NSTimer *timer;
@end



@implementation MACameraView
- (instancetype)initCameraWithFrame:(CGRect)frame
                             resolution:(NSString *)resolution
                             result:(MACameraViewInitResultBlock)initResultBlock
{
    if (self = [super initWithFrame:frame]) {
        self.initResultBlock = initResultBlock;
        _resolution = resolution;
        _cropSize = frame.size;
//        _cameraId = [IdGenerator generateIdWithClass:[self class]];
    }
    return self;
}


-(void)removeFromSuperview
{
    [self stopRunning];
    
    [super removeFromSuperview];
}
- (void)startRunning
{
    dispatch_async(self.videoQueue, ^{
        [self _setupCaptureSession];
        if (![self.session isRunning]) {
            [self.session startRunning];
        }
    });
}
- (void)stopRunning
{
    dispatch_async(self.videoQueue, ^{
        if ([self.session isRunning]) {
            [self.session stopRunning];
        }
    });
   
}

- (void)clean
{
    [self stopRunning];
    if (_timer) {
        [_timer invalidate];
    }
    self.photoResultBlock = nil;
    self.videoResultBlock = nil;
    self.videoFrameBlock = nil;
}

- (void)takePhotoWithQuality:(NSString *)quality
{
    if ([self.photoPath length] == 0) {
        if (self.photoResultBlock) {
            self.photoResultBlock(NO, [NSError errorWithDomain:@"photoPath is nil" code:-11 userInfo:nil], nil);
            self.photoResultBlock = nil;
        }
        return;
    }
    
    [self startRunning];
    
    dispatch_async(self.videoQueue, ^{
        AVCaptureConnection *captureConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
        @weakify(self)
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:captureConnection
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            @strongify(self)
            if (imageDataSampleBuffer != NULL) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                image = [self cropImage:image usingPreviewLayer:self.captureLayer];
                image = [image fixOrientation];
                
                // 对比了微信的体验，high、nomal、low三种质量的图片，图片的分辨率是一样的，只是质量因子不同
                
                CGFloat compressionQuality = [self compressionQualityWithQuality:quality];
                
                NSData *compressedJpegData = UIImageJPEGRepresentation(image, compressionQuality);
                UIImage *compressedimage = [[UIImage alloc] initWithData:compressedJpegData];
                
                NSData *compressedPngData = UIImagePNGRepresentation(compressedimage);
                NSError *error = nil;
                BOOL success = [compressedPngData writeToFile:self.photoPath options:NSDataWritingAtomic error:&error];
                
                if (self.photoResultBlock) {
                    self.photoResultBlock(success, error, self.photoPath);
                    self.photoResultBlock = nil;
                }
            }
        }];
    });
}
- (void)startRecord
{
    if (self.videoPath.length == 0 || self.thumbPath.length == 0) {
        if (self.videoResultBlock) {
            self.videoResultBlock(NO, [NSError errorWithDomain:@"videoPath or thumbPath is nil" code:-11 userInfo:nil], nil, nil);
            self.videoResultBlock = nil;
        }
        return;
    }
    
    if (!_isShooting) {
        _isShooting = YES;
        self.thumbIsExit = NO;
        
        [self startRunning];
        _timer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(stopRecord:) userInfo:_timer repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
}



- (void)stopRecord:(id)userInfo
{
    if (_isShooting) {
        BOOL isStopByTimer = NO;
        if ([userInfo isEqual:_timer]) {
            isStopByTimer = YES;
        }
        if ([_timer isValid]) {
            [_timer invalidate];
        }
        _isShooting = NO;
        @weakify(self);
        [self.assetWriter finishRecordingWithCompletionHandler:^{
            @strongify(self);
            self.assetWriter = nil;
            
            
            if (isStopByTimer) {
                if (self.videoTimeoutBlock) {
                    self.videoTimeoutBlock(YES, nil, [NSURL fileURLWithPath:self.videoPath], self.thumbPath);
                }
            } else {
                if (self.videoResultBlock) {
                    self.videoResultBlock(YES, nil, [NSURL fileURLWithPath:self.videoPath], self.thumbPath);
                    self.videoResultBlock = nil;
                }
            }
        }];
    }
}

- (void)setupFlash:(NSString *)flash
{
    if ([self.flash isEqualToString:flash]) {
        return;
    }
    self.flash = flash;
    [self _setupFlashMode];
}

- (void)setZoom:(CGFloat)zoom withCompletion:(void(^)(BOOL success, NSError *error))completionHandler
{
    if (zoom > self.device.activeFormat.videoMaxZoomFactor) {
        zoom = self.device.activeFormat.videoMaxZoomFactor;
    } else if (zoom < 1) {
        zoom = 1;
    }
    NSError *error;
    if ([self.device lockForConfiguration:&error]) {
        [self.device rampToVideoZoomFactor:zoom withRate:2];
        [self.device unlockForConfiguration];
    }
    if (!error) {
        completionHandler(YES, nil);
    } else {
        completionHandler(NO, error);
    }
}

- (void)switchCamera:(NSString *)devicePosition
{
    // 如果当前摄像头和参数没有变化，就直接return
    if ([self.devicePosition isEqualToString:devicePosition]) {
        return;
    }
    
    self.devicePosition = devicePosition;
    
    for (AVCaptureDeviceInput *input in self.session.inputs) {
        if (input.device == self.device) {
            self.device = [self cameraWithDevicePosition:self.devicePosition];
            NSError *error = nil;
            AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
            // deviceInputWithDevice 失败的时候，newInput是nil，下面add的时候会crash
            if (error) {
                WALOG(@"macamaraview -- deviceInputWithDevice fail：%@", error.description);
                break;
            }
            
            [self.session beginConfiguration];
            
            [self.session removeInput:input];
            [self.session addInput:newInput];
            
            [self.session commitConfiguration];
        }
    }
}
- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("MACameraView", DISPATCH_QUEUE_SERIAL);
    }
    
    return _videoQueue;
}
- (void)_setupCaptureSession
{
    if (self.session) {
        return;
    }
    
    // 3. 创建会话，添加输入
    self.session = [AVCaptureSession new];
    if([self.session canSetSessionPreset:AVCaptureSessionPresetLow] && [_resolution isEqualToString:@"low"] ) {
        self.session.sessionPreset = AVCaptureSessionPresetLow;
    } else if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh] && [_resolution isEqualToString:@"high"]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    } else {
        self.session.sessionPreset = AVCaptureSessionPresetMedium;
    }
    
    NSError *error = nil;
    // 1. 获取摄像头设备
    [self _initCaptureDevice:&error];
    if (error) {
        [self initFail:error];
        return;
    }
    // 2. 创建画面输入对象
    [self _initCaptureInput:&error];
    if (error) {
        [self initFail:error];
        return;
    }
    if ([@"scanCode" isEqualToString:self.mode]) {
        [self _initMetaDataOutput];
    } else {
        // 3. 创建音频输入对象
        [self _initCaptureAudio:&error];
        if (error) {
            [self initFail:error];
            return;
        }
        
        // 4. 创建图片&视频&音频输出对象
        [self _initImageOutput];
        [self _initVideoOutput];
        [self _initAudioOutput];
    }
    
    // 5. 创建视频预览图层,startRunning放在子线程了，这里要切换到主线程执行
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self _setupCaptureLayer];
    });
    
    if (self.initResultBlock) {
        self.initResultBlock(YES, self.device.activeFormat.videoMaxZoomFactor);
    }
    
}
- (void)initFail:(NSError *)error
{
    WALOG(@"macameraview -- init camera fail：%@", error.description);
    if (self.initResultBlock) {
        self.initResultBlock(NO, 0);
    }
    self.session = nil;
}
#pragma mark - camera init
- (void)_initCaptureDevice:(NSError **)error
{
    self.device = [self cameraWithDevicePosition:self.devicePosition];
    if (!self.device) {
        *error = [NSError errorWithDomain:@"摄像头错误" code:-12 userInfo:nil];
        return;
    }
    [self _setupCaptureDevice];
}
- (void)_initCaptureInput:(NSError **)error
{
    AVCaptureDeviceInput *captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:error];
    if (*error) {
        return;
    }
    if ([self.session canAddInput:captureInput]) {
        [self.session addInput:captureInput];
    }
}
- (void)_initCaptureAudio:(NSError **)error
{
    AVCaptureDevice *audioCaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:error];
    if (*error) {
        return;
    }
    
    if ([self.session canAddInput:audioDeviceInput]) {
        [self.session addInput:audioDeviceInput];
    }
}
- (void)_initImageOutput
{
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{ AVVideoCodecKey : AVVideoCodecJPEG
                                      };
    [self.imageOutput setOutputSettings:outputSettings];
    
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
}
- (void)_initVideoOutput
{
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
        
        AVCaptureConnection *videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([videoConnection isVideoStabilizationSupported]) {
            videoConnection.preferredVideoStabilizationMode=AVCaptureVideoStabilizationModeAuto;
        }
        
        videoConnection.videoOrientation = [self orientationForConnection];
    }
}

- (void)_initAudioOutput
{
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    
    if ([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
}
- (void)_initMetaDataOutput
{
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    if ([self.session canAddOutput:self.metadataOutput]) {
        [self.session addOutput:self.metadataOutput];
        
        //设置扫码支持的编码格式
        self.metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeAztecCode,
                                                    AVMetadataObjectTypeUPCECode,
                                                    AVMetadataObjectTypeCode39Code,
                                                    AVMetadataObjectTypeEAN13Code,
                                                    AVMetadataObjectTypeEAN8Code,
                                                    AVMetadataObjectTypeCode93Code,
                                                    AVMetadataObjectTypeCode128Code,
                                                    AVMetadataObjectTypePDF417Code,
                                                    AVMetadataObjectTypeQRCode,
                                                    AVMetadataObjectTypeAztecCode,
                                                    AVMetadataObjectTypeITF14Code,
                                                    AVMetadataObjectTypeDataMatrixCode];
    }
}
#pragma mark - camera setting
-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    CGRect bounds = self.bounds;
    self.captureLayer.bounds = bounds;
    self.captureLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}
- (void)_setupCaptureLayer
{
    CGRect bounds = self.bounds;
    self.captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.captureLayer.bounds = bounds;
    self.captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.captureLayer.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    
    [self.layer insertSublayer:self.captureLayer atIndex:0];
}


- (void)_setupCaptureDevice
{
    // 自动聚焦
//    if ([self.device lockForConfiguration:nil]) {
//        if([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
//            self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
//        }
//
//        self.device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
//        [self.device unlockForConfiguration];
//    }
    // 闪光灯
    [self _setupFlashMode];
}
- (void)_setupFlashMode
{
    if ([self.device lockForConfiguration:nil]) {
        AVCaptureFlashMode flashMode = [self flashModeWithFlash:self.flash];
        
        if ([self.device isFlashModeSupported:flashMode]) {
            self.device.flashMode = flashMode;
        }
        
        [self.device unlockForConfiguration];
    }
}
#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
     
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        
        if (self.scanCodeBlock) {
            self.scanCodeBlock(metadataObject.stringValue, metadataObject.type);
        }
    }
}
#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (sampleBuffer == NULL) {
        WALOG(@"macameraview empty sampleBuffer");
        return;
    }
    //视频
    if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
        @synchronized(self) {
            if (self.isShooting) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
            }
            if (self.videoFrameBlock) {
                size_t width;
                size_t height;
                NSData *data = [self imageDataAndWidth:&width height:&height fromSampleBuffer:sampleBuffer];
                self.videoFrameBlock(width, height, data);
            }
        }
    }
    //音频
    if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
        @synchronized(self) {
            if (self.isShooting) {
                [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
            }
        }
    }
}

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    @autoreleasepool {
        if (!self.assetWriter) {
            self.assetWriter  = [[MAAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:self.videoPath] cropSize:_cropSize];
            [self.assetWriter startRecording:sampleBuffer];
        }
        
        //写入视频数据
        if (mediaType == AVMediaTypeVideo) {
            
            [self writeVideoThumb:sampleBuffer];
            BOOL success = [self.assetWriter appendVideoBuffer:sampleBuffer];
            if (!success) {
                @synchronized (self) {
                    [self stopRecord:nil];
                }
            }
        }
        //写入音频数据
        if (mediaType == AVMediaTypeAudio) {
            BOOL success = [self.assetWriter appendAudioBuffer:sampleBuffer];
            if (!success) {
                @synchronized(self) {
                    [self stopRecord:nil];
                }
            }
        }
    }
}

- (void)writeVideoThumb:(CMSampleBufferRef)sampleBuffer
{
    // 写视频封面
    if (!self.thumbIsExit) {
        CGImageRef cgImage = [MACameraView convertSamepleBufferRefToCGImage:sampleBuffer];
        
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        CGFloat cropHeight = _cropSize.height * (width/ _cropSize.width);
        CGRect cropRect = CGRectMake(0, (height -  cropHeight)/2, width , cropHeight);
        
        CGImageRef cropCGImage = CGImageCreateWithImageInRect(cgImage, cropRect);
        UIImage *image = [UIImage imageWithCGImage:cropCGImage];
        CGImageRelease(cropCGImage);
        
        if (image) {
            NSData *clopImageData = UIImageJPEGRepresentation(image, 0.9);
            NSError *error = nil;
            self.thumbIsExit = [clopImageData writeToFile:self.thumbPath options:NSDataWritingAtomic error:&error];
        }
    }
}


- (NSData *)imageDataAndWidth:(size_t *)width height:(size_t *)height fromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width_t = CVPixelBufferGetWidth(imageBuffer);
    size_t height_t = CVPixelBufferGetHeight(imageBuffer);
    *width = width_t;
    *height = height_t;
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width_t, height_t, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(quartzImage);
    
    NSData *data = (__bridge_transfer NSData *)CGDataProviderCopyData(dataProvider);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return data;
}

- (void)dealloc
{
    WALOG(@"camera die ************");
}
@end
