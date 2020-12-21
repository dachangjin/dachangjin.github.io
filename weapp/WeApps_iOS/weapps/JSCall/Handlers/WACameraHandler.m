//
//  WACameraHandler.m
//  weapps
//
//  Created by tommywwang on 2020/7/26.
//  Copyright © 2020 tencent. All rights reserved.

#import "WACameraHandler.h"
#import "WACameraManager.h"
#import "Weapps.h"

kSELString(createNativeCameraComponent)
kSELString(createCameraContext)
kSELString(operateCameraContext)
kSELString(setCameraContextState)

kSELString(setZoom)
kSELString(setFlash)
kSELString(setDevicePosition)
kSELString(startRecord)
kSELString(stopRecord)
kSELString(takePhoto)
kSELString(startListening)
kSELString(stopListening)
kSELString(onCameraFrame)


@implementation WACameraHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            createNativeCameraComponent,
            createCameraContext,
            operateCameraContext,
            setCameraContextState
        ];
    }
    return methods;
}

JS_API(createNativeCameraComponent){

    kBeginCheck
    kCheck([NSDictionary class], @"state", NO)
    kEndCheck([NSDictionary class], @"position", NO)
    
    NSDictionary *position = event.args[@"position"];
    if (!([self checkValueClass:[NSNumber class] ofKey:@"top"
                         inDict:position canBeNil:NO
                withErrorString:&errorString] &&
       [self checkValueClass:[NSNumber class] ofKey:@"left"
                      inDict:position canBeNil:NO
             withErrorString:&errorString] &&
       [self checkValueClass:[NSNumber class] ofKey:@"height"
                      inDict:position canBeNil:NO
             withErrorString:&errorString] &&
       [self checkValueClass:[NSNumber class] ofKey:@"width"
                      inDict:position canBeNil:NO
             withErrorString:&errorString]
//          &&
//       [self checkValueClass:[NSNumber class] ofKey:@"scrollHeight" inDict:position canBeNil:YES withErrorString:&errorString]
          )) {
        kFailWithErrorWithReturn(@"createNativeCameraComponent", -1, errorString)
    }
    [[Weapps sharedApps].cameraManager createCameraViewWithWebView:event.webView
                                                          position:position
                                                             state:event.args
                                                   completionBlock:^(BOOL success,
                                                                     NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(createCameraContext){
    return @"";
}

JS_API(setCameraContextState){
    kBeginCheck
    kEndCheck([NSDictionary class], @"state", NO)
    [[Weapps sharedApps].cameraManager setCameraState:event.args[@"state"]];
    return @"";
}


JS_API(operateCameraContext){
    NSArray *operationTypes = @[
        setZoom,
        setFlash,
        setDevicePosition,
        startRecord,
        stopRecord,
        takePhoto,
        startListening,
        stopListening
    ];
    NSString *operationType = event.args[@"operationType"];
    if (![operationTypes containsObject:operationType]) {
        kFailWithErrorWithReturn(operateCameraContext, -1, @"operationType not support")
    }
    if (kStringEqualToString(operationType, setZoom)) {
        [self js_setZoom:event];
    } else if (kStringEqualToString(operationType, startRecord)) {
        [self js_startRecord:event];
    } else if (kStringEqualToString(operationType, stopRecord)) {
        [self js_stopRecord:event];
    } else if (kStringEqualToString(operationType, takePhoto)) {
        [self js_takePhoto:event];
    } else if (kStringEqualToString(operationType, startListening)) {
        [self js_startListening:event];
    } else if (kStringEqualToString(operationType, stopListening)){
        [self js_stopListening:event];
    } else if (kStringEqualToString(operationType, setFlash)) {
        [self js_setFlash:event];
    } else if (kStringEqualToString(operationType, setDevicePosition)) {
        [self js_setDevicePosition:event];
    }
    return @"";
}

JS_API(onCameraFrame){
    [[Weapps sharedApps].cameraManager onCameraFrame:event.callbacak
                                   completionHandler:^(BOOL success,
                                                       NSDictionary * _Nonnull result,
                                                       NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setZoom){
    kBeginCheck
    kEndCheck([NSNumber class], @"zoom", NO);
    NSNumber *zoom = event.args[@"zoom"];
    [[Weapps sharedApps].cameraManager setCameraZoom:[zoom floatValue]
                                   completionHandler:^(BOOL success,
                                                       NSDictionary * _Nonnull result,
                                                       NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(setFlash){
    kBeginCheck
    kEndCheck([NSString class], @"flash", NO);
    NSString *flash = event.args[@"flash"];
    [[Weapps sharedApps].cameraManager setCameraFlash:flash
                                    completionHandler:^(BOOL success,
                                                        NSDictionary * _Nonnull result,
                                                        NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}



JS_API(setDevicePosition){
    kBeginCheck
    kEndCheck([NSString class], @"devicePosition", NO);
    NSString *devicePosition = event.args[@"devicePosition"];
    [[Weapps sharedApps].cameraManager setCameraDevicePosition:devicePosition
                                             completionHandler:^(BOOL success,
                                                                 NSDictionary * _Nonnull result,
                                                                 NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(startRecord){
    kBeginCheck
    kEndCheck([NSString class], @"timeoutCallback", YES)
    NSString *timeoutCallback = event.args[@"timeoutCallback"];
    [[Weapps sharedApps].cameraManager startRecordWithTimeoutCallback:timeoutCallback
                                                    completionHandler:^(BOOL success,
                                                                        NSDictionary * _Nonnull result,
                                                                        NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopRecord){
    kBeginCheck
    kEndChecIsBoonlean(@"compressed", YES)
    BOOL compressed = [event.args[@"compressed"] boolValue];
    [[Weapps sharedApps].cameraManager stopRecordWithCompressed:compressed
                                              completionHandler:^(BOOL success,
                                                                  NSDictionary * _Nonnull result,
                                                                  NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(takePhoto){
    kBeginCheck
    kEndCheck([NSString class], @"quality", YES);
    NSString *quality = event.args[@"quality"] ?: @"normal";
    [[Weapps sharedApps].cameraManager takePhotoWithQuality:quality
                                          completionHandler:^(BOOL success,
                                                              NSDictionary * _Nonnull result,
                                                              NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result);
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(startListening){
    [[Weapps sharedApps].cameraManager startListeningCameraFrameWithCompletionHandler:^(BOOL success,
                                                                                        NSDictionary * _Nonnull result,
                                                                                        NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopListening){
    [[Weapps sharedApps].cameraManager stopListeningCameraFrameWithCompletionHandler:^(BOOL success,
                                                                                       NSDictionary * _Nonnull result,
                                                                                       NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

@end
