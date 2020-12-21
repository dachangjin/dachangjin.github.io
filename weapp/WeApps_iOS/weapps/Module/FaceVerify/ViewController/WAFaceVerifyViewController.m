//
//  WAFaceVerifyViewController.m
//  weapps
//
//  Created by tommywwang on 2020/6/23.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAFaceVerifyViewController.h"
#import "IHKeyboardAvoiding.h"
#import "Masonry.h"
#import "FVNetworkManager.h"
#import "AppConfig.h"
#import "NSMutableDictionary+NilCheck.h"
#import <WBCloudReflectionFaceVerify/WBFaceVerifyCustomerService.h>
#import "QMUITips.h"

#define BGColor [UIColor colorWithRed:64/255.0 green:158/255.0 blue:255/255.0 alpha:1.0]
#define MAS_SHORTHAND
#define MAS_SHORTHAND_GLOBALS

#define K_HEIGHT MAX([[UIScreen mainScreen] bounds].size.height,[[UIScreen mainScreen] bounds].size.width)//获取屏幕高度，兼容性测试
#define K_WIDTH  MIN([[UIScreen mainScreen] bounds].size.height,[[UIScreen mainScreen] bounds].size.width)//获取屏幕宽度，兼容性测试


@interface WAFaceVerifyViewController ()<WBFaceVerifyCustomerServiceDelegate>{
}


@property (nonatomic, strong) UIButton *logo;
@property (nonatomic, strong) UILabel *versionLabel;
@property (strong, nonatomic) UITextField *nameTextField;
@property (strong, nonatomic) UITextField *idTextField;

@property (strong, nonatomic) UIView *line1;
@property (strong, nonatomic) UIView *line2;
@property (nonatomic, strong) UIButton* activeButton;
@property (nonatomic, strong) UIButton* numberButton;
@property (nonatomic, strong) UIButton* lightButton;


@property (nonatomic ,strong)UIColor *barTintColor;
@property (nonatomic ,strong)UIColor *titleColor;
@property (nonatomic ,strong)NSMutableDictionary *titleDic;
@end

@implementation WAFaceVerifyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor =[UIColor colorWithRed:24/255.0 green:26/255.0 blue:28/255.0 alpha:1.0];

    [self setupUI];
}

- (BOOL)preferredNavigationBarHidden {
    return YES;
}

- (BOOL)forceEnableInteractivePopGestureRecognizer {
    return YES;
}

- (BOOL)shouldCustomizeNavigationBarTransitionIfHideable
{
    return YES;
}


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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.activeButton.hidden = NO;
    self.numberButton.hidden = NO;
    self.lightButton.hidden = NO;

}




