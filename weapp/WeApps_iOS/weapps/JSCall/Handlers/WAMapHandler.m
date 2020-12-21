//
//  WAMapHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMapHandler.h"
#import "Weapps.h"

kSELString(createMapContext)
kSELString(operateMapContext)
kSELString(setMapContextState)


@implementation WAMapHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createMapContext,
            operateMapContext,
            setMapContextState
        ];
    }
    return methods;
}

JS_API(createMapContext){
    kBeginCheck
    kCheck([NSDictionary class], @"position", NO)
    kEndCheck([NSString class], @"mapId", NO)
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager createMapViewWithMapId:mapId
                                                  position:event.args[@"position"]
                                                     state:event.args[@"state"]
                                                 inWebView:event.webView
                                         completionHandler:^(BOOL success,
                                                             NSDictionary * _Nullable result,
                                                             NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setMapContextState){
    kBeginCheck
    kCheck([NSString class], @"mapId", NO)
    kEndCheck([NSDictionary class], @"state", NO)
    NSString *mapId = event.args[@"mapId"];
    NSDictionary *state = event.args[@"state"];
    [[Weapps sharedApps].mapManager mapView:mapId
                                   setState:state];
    return @"";
}

JS_API(operateMapContext){
    kBeginCheck
    kCheck([NSString class], @"operationType", NO)
    kEndCheck([NSString class], @"mapId", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"getCenterLocation")) {
        return [self _getCenterLocation:event];
    } else if (kStringEqualToString(operationType, @"getRegion")) {
        return [self _getRegion:event];
    } else if (kStringEqualToString(operationType, @"getRotate")) {
        return [self _getRotate:event];
    } else if (kStringEqualToString(operationType, @"getScale")) {
        return [self _getScale:event];
    } else if (kStringEqualToString(operationType, @"getSkew")) {
        return [self _getSkew:event];
    } else if (kStringEqualToString(operationType, @"includePoints")) {
        return [self _includePoints:event];
    } else if (kStringEqualToString(operationType, @"moveAlong")) {
        return [self _moveAlong:event];
    } else if (kStringEqualToString(operationType, @"moveToLocation")) {
        return [self _moveToLocation:event];
    } else if (kStringEqualToString(operationType, @"setCenterOffset")) {
        return [self _setCenterOffset:event];
    } else if (kStringEqualToString(operationType, @"translateMarker")) {
        return [self _translateMarker:event];
    }
    return @"";
}


PRIVATE_API(getCenterLocation){
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
     getCenterLocationWithCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(getRegion){
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
             getRegionWithCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(getRotate){
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
             getRotateWithCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(getScale){
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
              getScaleWithCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(getSkew){
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
               getSkewWithCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(includePoints){
    kBeginCheck
    kCheck([NSArray class], @"points", NO)
    kEndCheck([NSArray class], @"padding", YES)
    NSArray *points = event.args[@"points"];
    NSArray *padding = event.args[@"padding"];
    NSString *mapId = event.args[@"mapId"];
    [[Weapps sharedApps].mapManager mapView:mapId
                              includePoints:points
                                    padding:padding
                      withCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(moveAlong){
    kBeginCheck
    kCheck([NSNumber class], @"markerId",NO)
    kCheck([NSArray class], @"path", NO)
    kCheckIsBoolean([NSNumber class], @"autoRotate", YES, YES)
    kEndCheck([NSNumber class], @"duration", NO)
    NSNumber *markerId = event.args[@"markerId"];
    NSArray *path = event.args[@"path"];
    NSString *mapId = event.args[@"mapId"];
    CGFloat duration = [event.args[@"duration"] floatValue] / 1000;
    BOOL autoRotate = YES;
    if (event.args[@"autoRotate"] && ![event.args[@"autoRotate"] boolValue]) {
        autoRotate = NO;
    }
    [[Weapps sharedApps].mapManager mapView:mapId
                            moveMarkerAlong:markerId
                                   withPath:path
                                 autoRotate:autoRotate
                                   duration:duration
                          completionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(moveToLocation){
    kBeginCheck
    kCheck([NSNumber class], @"longitude", YES)
    kEndCheck([NSNumber class], @"latitude", YES)
    NSString *mapId = event.args[@"mapId"];
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;;
    if (event.args[@"longitude"] && event.args[@"latitude"]) {
        coordinate = CLLocationCoordinate2DMake([event.args[@"latitude"] floatValue], [event.args[@"longitude"] floatValue]);
    }
    [[Weapps sharedApps].mapManager mapView:mapId
                             moveToLocation:coordinate
                      withCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(setCenterOffset){
    kBeginCheck
    kEndCheck([NSArray class], @"offset", NO)
    NSString *mapId = event.args[@"mapId"];
    NSArray *offset = event.args[@"offset"];
    if (offset.count != 2) {
        kFailWithErrorWithReturn(@"setCenterOffset", -1, @"invalid parameter offset")
    }
    CGPoint point = CGPointMake([[offset firstObject] floatValue], [[offset lastObject] floatValue]);
    [[Weapps sharedApps].mapManager mapView:mapId
                            setCenterOffset:point
                      withCompletionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(translateMarker){
    kBeginCheck
    kCheck([NSNumber class], @"markerId", NO)
    kCheck([NSDictionary class], @"destination", NO)
    kCheckInDict(event.args[@"destination"], [NSNumber class], @"longitude", NO)
    kCheckInDict(event.args[@"destination"], [NSNumber class], @"latitude", NO)
    kCheckIsBoolean([NSNumber class], @"autoRotate", NO, YES)
    kCheck([NSNumber class], @"rotate", NO)
    kCheckIsBoolean([NSNumber class], @"moveWithRotate", YES, YES)
    kCheck([NSNumber class], @"duration", YES)
    kEndCheck([NSString class], @"animationEnd", YES)
    NSString *mapId = event.args[@"mapId"];
    NSNumber *markerId = event.args[@"markerId"];
    CLLocationCoordinate2D destination = CLLocationCoordinate2DMake([event.args[@"destination"][@"latitude"] floatValue], [event.args[@"destination"][@"longitude"] floatValue]);
    BOOL autoRotate = [event.args[@"autoRotate"] boolValue];
    CGFloat rotate = [event.args[@"rotate"] floatValue];
    BOOL moveWithRotate = NO;
    if (event.args[@"moveWithRotate"]) {
        moveWithRotate = [event.args[@"moveWithRotate"] boolValue];
    }
    NSTimeInterval duration = 1;
    if (event.args[@"duration"]) {
        duration = [event.args[@"duration"] floatValue] / 1000;
    }
    
    NSString *animationEndCallback = event.args[@"animationEnd"];
    [[Weapps sharedApps].mapManager mapView:mapId
                            translateMarker:markerId
                              toDestination:destination
                             withAutoRotate:autoRotate
                                     rotate:rotate
                             moveWithRotate:moveWithRotate
                                   duration:duration
                               animationEnd:animationEndCallback
                          completionHandler:^(BOOL success,
                                              NSDictionary * _Nullable result,
                                              NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}
@end
