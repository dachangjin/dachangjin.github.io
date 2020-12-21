//
//  WAMarker.h
//  weapps
//
//  Created by tommywwang on 2020/10/12.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <QMapKit/QAnnotation.h>
#import <QMapKit/QPolyline.h>
#import <QMapKit/QPolygon.h>
#import <QMapKit/QCircle.h>

NS_ASSUME_NONNULL_BEGIN

@interface WAMarkerCallout : NSObject

@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGFloat padding;
@property (nonatomic, assign) BOOL alwaysShow; //是否常显，否则点击显示
@property (nonatomic, assign) NSTextAlignment textAlign;
@property (nonatomic, assign) CGFloat anchorX;
@property (nonatomic, assign) CGFloat anchorY;

- (id)initWithDict:(NSDictionary *)dict;

@end

@interface WAMarkerCustomCallout : NSObject

@property (nonatomic, assign) BOOL alwaysShow; //是否常显，否则点击显示
@property (nonatomic, assign) CGFloat anchorX;
@property (nonatomic, assign) CGFloat anchorY;

- (id)initWithDict:(NSDictionary *)dict;

@end

@interface WAMarkerLabel : NSObject

@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat fontSize;
@property (nonatomic, assign) CGFloat anchorX;
@property (nonatomic, assign) CGFloat anchorY;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderRadius;
@property (nonatomic, strong) UIColor *bgColor;
@property (nonatomic, assign) CGFloat padding;
@property (nonatomic, assign) NSTextAlignment textAlign;

- (id)initWithDict:(NSDictionary *)dict;

@end

@interface WAMarker : NSObject <QAnnotation>

@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) int zIndex;
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, assign) CGFloat rotate;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;
@property (nonatomic, strong) WAMarkerCallout *callout;
@property (nonatomic, strong) WAMarkerCustomCallout *customCallout;
@property (nonatomic, strong) WAMarkerLabel *label;
@property (nonatomic, assign) CGPoint anchor;
@property (nonatomic, copy) NSString *ariaLabel;

- (id)initWithDict:(NSDictionary *)dict;

@end


@interface WAPolyline : QPolyline

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSArray <UIColor *> *colorList;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) BOOL dottedLine; //虚线，默认NO
@property (nonatomic, assign) BOOL arrowLine;  //带箭头的线，默认NO
@property (nonatomic, copy) NSString *arrowIconPath;
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat borderWidth;

- (id)initWithDict:(NSDictionary *)dict;

@end

@interface WAPolygon : QPolygon

@property (nonatomic, assign) CGFloat strokeWidth;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) int zIndex;

- (id)initWithDict:(NSDictionary *)dict;

@end

@interface WACircle : QCircle

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) CGFloat strokeWidth;

- (id)initWithDict:(NSDictionary *)dict;

@end



@interface WAControl : NSObject
@property (nonatomic, strong) NSNumber *identifier;
@property (nonatomic, assign) CGRect position;
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, assign) BOOL clickable;

- (id)initWithDict:(NSDictionary *)dict;

@end
NS_ASSUME_NONNULL_END