-(void)setupUI{
    float actorX = 1.0;
    float actorY = 1.0;
    if(K_WIDTH <= 375){
        actorX = K_WIDTH/375;
        actorY = K_HEIGHT/667;
    }else if (K_WIDTH > 375) {
        actorX = K_WIDTH/375;
        actorY = K_HEIGHT/667;
    }

    UIImage *logoImage = [UIImage imageNamed:@"logo"];
    UIButton *logo = [[UIButton alloc] init];
    [logo setImage:logoImage forState:UIControlStateNormal];//有图片表示显示结果页
    [self.view addSubview:logo];
    self.logo = logo;
    [self.logo addTarget:self action:@selector(dissmissToHome) forControlEvents:UIControlEventTouchUpInside];

    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"人脸核身"];
    versionLabel.textColor = [UIColor colorWithRed:92/255.0 green:91/255.0 blue:91/255.0 alpha:1.0];
    versionLabel.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:versionLabel];
    self.versionLabel = versionLabel;

    UIButton *activeButton = [[UIButton alloc] init];
    activeButton.clipsToBounds = YES;
    activeButton.layer.cornerRadius = 6;
    [activeButton setBackgroundImage:[UIImage imageNamed:@"active"] forState:UIControlStateNormal];
    [activeButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:activeButton];

    UIButton *numberButton = [[UIButton alloc] init];
    numberButton.clipsToBounds = YES;
    numberButton.layer.cornerRadius = 6;
    [numberButton setBackgroundImage:[UIImage imageNamed:@"number"] forState:UIControlStateNormal];

    [numberButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:numberButton];

    UIButton *lightButton = [[UIButton alloc] init];
    lightButton.clipsToBounds = YES;
    lightButton.layer.cornerRadius = 6;
    [lightButton setBackgroundImage:[UIImage imageNamed:@"light"] forState:UIControlStateNormal];

    [lightButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:lightButton];

    self.activeButton = activeButton;
    self.numberButton = numberButton;
    self.lightButton = lightButton;

    [self.logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_top).offset(actorY * 58);
        make.width.equalTo(@(80));
        make.height.equalTo(@(100));
        make.centerX.equalTo(self.view);
    }];

    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.logo.mas_bottom).offset(12 * actorY);
    }];

    self.nameTextField = [[UITextField alloc] init];
    self.nameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入姓名"
                                                                               attributes:@{
        NSForegroundColorAttributeName: [UIColor lightTextColor]
    }];
    self.nameTextField.tintColor = [UIColor whiteColor];

    [self.view addSubview:self.nameTextField];
    [self.nameTextField setTextColor:[UIColor whiteColor]];
    self.nameTextField.font = [UIFont systemFontOfSize:16 * actorY];
    self.nameTextField.borderStyle = UITextBorderStyleNone;
    [self.nameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.versionLabel.mas_bottom).offset(actorY * 29);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.equalTo(@(34));
    }];


    UIView *line1 = [[UIView alloc] init];
    [self.view addSubview:line1];
    line1.backgroundColor = [UIColor colorWithRed:70/255.0 green:78/255.0 blue:87/255.0 alpha:1.0];
    self.line1 = line1;
    [line1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameTextField.mas_bottom);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.equalTo(@(1));
    }];

    self.idTextField = [[UITextField alloc] init];
    self.idTextField.tintColor = [UIColor whiteColor];
    self.idTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"请输入身份证号"
                                                                             attributes:@{
                                                                                 NSForegroundColorAttributeName: [UIColor lightTextColor]
                                                                             }];
    [self.view addSubview:self.idTextField];
    self.idTextField.font = [UIFont systemFontOfSize:16 * actorY];
    [self.idTextField setTextColor:[UIColor whiteColor]];
    self.idTextField.borderStyle = UITextBorderStyleNone;
    [self.idTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line1.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.equalTo(@(34));
    }];

    UIView *line2 = [[UIView alloc] init];
    line2.backgroundColor = [UIColor colorWithRed:70/255.0 green:78/255.0 blue:87/255.0 alpha:1.0];
    [self.view addSubview:line2];
    self.line2 = line2;
    [line2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.idTextField.mas_bottom);
        make.left.equalTo(self.view).offset(12);
        make.right.equalTo(self.view).offset(-12);
        make.height.equalTo(@(1));
    }];

    [activeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.line2.mas_bottom).offset(24 * actorY);
        make.width.height.equalTo(numberButton);
        make.left.equalTo(self.view).offset(12);
    }];


    [numberButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(activeButton.mas_top);
        make.width.height.equalTo(lightButton);
        make.height.equalTo(numberButton.mas_width).offset(5);
        make.left.equalTo(activeButton.mas_right).offset(4);
        make.centerX.equalTo(self.view);
    }];
    [lightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(activeButton.mas_top);
        make.left.equalTo(numberButton.mas_right).offset(4);
        make.right.equalTo(self.view).offset(-12);
    }];


    [activeButton addTarget:self action:@selector(middleServiceClicked:) forControlEvents:UIControlEventTouchUpInside];
    [numberButton addTarget:self action:@selector(hightButtonServiceClicked:) forControlEvents:UIControlEventTouchUpInside];
    [lightButton addTarget:self action:@selector(thirdButtonServiceClicked:) forControlEvents:UIControlEventTouchUpInside];

    [IHKeyboardAvoiding setAvoidingView:self.view withTriggerView:self.idTextField];
}


