//
//  WAMarker.m
//  weapps
//
//  Created by tommywwang on 2020/10/12.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMarker.h"
#import "UIColor+QMUI.h"
#import <QMapKit/QGeometry.h>

@implementation WAMarkerCallout

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _content = dict[@"content"];
        _color = [UIColor qmui_rgbaColorWithHexString:dict[@"color"]];
        _fontSize = [dict[@"fontSize"] floatValue];
        _borderRadius = [dict[@"borderRadius"] floatValue];
        _borderWidth = [dict[@"borderWidth"] floatValue];
        _borderColor = [UIColor qmui_rgbaColorWithHexString:dict[@"borderColor"]];
        _bgColor = [UIColor qmui_rgbaColorWithHexString:dict[@"bgColor"]];
        _padding = [dict[@"padding"] floatValue];
        _alwaysShow = kStringEqualToString(dict[@"display"], @"ALWAYS") ? YES : NO;
        NSString *textAlign = dict[@"textAlign"];
        if (kStringEqualToString(textAlign, @"left")) {
            _textAlign = NSTextAlignmentLeft;
        } else if (kStringEqualToString(textAlign, @"right")) {
            _textAlign = NSTextAlignmentRight;
        } else {
            _textAlign = NSTextAlignmentCenter;
        }
        _anchorX = [dict[@"anchorX"] floatValue];
        _anchorY = [dict[@"anchorY"] floatValue];
    }
    return self;
}

@end



@implementation WAMarkerCustomCallout

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _alwaysShow = kStringEqualToString(dict[@"display"], @"ALWAYS") ? YES : NO;
        _anchorX = [dict[@"anchorX"] floatValue];
        _anchorY = [dict[@"anchorY"] floatValue];
    }
    return self;
}

@end


@implementation WAMarkerLabel

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _content = dict[@"content"];
        _color = [UIColor qmui_rgbaColorWithHexString:dict[@"color"]];
        _fontSize = [dict[@"fontSize"] floatValue];
        _anchorX = [(dict[@"x"] ?: dict[@"anchorX"]) floatValue];
        _anchorY = [(dict[@"y"] ?: dict[@"anchorY"]) floatValue];
        _borderWidth = [dict[@"borderWidth"] floatValue];
        _borderColor = [UIColor qmui_rgbaColorWithHexString:dict[@"borderColor"]];
        _borderRadius = [dict[@"borderRadius"] floatValue];
        _bgColor = [UIColor qmui_rgbaColorWithHexString:dict[@"bgColor"]];
        _padding = [dict[@"padding"] floatValue];
        NSString *textAlign = dict[@"textAlign"];
        if (kStringEqualToString(textAlign, @"left")) {
            _textAlign = NSTextAlignmentLeft;
        } else if (kStringEqualToString(textAlign, @"right")) {
            _textAlign = NSTextAlignmentRight;
        } else {
            _textAlign = NSTextAlignmentCenter;
        }
    }
    return self;
}

@end



@implementation WAMarker

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _identifier = dict[@"id"];
        _coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] floatValue],
                                                 [dict[@"longitude"] floatValue]);
        _title = dict[@"title"];
        _zIndex = [dict[@"zIndex"] intValue];
        _iconPath = dict[@"iconPath"];
        _rotate = [dict[@"rotate"] floatValue];
        _alpha = dict[@"alpha"] ? [dict[@"alpha"] floatValue] : 1.f;
        _width = dict[@"width"] ? [dict[@"width"] floatValue] : 0.f;
        _height = dict[@"height"] ? [dict[@"height"] floatValue] : 0.f;
        if (dict[@"callout"]) {
            _callout = [[WAMarkerCallout alloc] initWithDict:dict[@"callout"]];
        }
        if (dict[@"customCallout"]) {
            _customCallout = [[WAMarkerCustomCallout alloc] initWithDict:dict[@"customCallout"]];
        }
        if (dict[@"label"]) {
            _label = [[WAMarkerLabel alloc] initWithDict:dict[@"label"]];
        }
        NSDictionary *anchor = dict[@"anchor"];
        if (anchor) {
            _anchor = CGPointMake([anchor[@"x"] floatValue], [anchor[@"y"] floatValue]);
        } else {
            _anchor = CGPointMake(.5f, 1.f);
        }
        _ariaLabel = dict[@"ariaLabel"];
    }
    return self;
}

