//
//  WAShowLocationViewController.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAShowLocationViewController.h"
#import <MapKit/MapKit.h>
#import "WAAnnotation.h"
#import "Masonry.h"
#import "LCActionSheet.h"
#import "NSString+QMUI.h"
#import "Device.h"

#define kBottonViewHeight 90

@interface WALocationBottomView : UIView


@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *addressLabel;
@property (nonatomic, strong) UIButton *directButton;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, copy) void(^directButtonTapBloack)(__kindof UIControl *sender);

@end

@implementation WALocationBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.titleLabel];
        [self addSubview:self.addressLabel];
        [self addSubview:self.infoLabel];
        [self addSubview:self.directButton];
        self.infoLabel.hidden = YES;
        [self addConstraints];
    }
    return self;
}

- (void)setDirectButtonTapBloack:(void (^)(__kindof UIControl *))directButtonTapBloack
{
    [self.directButton setQmui_tapBlock:directButtonTapBloack];
}


- (void)addConstraints
{
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).inset(15);
        make.top.equalTo(self).with.inset(20);
        make.right.equalTo(self).with.inset(100);
        make.size.height.mas_equalTo(30);
    }];
    [self.addressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.inset(15);
        make.top.equalTo(self.titleLabel.mas_bottom);
        make.right.equalTo(self).with.inset(100);
        make.size.height.mas_equalTo(20);
    }];
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.inset(15);
        make.right.equalTo(self).with.inset(100);
        make.height.mas_equalTo(30);
        make.centerY.equalTo(self);
    }];
    [self.directButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).with.inset(15);
        make.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
}



- (void)setTitle:(NSString *)title andAddress:(NSString *)address
{
    if (!title && !address) {
        _infoLabel.hidden = YES;
        _addressLabel.hidden = YES;
        _infoLabel.hidden = NO;
    } else {
        _infoLabel.hidden = NO;
        _addressLabel.hidden = NO;
        _infoLabel.hidden = YES;
    }
    _titleLabel.text = title;
    _addressLabel.text = address;
}


- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:20.0];
    }
    return _titleLabel;
}

- (UILabel *)infoLabel
{
    if (!_infoLabel) {
        _infoLabel = [[UILabel alloc] init];
        _infoLabel.font = [UIFont systemFontOfSize:20.0];
        _infoLabel.text = @"[位置]";
    }
    return _infoLabel;
}

- (UILabel *)addressLabel
{
    if (!_addressLabel) {
        _addressLabel = [[UILabel alloc] init];
        _addressLabel.font = [UIFont systemFontOfSize:13.0];
        _addressLabel.textColor = [UIColor grayColor];
    }
    return _addressLabel;
}


- (UIButton *)directButton
{
    if (!_directButton) {
        _directButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_directButton setBackgroundImage:[UIImage imageNamed:@"locationSharing_navigate_icon_new"] forState:UIControlStateNormal];
        [_directButton setBackgroundImage:[UIImage imageNamed:@"locationSharing_navigate_icon_HL_new"] forState:UIControlStateHighlighted];
    }
    return _directButton;
}

@end

@interface WAShowLocationViewController ()<MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UIButton *locationButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, assign) MKCoordinateRegion region;
@property (nonatomic, strong) WALocationBottomView *bottomView;

@end

@implementation WAShowLocationViewController



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


- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.locationButton];
    [self.view addSubview:self.backButton];
    [self.view addSubview:self.bottomView];
    [self.bottomView setTitle:self.params[@"name"] andAddress:self.params[@"address"]];
//#ifdef DEBUG
//    [self.bottomView setTitle:@"腾讯西南总部大厦" andAddress:@"重庆市渝北区涉外商务区"];
//#endif
    
    @weakify(self)
    self.bottomView.directButtonTapBloack = ^(__kindof UIControl *sender) {
        @strongify(self)
        [self gotoMap];
    };
    
    [self setConstrains];
}


//约束
- (void)setConstrains
{
    [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view).insets(UIEdgeInsetsMake(0, 0, kBottonViewHeight, 0));
    }];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.left.equalTo(self.view).insets(UIEdgeInsetsMake(0, 0, 0, 0));
        make.top.equalTo(self.mapView.mas_bottom);
    }];
    [self.locationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.view).inset(10);
        make.bottom.equalTo(self.bottomView.mas_top).inset(20);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    }];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).inset(14);
        make.top.equalTo(self.view).inset([Device statusBarHeight] + 5);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
}