-(void)dissmissToHome{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

-(WBFaceVerifySDKConfig *)getSDKSettings{
    WBFaceVerifySDKConfig *config = [WBFaceVerifySDKConfig sdkConfig];
    config.recordVideo = YES;
    config.theme = WBFaceVerifyThemeDarkness;
    return  config;
}

-(void)startServiceWithType:(WBFaceVerifyLivingType)type{
    [self.view endEditing:YES];
    if (self.idTextField.text.length <= 0 || self.nameTextField.text.length <= 0) {
        [QMUITips showError:@"获取faceID时, 参数出错" detailText:@"姓名或者身份证为空" inView:self.view];
            return;
    }
    [QMUITips showLoading:@"加载中..." inView:self.view];
    [[FVNetworkManager sharedManager] faceVerifyParamsWithName:self.nameTextField.text
                                                          idNO:self.idTextField.text
                                                sourcePhotoStr:nil
                                               sourcePhotoType:@"1"
                                                    completion:^(FaceIdRequestParams * _Nullable result,
                                                                 NSError * _Nullable error) {
        [QMUITips hideAllTips];
        if (error) {
            WALOG(@"%@",error.description);
            [QMUITips showError:error.description inView:self.view];
            if (self.completion) {
                self.completion(nil, error);
            }
        } else {
            [self faceVerifyEntranceUsingFaceId:type withParams:result];
        }
    }];
}

- (void)middleServiceClicked:(id)sender {
    [self startServiceWithType:WBFaceVerifyLivingType_Action];
}

-(void)hightButtonServiceClicked:(id)sender{
    [self startServiceWithType:WBFaceVerifyLivingType_Number];
}

-(void)thirdButtonServiceClicked:(id)sender{
    [self startServiceWithType:WBFaceVerifyLivingType_Light];
}

// faceID版本接口. 动作活体和光线活体可以使用新接口
-(void)faceVerifyEntranceUsingFaceId:(WBFaceVerifyLivingType)type
                          withParams:(FaceIdRequestParams *)params
{

    [WBFaceVerifyCustomerService sharedInstance].delegate = self;
    WBFaceVerifySDKConfig *config = [self getSDKSettings];
//    config.showFailurePage = YES;
//    config.showSuccessPage = YES;
    // 身份证+姓名接口
    WBFaceUserInfo *userInfo = [[WBFaceUserInfo alloc] init];
    userInfo.idType = @"01";
    userInfo.name = _nameTextField.text;
    userInfo.idNo = _idTextField.text;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WBFaceVerifyCustomerService sharedInstance] startLoginLiveCheckAndCompareServiceWithUserid:params.userId
                                                                                               nonce:params.nonce
                                                                                                sign:params.sign
                                                                                               appid:kCloudFaceId
                                                                                             orderNo:params.orderNO
                                                                                          apiVersion:params.version
                                                                                             licence:kCloudLicense
                                                                                      faceverifyType:type
                                                                                            userInfo:userInfo
                                                                                           configure:config success:^{
            [QMUITips hideAllTips];
        } failure:^(WBFaceError *error) {
            WALOG(@"error: %@", error);
            NSString *info = error.reason ? error.reason : @"识别出错";
            [QMUITips showError:info inView:self.view];
            if (self.completion) {
                self.completion(nil, [NSError errorWithDomain:error.domain code:error.code
                                                     userInfo:@{NSLocalizedDescriptionKey: info}]);
            }
        }];
    });
}


#pragma mark - WBFaceVerifyCustomerServiceDelegate

-(void)wbfaceVerifyCustomerServiceDidFinishedWithFaceVerifyResult:(WBFaceVerifyResult *)faceVerifyResult{
    NSLog(@"result 结果: %@", faceVerifyResult);
    if (faceVerifyResult.isSuccess) {
        if (self.completion) {
            NSMutableDictionary *result = [NSMutableDictionary dictionary];
            kWA_DictSetObjcForKey(result, @"success", [NSNumber numberWithBool:YES]);
            kWA_DictSetObjcForKey(result, @"name", _nameTextField.text);
            kWA_DictSetObjcForKey(result, @"idNo", _idTextField.text);
            kWA_DictSetObjcForKey(result, @"liveRate", faceVerifyResult.liveRate);
            kWA_DictSetObjcForKey(result, @"similarityRate", faceVerifyResult.similarity);
            self.completion(result, nil);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }else {
        NSString *info = faceVerifyResult.error.reason ? faceVerifyResult.error.reason : @"识别出错";
        if (self.completion) {
            
            self.completion(nil, [NSError errorWithDomain:faceVerifyResult.error.domain
                                                     code:faceVerifyResult.error.code
                                                 userInfo:@{NSLocalizedDescriptionKey: info}]);
        }
        [QMUITips showError:@"失败" detailText:info.description inView:self.view];
    }
}

#pragma mark - Private Methods

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}

#pragma mark - viewController orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations//支持哪些方向
{
    return UIInterfaceOrientationMaskPortrait;
}

/**
 初始化自己的方向, 这个在旋转屏幕时候非常重要
 If you do not implement this method, the system presents the view controller using the current orientation of the status bar.

 说明如果我们没有override这个方法,系统会根据当前statusbar来决定当前使用的orientation
 */
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation//默认显示的方向
{
    return UIInterfaceOrientationPortrait;
}

/**
 如果返回NO，则无论你的项目如何设置，你的ViewController都只会使用preferredInterfaceOrientationForPresentation的返回值来初始化自己的方向，如果你没有重新定义这个函数，那么它就返回父视图控制器的preferredInterfaceOrientationForPresentation的值。
 */
- (BOOL)shouldAutorotate//是否支持旋转屏幕
{
    return NO;
}

@end

