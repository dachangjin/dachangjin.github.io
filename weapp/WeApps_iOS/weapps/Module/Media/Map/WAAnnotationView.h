//
//  WAAnnotationView.h
//  weapps
//
//  Created by tommywwang on 2020/10/12.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <QMapKit/QMapKit.h>
#import "QMUILabel.h"
#import "WAMarker.h"
#import "WAMapViewContainer.h"

NS_ASSUME_NONNULL_BEGIN


@interface WAAnnotationView : QAnnotationView

@property (nonatomic, copy) WAMapViewContainerCalloutTapBlock calloutTapBlock;
@property (nonatomic, copy) WAMapViewContainerLabelTapBlock labelTapBlock;
@property (nonatomic, assign) BOOL alwaysShowCallout;

- (void)setIconWidth:(CGFloat)width;
- (void)setIconHeight:(CGFloat)height;

- (void)configWithMarker:(WAMarker *)marker;
@end


@interface WACalloutView : QMUILabel

@property (nonatomic, strong) WAMarkerCallout *callout;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, copy) WAMapViewContainerCalloutTapBlock tapBlock;

@end

@interface WAMarkerLabelView : QMUILabel

@property (nonatomic, strong) WAMarkerLabel *label;
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, copy) WAMapViewContainerLabelTapBlock tapBlock;

@end

@interface WAControlView : UIImageView

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, copy) WAMapViewContainerControlTapBlock tapBlock;

@end


NS_ASSUME_NONNULL_END
