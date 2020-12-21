//
//  WBQRCodeVC.m
//  SGQRCodeExample
//
//  Created by kingsic on 2018/2/8.
//  Copyright © 2018年 kingsic. All rights reserved.
//
#import "WBQRCodeVC.h"
#import "SGQRCode.h"
#import "SGQRCodeScanView.h"
#import "QMUITips+Mask.h"
#import "Device.h"
#import "UINavigationBar+Custom.h"

@interface WBQRCodeVC () {
    SGQRCodeObtain *obtain;
}


@property (nonatomic, strong) SGQRCodeScanView *scanView;
@property (nonatomic, strong) UILabel *promptLabel;
@property (nonatomic, assign) BOOL stop;
@end

@implementation WBQRCodeVC

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


- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_stop) {
        [obtain startRunningWithBefore:nil completion:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.scanView addTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.scanView removeTimer];
}

- (void)dealloc {
    [self removeScanningView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor blackColor];
    obtain = [SGQRCodeObtain QRCodeObtain];
    
    [self setupQRCodeScan];
    [self setupNavigationBar];
    [self.view addSubview:self.scanView];
    [self.view addSubview:self.promptLabel];
    [self.navigationController.navigationBar setBackgroundColor:[UIColor clearColor] withAnimationInfo:nil];
}

- (void)setupQRCodeScan {
    __weak typeof(self) weakSelf = self;
    SGQRCodeObtainConfigure *configure = [SGQRCodeObtainConfigure QRCodeObtainConfigure];
    configure.openLog = YES;
    configure.rectOfInterest = CGRectMake(0.05, 0.2, 0.7, 0.6);
    // 这里只是提供了几种作为参考（共：13）；需什么类型添加什么类型即可
    NSArray *arr = @[AVMetadataObjectTypeAztecCode,
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
    
    configure.metadataObjectTypes = arr;
    
    [obtain establishQRCodeObtainScanWithController:self configure:configure];
    [obtain startRunningWithBefore:^{
        [QMUITips showLoading:@"正在加载" inView:weakSelf.view];
    } completion:^{
        [QMUITips hideAllTips];
    }];
    [obtain setBlockWithQRCodeObtainScanResult:^(SGQRCodeObtain *obtain, NSString *type, NSString *result) {
        if (result) {
            [obtain stopRunning];
            weakSelf.stop = YES;
            [obtain playSoundName:@"SGQRCode.bundle/sound.caf"];
            
            NSString *scanType= [Device scanTypeFromType:type];
            NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSString *resultBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            
            //这里还需要返回类型等
            NSMutableDictionary *resDic = [NSMutableDictionary new];
            [resDic setObject:result forKey:@"result"];
            [resDic setObject:scanType forKey:@"type"];
            [resDic setObject:@"UTF-8" forKey:@"charSet"];
            [resDic setObject:resultBase64?:@"" forKey:@"rawData"];
//            [weakSelf.navigationController popViewControllerAnimated:YES];
            weakSelf.scanCodeCallBack(resDic);
            
        }
    }];
}

- (void)setupNavigationBar {
    [self.navigationController.navigationBar setHidden:NO];
    self.navigationItem.title = @"扫一扫";
    if (![self.scanPrams[@"onlyFromCamera"] boolValue]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"相册"
                                                                                  style:(UIBarButtonItemStyleDone)
                                                                                 target:self
                                                                                 action:@selector(rightBarButtonItenAction)];
    }
}

- (void)rightBarButtonItenAction {
    __weak typeof(self) weakSelf = self;
    [obtain establishAuthorizationQRCodeObtainAlbumWithController:nil];
    if (obtain.isPHAuthorization == YES) {
        [self.scanView removeTimer];
    }
    [obtain setBlockWithQRCodeObtainAlbumDidCancelImagePickerController:^(SGQRCodeObtain *obtain) {
        [weakSelf.view addSubview:weakSelf.scanView];
    }];
    [obtain setBlockWithQRCodeObtainAlbumResult:^(SGQRCodeObtain *obtain, NSString *result) {
        if (result == nil) {
//            NSLog(@"暂未识别出二维码");
            [QMUITips showInfo:@"暂未识别出二维码" inView:weakSelf.view hideAfterDelay:1.5];
            [weakSelf.scanView addTimer];
        } else {
            [obtain playSoundName:@"SGQRCode.bundle/sound.caf"];
            NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
            NSString *resultBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            
            //这里还需要返回类型等
            NSMutableDictionary *resDic = [NSMutableDictionary new];
            [resDic setObject:result forKey:@"result"];
//            [resDic setObject:scanType forKey:@"type"];
            [resDic setObject:@"UTF-8" forKey:@"charSet"];
            [resDic setObject:resultBase64?:@"" forKey:@"rawData"];
//            [weakSelf.navigationController popViewControllerAnimated:YES];

            weakSelf.scanCodeCallBack(resDic);

        }
    }];
}

- (SGQRCodeScanView *)scanView {
    if (!_scanView) {
        _scanView = [[SGQRCodeScanView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        // 静态库加载 bundle 里面的资源使用 SGQRCode.bundle/QRCodeScanLineGrid
        // 动态库加载直接使用 QRCodeScanLineGrid
        _scanView.scanImageName = @"SGQRCode.bundle/QRCodeScanLineGrid";
        _scanView.scanAnimationStyle = ScanAnimationStyleGrid;
        _scanView.cornerLocation = CornerLoactionOutside;
        _scanView.cornerColor = [UIColor orangeColor];
    }
    return _scanView;
}

- (void)removeScanningView {
    [self.scanView removeTimer];
    [self.scanView removeFromSuperview];
    self.scanView = nil;
}

- (UILabel *)promptLabel {
    if (!_promptLabel) {
        _promptLabel = [[UILabel alloc] init];
        _promptLabel.backgroundColor = [UIColor clearColor];
        CGFloat promptLabelX = 0;
        CGFloat promptLabelY = 0.73 * self.view.frame.size.height;
        CGFloat promptLabelW = self.view.frame.size.width;
        CGFloat promptLabelH = 25;
        _promptLabel.frame = CGRectMake(promptLabelX, promptLabelY, promptLabelW, promptLabelH);
        _promptLabel.textAlignment = NSTextAlignmentCenter;
        _promptLabel.font = [UIFont boldSystemFontOfSize:13.0];
        _promptLabel.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        _promptLabel.text = @"将二维码/条码放入框内, 即可自动扫描";
    }
    return _promptLabel;
}

@end
 
