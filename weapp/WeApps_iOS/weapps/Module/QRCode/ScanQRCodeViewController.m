//
//  ScanQRCodeViewController.m
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "ScanQRCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ScanQRCodeMaskView.h"

#define kFrame (CGRectMake((self.view.bounds.size.width - 280) / 2, 186, 280, 280))

@interface ScanQRCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    
}
@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong, nonatomic)AVCaptureStillImageOutput *outputPicture;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * preview;
@property (nonatomic ,strong)ScanQRCodeMaskView *scanQRMaskView;
@property (nonatomic ,strong)UIColor *barTintColor;
@property (nonatomic ,strong)UIColor *titleColor;
@property (nonatomic ,strong)NSMutableDictionary *titleDic;


@end


@implementation ScanQRCodeViewController



- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - QMUINavigationControllerDelegate

- (UIImage *)navigationBarBackgroundImage {
    return [UIImage new];
}

- (UIImage *)navigationBarShadowImage {
    return [UIImage new];
}

- (UIColor *)navigationBarTintColor {
    return [UIColor whiteColor];
}

- (UIColor *)titleViewTintColor {
    return [UIColor whiteColor];

}

- (BOOL)preferredNavigationBarHidden {
    return YES;
}

- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.title = @"扫一扫";
    if (![self isCameraAvilable]) {
        return;
    }
    self.scanQRMaskView = [[ScanQRCodeMaskView alloc] initWithFrame:self.view.bounds andMaskFrame:kFrame];
    self.scanQRMaskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [self.view addSubview:self.scanQRMaskView];
    [self setupCamera];
    

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_session startRunning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    UINavigationBar *bar = self.navigationController.navigationBar;
//    _barTintColor = bar.tintColor;
//    bar.tintColor = [UIColor whiteColor];
//
//    _titleDic = [NSMutableDictionary dictionaryWithDictionary:bar.titleTextAttributes];
//    _titleColor = _titleDic[@"NSColor"];
//    [_titleDic setObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
//    bar.titleTextAttributes = _titleDic;
//    [bar setTranslucent:YES];
//    [bar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
//    [bar setShadowImage:[UIImage new]];
//
    [_scanQRMaskView startAnimation];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    UINavigationBar *bar = self.navigationController.navigationBar;
//    bar.tintColor = _barTintColor;
//    if (_titleColor) {
//        [_titleDic setObject:_titleColor forKey:NSForegroundColorAttributeName];
//    }else{
//        [_titleDic removeObjectForKey:NSForegroundColorAttributeName];
//    }
//    bar.titleTextAttributes = _titleDic;
//    [bar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
//    [bar setShadowImage:nil];
//
    [_scanQRMaskView stopAnimation];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_session stopRunning];
   
}


- (void) scanPicture
{
    self.outputPicture = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey, nil];
    [self.outputPicture setOutputSettings:outputSettings];
    if ([self.session canAddOutput:self.outputPicture]) {
        [self.session addOutput:self.outputPicture];
    }
}


- (BOOL)isCameraAvilable
{
    Boolean haveCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    if (!haveCamera) {
            //提示没有摄像头
        [self showAlertViewWithTitle:@"警告" message:[NSString stringWithFormat:@"此设备没有摄像头"]];
        return NO;
    }
    //判断相机是否能够使用
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusAuthorized) {
        // authorized
        return YES;
    } else if(status == AVAuthorizationStatusDenied){
        // denied
        [self showAlertViewWithTitle:@"警告" message:[NSString stringWithFormat:@"%@无权访问相机,请在“设置”->“隐私”->“相机”中设置权限",@"app"]];
        return NO;
    } else if(status == AVAuthorizationStatusRestricted){
        [self showAlertViewWithTitle:@"警告" message:[NSString stringWithFormat:@"%@无权访问相机,请在“设置”->“隐私”->“相机”中设置权限",@"app"]];
        return NO;
    } else if(status == AVAuthorizationStatusNotDetermined){
        // not determined
        __block BOOL access = NO;
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            access = granted;
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        return access;
    }
    return NO;
}

- (void)setupCamera
{
    // Device
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Input
    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    
    // Output
    _output = [[AVCaptureMetadataOutput alloc]init];
    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    CGSize size = self.view.bounds.size;
    CGRect cropRect = kFrame;
    CGFloat p1 = size.height/size.width;
    CGFloat p2 = 1920./1080.;  //使用了1080p的图像输出
    if (p1 < p2) {
        CGFloat fixHeight = self.view.bounds.size.width * 1920. / 1080.;
        CGFloat fixPadding = (fixHeight - size.height)/2;
        _output.rectOfInterest = CGRectMake((cropRect.origin.y + fixPadding)/fixHeight,
                                                  cropRect.origin.x/size.width,
                                                  cropRect.size.height/fixHeight,
                                                  cropRect.size.width/size.width);
    } else {
        CGFloat fixWidth = self.view.bounds.size.height * 1080. / 1920.;
        CGFloat fixPadding = (fixWidth - size.width)/2;
        _output.rectOfInterest = CGRectMake(cropRect.origin.y/size.height,
                                                  (cropRect.origin.x + fixPadding)/fixWidth,
                                                  cropRect.size.height/size.height,
                                                  cropRect.size.width/fixWidth);
    }
    // Session
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:self.input])
    {
        [_session addInput:self.input];
    }
    
    if ([_session canAddOutput:self.output])
    {
        [_session addOutput:self.output];
    }
    
    // 条码类型 AVMetadataObjectTypeQRCode
    _output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,
                                    AVMetadataObjectTypeCode128Code,
                                    AVMetadataObjectTypeEAN8Code,
                                    AVMetadataObjectTypeUPCECode,
                                    AVMetadataObjectTypeCode39Code,
                                    AVMetadataObjectTypePDF417Code,
                                    AVMetadataObjectTypeAztecCode,
                                    AVMetadataObjectTypeCode93Code,
                                    AVMetadataObjectTypeEAN13Code,
                                    AVMetadataObjectTypeCode39Mod43Code];
    
;
    
    // Preview
    _preview =[AVCaptureVideoPreviewLayer layerWithSession:self.session];
    _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _preview.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.preview atIndex:0];
    
    // Start
    [_session startRunning];
}



#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    NSString *stringValue;
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    [self otherWithCode:stringValue];
}

- (void)otherWithCode:(NSString *)code
{
    if (code) {
        [_session stopRunning];
        [_scanQRMaskView stopAnimation];
        if (self.handler) {
            self.handler(code);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:alert animated:YES completion:nil];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
}

@end