- (MKMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MKMapView alloc] init];
        WAAnnotation *annotation = [[WAAnnotation alloc] init];
        annotation.title = self.params[@"name"];
        annotation.subtitle = self.params[@"address"];
        annotation.coordinate = CLLocationCoordinate2DMake([self.params[@"latitude"] doubleValue], [self.params[@"longitude"] doubleValue]);
        [_mapView addAnnotation:annotation];
        CLLocationDistance distance = 900;
        NSNumber *scaleNumber = self.params[@"scale"];
        
        if ([scaleNumber isKindOfClass:[NSNumber class]]) {
            if ([scaleNumber floatValue] >= 5 && [scaleNumber floatValue] < 18) {
                distance = distance * 18 / [scaleNumber floatValue] ;
            }
        }
        _region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, distance, distance);
        _mapView.delegate = self;
        [_mapView setRegion:_region];
    }
    return _mapView;
}


- (UIButton *)locationButton
{
    if (!_locationButton) {
        _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_locationButton setBackgroundImage:[UIImage imageNamed:@"location_my"] forState:UIControlStateSelected];
        [_locationButton setBackgroundImage:[UIImage imageNamed:@"location_my_HL"] forState:UIControlStateHighlighted];
        [_locationButton setBackgroundImage:[UIImage imageNamed:@"location_my_current"] forState:UIControlStateNormal];

        @weakify(self)
        [_locationButton setQmui_tapBlock:^(__kindof UIControl *sender) {
            @strongify(self)
            [self.mapView setRegion:self.region animated:YES];
        }];
    }
    return _locationButton;
}


- (WALocationBottomView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[WALocationBottomView alloc] init];
        _bottomView.backgroundColor = [UIColor whiteColor];
        [_bottomView setQmui_borderPosition:QMUIViewBorderPositionTop];
        [_bottomView setQmui_borderColor:[UIColor colorWithWhite:0.5 alpha:0.2]];
        [_bottomView setQmui_borderWidth:0.5];
    }
    return _bottomView;
}

- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setBackgroundImage:[UIImage imageNamed:@"barbuttonicon_back_cube"] forState:UIControlStateNormal];
        @weakify(self)
        [_backButton setQmui_tapBlock:^(__kindof UIControl *sender) {
            @strongify(self)
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }
    return _backButton;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *ID = @"anno";
    MKPinAnnotationView *annoView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:ID];
    if (annoView == nil) {
        annoView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
        // 设置绿色
    }
    annoView.pinTintColor = [UIColor redColor];
    annoView.animatesDrop = YES;
    return annoView;
}

#pragma mark 业务
/// 地图展示路线
- (void)gotoMap{
    
    LCActionSheet *actionSheet = [[LCActionSheet alloc] initWithTitle:nil
                                                    cancelButtonTitle:@"取消" didDismiss:^(LCActionSheet * _Nonnull actionSheet, NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self gotoQQmap];
        } else if (buttonIndex == 2) {
            [self gotIosamap];
        } else if (buttonIndex == 3) {
            [self gotoAppleMap];
        }
    } otherButtonTitleArray:@[@"腾讯地图", @"高德地图", @"Apple地图"]];
    [actionSheet show];
}


- (void)gotoQQmap
{
    //腾讯地图
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"qqmap://"]]) {
        
        NSString *urlString = [[NSString stringWithFormat:@"qqmap://map/routeplan?from=我的位置&type=drive&tocoord=%f,%f&to=%@&policy=0",
                                _region.center.latitude,_region.center.longitude,
                                self.params[@"title"] ? : @"目的地"]
                               qmui_stringByEncodingUserInputQuery];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    } else {
        //转跳到下载页面
    }
}


/// 高德地图
- (void)gotIosamap
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"iosamap://"]]) {
        NSString *urlString = [[NSString stringWithFormat:@"iosamap://path?dlat=%f&dlon=%f&dname=%@",
                                self.region.center.latitude,
                                self.region.center.longitude,
                                self.params[@"title"] ? : @"目的地"]
                               stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        

    }
}

//apple map
- (void)gotoAppleMap
{
    
    MKMapItem *currentLoc = [MKMapItem mapItemForCurrentLocation];
    MKMapItem *toLocation = [[MKMapItem alloc] initWithPlacemark:[[MKPlacemark alloc] initWithCoordinate:self.region.center addressDictionary:nil]];
    toLocation.name = self.params[@"title"];
    NSArray *items = @[currentLoc,toLocation];
    NSDictionary *dic = @{
                          MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving,
                          MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard),
                          MKLaunchOptionsShowsTrafficKey : @(YES)
                          };
    
    [MKMapItem openMapsWithItems:items launchOptions:dic];
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    self.locationButton.selected = !isCLLocationCoordinate2DEqualToOther(mapView.region.center,_region.center);
}


BOOL isCLLocationCoordinate2DEqualToOther(CLLocationCoordinate2D coor1, CLLocationCoordinate2D coor2)
{
    if (fabs(coor1.latitude - coor2.latitude) < 0.0000001 && fabs(coor1.longitude - coor2.longitude) < 0.0000001) {
        return YES;
    }
    return NO;
}


@end