@end


@implementation WAPolyline

- (id)initWithDict:(NSDictionary *)dict
{
    NSArray *points = dict[@"points"];
    CLLocationCoordinate2D coordinates[points.count];
    NSUInteger index = 0;
    if (points && [points isKindOfClass:[NSArray class]]) {
        for (NSDictionary *point in points) {
            if ([point isKindOfClass:[NSDictionary class]]) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([point[@"latitude"] floatValue],
                                                                               [point[@"longitude"] floatValue]);
                coordinates[index] = coordinate;
                index ++;
            }
        }
    }
    if (self = [super initWithCoordinates:coordinates count:index]) {
        NSMutableArray *array = [NSMutableArray array];
        NSArray *colors = dict[@"colorList"];
        for (NSString *colorString in colors) {
            if ([colorString isKindOfClass:[NSString class]]) {
                UIColor *color = [UIColor qmui_rgbaColorWithHexString:colorString];
                if (color) {
                    [array addObject:color];
                }
            }
        }
        _colorList = [array copy];
        _color = [UIColor qmui_rgbaColorWithHexString:dict[@"color"]];
        _width = [dict[@"width"] floatValue];
        _dottedLine = [dict[@"dottedLine"] boolValue];
        _arrowLine = [dict[@"arrowLine"] boolValue];
        _arrowIconPath = dict[@"arrowIconPath"];
        _borderColor = [UIColor qmui_rgbaColorWithHexString:dict[@"borderColor"]];
        _borderWidth = [dict[@"borderWidth"] floatValue];
    }
    return self;
}

@end



@implementation WAPolygon

- (id)initWithDict:(NSDictionary *)dict
{
    NSArray *points = dict[@"points"];
    CLLocationCoordinate2D coordinates[points.count];
    NSUInteger index = 0;
    if (points && [points isKindOfClass:[NSArray class]]) {
        for (NSDictionary *point in points) {
            if ([point isKindOfClass:[NSDictionary class]]) {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([point[@"latitude"] floatValue],
                                                                               [point[@"longitude"] floatValue]);
                coordinates[index] = coordinate;
                index ++;
            }
        }
    }
    if (self = [super initWithWithCoordinates:coordinates count:index]) {
        _strokeWidth = [dict[@"strokeWidth"] floatValue];
        _strokeColor = [UIColor qmui_rgbaColorWithHexString:dict[@"strokeColor"]];
        _fillColor = [UIColor qmui_rgbaColorWithHexString:dict[@"fillColor"]];
        _zIndex = [dict[@"zIndex"] intValue];
    }
    return self;
}

@end



@implementation WACircle

- (id)initWithDict:(NSDictionary *)dict
{
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([dict[@"latitude"] floatValue],
                                                                   [dict[@"longitude"] floatValue]);
    if (self = [super initWithWithCenterCoordinate:coordinate radius:[dict[@"radius"] floatValue]]) {
        _color = [UIColor qmui_rgbaColorWithHexString:dict[@"color"]];
        _fillColor = [UIColor qmui_rgbaColorWithHexString:dict[@"fillColor"]];
        _strokeWidth = [dict[@"strokeWidth"] floatValue];
    }
    return self;
}

@end


@implementation WAControl

- (id)initWithDict:(NSDictionary *)dict
{
    if (self = [super init]) {
        _identifier = dict[@"id"];
        NSDictionary *position = dict[@"position"];
        _position = CGRectMake([position[@"left"] floatValue],
                               [position[@"top"] floatValue],
                               [position[@"width"] floatValue],
                               [position[@"height"] floatValue]);
        _iconPath = dict[@"iconPath"];
        _clickable = [dict[@"clickable"] boolValue];
    }
    return self;
}

@end
