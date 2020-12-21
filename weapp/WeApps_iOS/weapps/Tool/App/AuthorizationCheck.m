//
//  AuthorizationCheck.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AuthorizationCheck.h"
#import <AVFoundation/AVCaptureDevice.h>
#import <CoreLocation/CoreLocation.h>
#import <EventKit/EventKit.h>
#import <Photos/Photos.h>

@implementation AuthorizationCheck


+ (BOOL)videoAuthorizationCheck
{
    return [self _AVCaptureAuthorizationCheckWithType:AVMediaTypeVideo];
}


/// 麦克风权限检测与选择
+ (BOOL)audioAuthorizaitonCheck
{
    return [self _AVCaptureAuthorizationCheckWithType:AVMediaTypeAudio];
}

/// 定位权限检测与选择
+ (BOOL)locationAuthorizationCheck
{
    if ([CLLocationManager locationServicesEnabled] == NO) {
        return NO;
    }
    CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
    if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
        return NO;
    } else {
        return YES;
    }
}

/// 日历权限检测与选择
+ (BOOL)eventAuthorizationCheck
{
    return [self evenStoreAuthorizationCheckWithType:EKEntityTypeEvent];
}

/// 备忘权限检测与选择
+ (BOOL)reminderAuthorizationCheck
{
    return [self evenStoreAuthorizationCheckWithType:EKEntityTypeReminder];
}

/// 相册权限检测与选择
+ (BOOL)photoLibraryAuthorizationCheck
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        return NO;
    } else if (status == PHAuthorizationStatusAuthorized) {
        return YES;
    }
    __block BOOL accessGranted = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            accessGranted = YES;
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return accessGranted;
}


#pragma mark - private
    
+ (BOOL)_AVCaptureAuthorizationCheckWithType:(AVMediaType)type
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:type];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
       return NO;
    } else if (authStatus == AVAuthorizationStatusAuthorized) {
       return YES;
    }
    //用户选择
    __block BOOL accessGranted = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    [AVCaptureDevice requestAccessForMediaType:type completionHandler:^(BOOL granted) {
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    if (accessGranted) {
        return YES;
    }else{
        return NO;
    }
}


+ (BOOL)evenStoreAuthorizationCheckWithType:(EKEntityType)type
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    if (status == EKAuthorizationStatusAuthorized) {
        return YES;
    } else if (status == EKAuthorizationStatusDenied || status == EKAuthorizationStatusRestricted) {
        return NO;
    }
    //用户选择
    __block BOOL accessGranted = NO;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    EKEventStore *store = [[EKEventStore alloc]init];
    [store requestAccessToEntityType:type completion:^(BOOL granted, NSError * _Nullable error) {
        accessGranted = granted;
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return accessGranted;
}
    
@end
