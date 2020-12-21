//
//  WAIBeaconHandler.m
//  weapps
//
//  Created by tommywwang on 2020/9/21.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAIBeaconHandler.h"
#import "WALocationManager.h"

kSELString(startBeaconDiscovery)
kSELString(stopBeaconDiscovery)
kSELString(onBeaconUpdate)
kSELString(onBeaconServiceChange)
kSELString(offBeaconUpdate)
kSELString(offBeaconServiceChange)
kSELString(getBeacons)

@implementation WAIBeaconHandler


- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            startBeaconDiscovery,
            stopBeaconDiscovery,
            onBeaconUpdate,
            onBeaconServiceChange,
            offBeaconUpdate,
            offBeaconServiceChange,
            getBeacons
        ];
    }
    return methods;
}

JS_API(startBeaconDiscovery){
    kBeginCheck
    kCheck([NSArray class], @"uuids", NO)
    kEndChecIsBoonlean(@"ignoreBluetoothAvailable", YES)
    NSArray *uuids = event.args[@"uuids"];
    NSMutableArray <NSUUID *>*UUIDS = [NSMutableArray array];
    for (NSString *uuid in uuids) {
        NSUUID *UUID = [[NSUUID alloc] initWithUUIDString:uuid];
        if (!UUID) {
            kFailWithErrorWithReturn(@"startBeaconDiscovery", IBeaconErrorInvalidData, @"invalid data")
        }
        [UUIDS addObject:UUID];
    }
    BOOL ignoreBluetoothAvailable = NO;
    if ([event.args[@"ignoreBluetoothAvailable"] boolValue]) {
        ignoreBluetoothAvailable = YES;
    }
    [[WALocationManager sharedManager] startBeaconDiscoveryWithUUIDS:UUIDS
                                            ignoreBluetoothAvailable:ignoreBluetoothAvailable
                                                   completionHandler:^(BOOL success,
                                                                       NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopBeaconDiscovery){
    [[WALocationManager sharedManager] stopBeaconDiscoveryWithcompletionHandler:^(BOOL success,
                                                                                  NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onBeaconUpdate){
    [[WALocationManager sharedManager] webView:event.webView
                                onBeaconUpdate:event.callbacak];
    return @"";
}

JS_API(onBeaconServiceChange){
    [[WALocationManager sharedManager] webView:event.webView
                         onBeaconServiceChange:event.callbacak];
    return @"";
}

JS_API(offBeaconUpdate){
    [[WALocationManager sharedManager] webView:event.webView
                               offBeaconUpdate:event.callbacak];
    return @"";
}

JS_API(offBeaconServiceChange){
    [[WALocationManager sharedManager] webView:event.webView
                        offBeaconServiceChange:event.callbacak];
    return @"";
}

JS_API(getBeacons){
    [[WALocationManager sharedManager] getBeaconsWithcompletionHandler:^(BOOL success,
                                                                         NSDictionary * _Nonnull result, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}
@end
