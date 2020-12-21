//
//  WAAnnotationView.m
//  weapps
//
//  Created by tommywwang on 2020/10/12.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAAnnotationView.h"
#import "WAMarker.h"
#import "QMUIKit.h"
#import "PathUtils.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define K_ARROR_HEIGHT 10

@interface WAAnnotationView ()

@property (nonatomic, strong) WACalloutView *calloutView;
@property (nonatomic, strong) WAMarkerLabelView *label;
@property (nonatomic, strong) UIImageView *iconView;

@end

@implementation WAAnnotationView

- (id)initWithAnnotation:(id<QAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier]) {
        UIImage *image = [UIImage imageNamed:@"pin"];
        _iconView = [[UIImageView alloc] initWithImage:image];
        self.qmui_width = image.size.width;
        self.qmui_height = image.size.height;
        _iconView.frame = CGRectMake(0,
                                     0,
                                     image.size.width,
                                     image.size.height);
        [self addSubview:_iconView];
    }
    return self;
}

- (void)setIconWidth:(CGFloat)width
{
    self.iconView.qmui_width = width;
    self.qmui_width = width;
    self.iconView.center = CGPointMake(self.qmui_width / 2, self.qmui_height / 2);
}

- (void)setIconHeight:(CGFloat)height
{
    self.iconView.qmui_height = height;
    self.qmui_height = height;
    self.iconView.center = CGPointMake(self.qmui_width / 2, self.qmui_height / 2);
}

- (void)configWithMarker:(WAMarker *)marker
{
    self.zIndex = marker.zIndex;
    self.alpha = marker.alpha;
    self.transform = CGAffineTransformRotate(CGAffineTransformIdentity,
                                             marker.rotate * M_PI / 180);
    
    if (marker.iconPath) {
        if (kStringContainString(marker.iconPath, @"http")) {
            //网络路径
            [self.iconView sd_setImageWithURL:[NSURL URLWithString:marker.iconPath]
                             placeholderImage:[UIImage imageNamed:@"pin"]
                                    completed:^(UIImage * _Nullable image,
                                                NSError * _Nullable error,
                                                SDImageCacheType cacheType,
                                                NSURL * _Nullable imageURL) {
                if (image) {
                    //根据image大小自适应大小
                    [self setIconWidth:image.size.width];
                    [self setIconHeight:image.size.height];
                }
                //若设置了marker大小相关
                if (marker.width > 0) {
                    [self setIconWidth:marker.width];
                }
                if (marker.height > 0) {
                    [self setIconHeight:marker.height];
                }
            }];
        } else {
            //本地路径
            UIImage *image = [UIImage imageWithContentsOfFile:
                              [PathUtils h5BundlePathForRelativePath:[NSString stringWithFormat:@"preview/%@",marker.iconPath]]];
            self.iconView.image = image;
            [self setIconWidth:image.size.width];
            [self setIconHeight:image.size.height];
        }
    }
    if (marker.width > 0) {
        [self setIconWidth:marker.width];
    }
    if (marker.height > 0) {
        [self setIconHeight:marker.height];
    }
    //设置callout和label
    self.alwaysShowCallout = marker.callout.alwaysShow;
    [self setupCallout:marker.callout withIdentifier:marker.identifier];
    [self setupLabel:marker.label withIdentifier:marker.identifier];
    //设置offset
    CGFloat x = (0.5 - marker.anchor.x) * self.qmui_width;
    CGFloat y = (0.5 - marker.anchor.y) * self.qmui_height;
    self.centerOffset = CGPointMake(x, y);
}

- (void)setupCallout:(WAMarkerCallout *)callout withIdentifier:(NSNumber *)identifier
{
    if (!callout) {
        self.canShowCallout = YES;
        return;
    }
    self.canShowCallout = NO;
    self.calloutView.callout = callout;
    self.calloutView.identifier = identifier;
    if (callout.alwaysShow) {
        [self setSelected:YES];
    }
    CGFloat x = self.qmui_width / 2 - self.calloutView.qmui_width / 2;
    if (callout.textAlign == NSTextAlignmentLeft) {
        x = self.qmui_width / 2 - self.calloutView.qmui_width;
    } else if (callout.textAlign == NSTextAlignmentRight) {
        x = self.qmui_width / 2;
    }
    x += callout.anchorX;
    CGFloat y = - self.calloutView.qmui_height;
    y += callout.anchorY;
    CGRect calloutViewframe = CGRectMake(x,
                                         y,
                                         self.calloutView.qmui_width,
                                         self.calloutView.qmui_height);
    self.calloutView.frame = calloutViewframe;
    
}

