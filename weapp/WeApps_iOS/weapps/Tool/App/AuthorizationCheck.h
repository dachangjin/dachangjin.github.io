//
//  AuthorizationCheck.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface AuthorizationCheck : NSObject


/// 相机权限检测与选择
+ (BOOL)videoAuthorizationCheck;

/// 麦克风权限检测与选择
+ (BOOL)audioAuthorizaitonCheck;

/// 定位权限检测与选择
+ (BOOL)locationAuthorizationCheck;

/// 日历权限检测与选择
+ (BOOL)eventAuthorizationCheck;

/// 备忘权限检测与选择
+ (BOOL)reminderAuthorizationCheck;

/// 相册权限检测与选择
+ (BOOL)photoLibraryAuthorizationCheck;

@end

NS_ASSUME_NONNULL_END
