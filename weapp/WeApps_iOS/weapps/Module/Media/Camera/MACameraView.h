//
//  MACameraView.h
//  MiniAppSDK
//
//  Created by elvisgao on 2019/1/16.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "WAContainerView.h"

typedef void (^MACameraViewInitResultBlock)(BOOL success, CGFloat maxZoomFator);
typedef void (^MACameraViewPhotoResultBlock)(BOOL success, NSError *error, NSString *photoPath);
typedef void (^MACameraViewVideoResultBlock)(BOOL success, NSError *error, NSURL *videoURL, NSString *thumbPath);
typedef void (^MACameraViewVideoFrameBlock)(CGFloat width, CGFloat heght, NSData *bytes);

typedef void (^MACameraViewScanCodeResultBlock)(NSString *result, NSString *type);


@interface MACameraView : WAContainerView
#pragma mark - setting
//@property(nonatomic, assign, readonly) NSInteger cameraId;
// 摄像头 front/back
@property(nonatomic, copy) NSString  *devicePosition;
// 闪光灯 auto/on/off
@property(nonatomic, copy) NSString  *flash;
//相机的帧数据尺寸
@property (nonatomic, copy) NSString *frameSize;
//分辨率
@property (nonatomic, copy, readonly) NSString *resolution;
// 模式 normal/scanCode
@property(nonatomic, copy) NSString  *mode;
// TODO: 应该是滤镜相关
@property(nonatomic, copy) NSString  *filter;
#pragma mark - output
@property(nonatomic, copy) NSString *photoPath;

@property(nonatomic, copy) NSString *videoPath;
@property(nonatomic, copy) NSString *thumbPath;
@property(nonatomic, copy) MACameraViewPhotoResultBlock photoResultBlock;
@property(nonatomic, copy) MACameraViewVideoResultBlock videoResultBlock;
@property (nonatomic, copy) MACameraViewVideoResultBlock videoTimeoutBlock;
@property(nonatomic, copy) MACameraViewScanCodeResultBlock scanCodeBlock;
@property (nonatomic, copy) MACameraViewVideoFrameBlock videoFrameBlock;

- (instancetype)initCameraWithFrame:(CGRect)frame
                         resolution:(NSString *)resolution
                             result:(MACameraViewInitResultBlock)initResultBlock;

- (void)startRunning;

- (void)stopRunning;

- (void)clean;

- (void)takePhotoWithQuality:(NSString *)quality;

- (void)startRecord;

- (void)stopRecord:(id)userInfo;

- (void)switchCamera:(NSString *)devicePosition;

- (void)setupFlash:(NSString *)flash;

- (void)setZoom:(CGFloat)zoom withCompletion:(void(^)(BOOL success, NSError *error))completionHandler;

@end