- (void)setupLabel:(WAMarkerLabel *)label withIdentifier:(NSNumber *)identifier
{
    if (!label) {
        return;
    }
    self.label.label = label;
    self.label.identifier = identifier;
    CGFloat x = self.qmui_width / 2 - self.label.qmui_width / 2;
    if (label.textAlign == NSTextAlignmentLeft) {
        x = self.qmui_width / 2 - self.label.qmui_width;
    } else if (label.textAlign == NSTextAlignmentRight) {
        x = self.qmui_width / 2;
    }
    x += label.anchorX;
    CGFloat y = self.qmui_height;
    y += label.anchorY;
    CGRect labelframe = CGRectMake(x,
                                         y,
                                         self.label.qmui_width,
                                         self.label.qmui_height);
    self.label.frame = labelframe;
}


- (WACalloutView *)calloutView
{
    if (!_calloutView) {
        _calloutView = [[WACalloutView alloc] init];
        _calloutView.numberOfLines = 0;
        @weakify(self)
        _calloutView.tapBlock = ^(NSNumber * _Nonnull markerId) {
            @strongify(self)
            if (self.calloutTapBlock) {
                self.calloutTapBlock(markerId);
            }
        };
    }
    return _calloutView;
}

- (WAMarkerLabelView *)label
{
    if (!_label) {
        _label = [[WAMarkerLabelView alloc] init];
        _label.numberOfLines = 0;
        [self addSubview:_label];
        @weakify(self)
        _label.tapBlock = ^(NSNumber * _Nonnull markerId) {
            @strongify(self)
            if (self.labelTapBlock) {
                self.labelTapBlock(markerId);
            }
        };
    }
    return _label;
}


- (void)setSelected:(BOOL)selected
{
    if (self.alwaysShowCallout) {
        [self setSelected:YES animated:NO];
    } else {
        [self setSelected:selected animated:NO];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (self.alwaysShowCallout) {
        selected = YES;
    }
    if (self.selected == selected) {
        return;
    }
    if (selected) {
        [self addSubview:self.calloutView];
    } else {
        [self.calloutView removeFromSuperview];
    }
    
    [super setSelected:selected animated:animated];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.calloutView.frame, point) || CGRectContainsPoint(self.label.frame, point)) {
        return YES;
    }
    BOOL inside = [super pointInside:point withEvent:event];
    
    /*若不在annotationView内，检测是否在calloutView内. */
    if (!inside && self.selected) {
        inside = [self.calloutView pointInside:[self convertPoint:point toView:self.calloutView] withEvent:event];
    }
    
    return inside;
}


@end

@implementation WACalloutView

- (instancetype)init
{
    self = [super init];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self addGestureRecognizer:tap];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)tap
{
    if (self.tapBlock) {
        self.tapBlock(self.identifier);
    }
}

- (void)setCallout:(WAMarkerCallout *)callout
{
    _callout = callout;
    self.text = callout.content;
    self.textColor = callout.color ? callout.color : [UIColor blackColor];
    if (callout.fontSize > 0) {
        self.font = [UIFont systemFontOfSize:callout.fontSize];
    }
    CGRect rect = [self.text boundingRectWithSize:CGSizeMake(K_SCREEN_WIDTH, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{
                                           NSFontAttributeName : self.font
                                       }
                                          context:nil];
    self.bounds = CGRectMake(0,
                             0,
                             rect.size.width + (callout.padding + _callout.borderWidth) * 2,
                             rect.size.height + (callout.padding + _callout.borderWidth) * 2 + K_ARROR_HEIGHT);
    self.contentEdgeInsets = UIEdgeInsetsMake(callout.padding + _callout.borderWidth,
                                              callout.padding + _callout.borderWidth,
                                              callout.padding + _callout.borderWidth + K_ARROR_HEIGHT,
                                              callout.padding + _callout.borderWidth);
}

- (void)drawRect:(CGRect)rect
{
    [self drawInContext:UIGraphicsGetCurrentContext()];
    [super drawRect:rect];
}

- (void)drawInContext:(CGContextRef)context
{
    CGContextSetFillColorWithColor(context, _callout.bgColor.CGColor);
    [self getFillPath:context];
    CGContextFillPath(context);
    
    if (_callout.borderWidth && _callout.borderColor) {
        CGContextSetLineWidth(context, _callout.borderWidth);
        CGContextSetStrokeColorWithColor(context, _callout.borderColor.CGColor);
        [self getBorderPath:context];
        CGContextStrokePath(context);
    }
}


- (void)getBorderPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = _callout.borderRadius;
    CGFloat minx = CGRectGetMinX(rrect) + self.callout.borderWidth / 2,
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect) - self.callout.borderWidth / 2;
    CGFloat miny = CGRectGetMinY(rrect) + self.callout.borderWidth / 2,
    maxy = CGRectGetMaxY(rrect) - self.callout.borderWidth / 2 - K_ARROR_HEIGHT;
    
    CGContextMoveToPoint(context, midx + K_ARROR_HEIGHT, maxy);
    CGContextAddLineToPoint(context,midx, maxy + K_ARROR_HEIGHT);
    CGContextAddLineToPoint(context,midx - K_ARROR_HEIGHT, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}

