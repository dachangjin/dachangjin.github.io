//
//  WALocationHandler.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALocationHandler.h"
#import "WALocationManager.h"
#import "WAShowLocationViewController.h"

kSELString(stopLocationUpdate)
kSELString(startLocationUpdateBackground)
kSELString(startLocationUpdate)
kSELString(openLocation)
kSELString(onLocationChange)
kSELString(offLocationChange)
kSELString(getLocation)
kSELString(chooseLocation)

@implementation WALocationHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            stopLocationUpdate,
            startLocationUpdate,
            startLocationUpdateBackground,
            openLocation,
            onLocationChange,
            offLocationChange,
            getLocation,
            chooseLocation
        ];
    }
    return methods;
}


JS_API(startLocationUpdate){
    WALocationManager *manager = [WALocationManager sharedManager];
    [manager startLocationUpdateWithCompletion:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(@{@"msg": @"start location update"})
        } else {
            [self event:event failWithError:error];
        }
    }];
    return @"";
}

JS_API(startLocationUpdateBackground){
    [self js_startLocationUpdate:event];
    return @"";
}

JS_API(stopLocationUpdate){
    WALocationManager *manager = [WALocationManager sharedManager];
    [manager stopLocationUpdate];
    kSuccessWithDic(@{@"msg": @"stop location update"})
    return @"";
}

JS_API(getLocation){
    
    kBeginCheck
    kCheck([NSString class], @"type", YES)
    kCheckIsBoolean([NSNumber class], @"isHighAccuracy", YES, YES)
    kEndCheck([NSNumber class], @"highAccuracyExpireTime", YES)
    
    NSDictionary *params = event.args;
    NSString *type = params[@"type"];
//    NSNumber *altitude = params[@"altitude"];
    NSNumber *isHighAccuracy = params[@"isHighAccuracy"];
    NSNumber *highAccuracyExpireTime = params[@"highAccuracyExpireTime"];
    
    if (!type) {
        type = @"wgs84";
    }
    WALocationManager *manager = [WALocationManager sharedManager];
    [manager getLocationWithType:type
                  isHighAccuracy:[isHighAccuracy boolValue]
          highAccuracyExpireTime:[highAccuracyExpireTime doubleValue]
                      completion:^(WALocationModel * _Nonnull model, NSError * _Nonnull error) {
        if (error) {
            [self event:event failWithError:error];
        } else {
            CLLocationDegrees latitude = model.location.coordinate.latitude;
            CLLocationDegrees longitude = model.location.coordinate.longitude;
            if (kStringEqualToString(type, @"gcj02")) {
                latitude = model.marsCoordinate.latitude;
                longitude = model.marsCoordinate.longitude;
            }
            kSuccessWithDic((@{
                @"latitude"             : [NSNumber numberWithDouble:latitude],
                @"longitude"            : [NSNumber numberWithDouble:longitude],
                @"speed"                : [NSNumber numberWithDouble:model.location.speed > 0 ? : 0],
                @"accuracy"             : [NSNumber numberWithDouble:MAX(model.location.verticalAccuracy,
                model.location.horizontalAccuracy)],
                @"altitude"             : [NSNumber numberWithDouble:model.location.altitude],
                @"verticalAccuracy"     : [NSNumber numberWithDouble:model.location.verticalAccuracy],
                @"horizontalAccuracy"   : [NSNumber numberWithDouble:model.location.horizontalAccuracy]
                            }))
        }
    }];
    
    return @"";
}

JS_API(onLocationChange){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(onLocationChange, -1, @"params invalid")
    }
    [event.webView.webHost addLocationChangeCallback:event.callbacak];
    kSuccessWithDic((@{
    @"msg": [NSString stringWithFormat:@"%@，callback:%@",onLocationChange,event.callbacak]
                 }))
    return @"";
}


JS_API(offLocationChange){
    if ([self isInvalidObject:event.funcName ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(offLocationChange, -1, @"params invalid")
    }
    [event.webView.webHost removeLocationChangeCallback:event.callbacak];
    return @"";
}

JS_API(openLocation){
    NSDictionary *params = event.args;

    if (![self isValidObject:params[@"latitude"] ofClass:[NSNumber class]] ||
        ![self isValidObject:params[@"longitude"] ofClass:[NSNumber class]]) {
        kFailWithErrorWithReturn(openLocation, -1, @"params invalid");
    }
    if ([self isInvalidObject:params[@"scale"] ofClass:[NSNumber class]] ||
        [self isInvalidObject:params[@"name"] ofClass:[NSString class]] ||
        [self isInvalidObject:params[@"address"] ofClass:[NSString class]]) {
        kFailWithErrorWithReturn(openLocation, -1, @"params invalid");
    }

    WAShowLocationViewController *VC = [[WAShowLocationViewController alloc] init];
    VC.params = params;
    UIViewController *topVC = [event.webView.webHost currentViewController];
    if (topVC.navigationController) {
        [topVC.navigationController pushViewController:VC animated:YES];
    } else {
        VC.modalPresentationStyle = UIModalPresentationFullScreen;
        [topVC presentViewController:VC animated:YES completion:nil];
    }
    kSuccessWithDic((@{
    @"msg": [NSString stringWithFormat:@"%@",openLocation]
                 }))
    return @"";
    
}


JS_API(chooseLocation){
    return @"";
}

@end