- (void)getFillPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = _callout.borderRadius;
    CGFloat minx = CGRectGetMinX(rrect) + self.callout.borderWidth / 2,
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect) - self.callout.borderWidth / 2;
    CGFloat miny = CGRectGetMinY(rrect) + self.callout.borderWidth / 2,
    maxy = CGRectGetMaxY(rrect) - self.callout.borderWidth / 2 - K_ARROR_HEIGHT;
    
    CGContextMoveToPoint(context, midx + K_ARROR_HEIGHT, maxy);
    CGContextAddLineToPoint(context,midx, maxy + K_ARROR_HEIGHT);
    CGContextAddLineToPoint(context,midx - K_ARROR_HEIGHT, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}


@end


@implementation WAMarkerLabelView

- (instancetype)init
{
    self = [super init];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        [self addGestureRecognizer:tap];
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)tap
{
    if (self.tapBlock) {
        self.tapBlock(self.identifier);
    }
}

- (void)setLabel:(WAMarkerLabel *)label
{
    _label = label;
    self.text = label.content;
    self.textColor = label.color;
    if (label.fontSize) {
        self.font = [UIFont systemFontOfSize:label.fontSize];
    }
    CGRect rect = [self.text boundingRectWithSize:CGSizeMake(K_SCREEN_WIDTH, CGFLOAT_MAX)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{
                                           NSFontAttributeName : self.font
                                       }
                                          context:nil];
    self.bounds = CGRectMake(0,
                             0,
                             rect.size.width + (label.padding + label.borderWidth) * 2,
                             rect.size.height + (label.padding + label.borderWidth) * 2);
    self.contentEdgeInsets = UIEdgeInsetsMake(label.padding + label.borderWidth,
                                              label.padding + label.borderWidth,
                                              label.padding + label.borderWidth,
                                              label.padding + label.borderWidth);
}

- (void)drawRect:(CGRect)rect
{
    [self drawInContext:UIGraphicsGetCurrentContext()];
    [super drawRect:rect];
}

- (void)drawInContext:(CGContextRef)context
{
    CGContextSetFillColorWithColor(context, _label.bgColor.CGColor);
    [self getFillPath:context];
    CGContextFillPath(context);
    
    if (_label.borderWidth && _label.borderColor) {
        CGContextSetLineWidth(context, _label.borderWidth);
        CGContextSetStrokeColorWithColor(context, _label.borderColor.CGColor);
        [self getBorderPath:context];
        CGContextStrokePath(context);
    }
}


- (void)getBorderPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = _label.borderRadius;
    CGFloat minx = CGRectGetMinX(rrect) + self.label.borderWidth / 2,
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect) - self.label.borderWidth / 2;
    CGFloat miny = CGRectGetMinY(rrect) + self.label.borderWidth / 2,
    maxy = CGRectGetMaxY(rrect) - self.label.borderWidth / 2;
    
    CGContextMoveToPoint(context, midx, maxy);
    CGContextAddLineToPoint(context,midx, maxy);
    CGContextAddLineToPoint(context,midx, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}

- (void)getFillPath:(CGContextRef)context
{
    CGRect rrect = self.bounds;
    CGFloat radius = _label.borderRadius;
    CGFloat minx = CGRectGetMinX(rrect) + self.label.borderWidth / 2,
    midx = CGRectGetMidX(rrect),
    maxx = CGRectGetMaxX(rrect) - self.label.borderWidth / 2;
    CGFloat miny = CGRectGetMinY(rrect) + self.label.borderWidth / 2,
    maxy = CGRectGetMaxY(rrect) - self.label.borderWidth / 2;
    
    CGContextMoveToPoint(context, midx, maxy);
    CGContextAddLineToPoint(context,midx, maxy);
    CGContextAddLineToPoint(context,midx, maxy);
    
    CGContextAddArcToPoint(context, minx, maxy, minx, miny, radius);
    CGContextAddArcToPoint(context, minx, minx, maxx, miny, radius);
    CGContextAddArcToPoint(context, maxx, miny, maxx, maxx, radius);
    CGContextAddArcToPoint(context, maxx, maxy, midx, maxy, radius);
    CGContextClosePath(context);
}
@end

@implementation WAControlView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] init];
        [tap addTarget:self action:@selector(tap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)tap
{
    if (self.tapBlock) {
        self.tapBlock(self.identifier);
    }
}


@end


