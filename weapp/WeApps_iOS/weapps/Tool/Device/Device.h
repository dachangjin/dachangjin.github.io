//
//  Device.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN



/// 设备相关
@interface Device : NSObject


/// 系统名
+ (NSString *)systemName;


/// 系统版本
+ (NSString *)systemVersion;


/// 设备model信息
+ (NSString *)model;


/// 设备名
+ (NSString *)platformString;

/// 电池电量
+ (float)batteryLevel;

/// 是否正在充电
+ (BOOL)isCharging;

/// 设置屏幕亮度
/// @param brightness 0~1.0
+ (void)setScreenBrightness:(CGFloat)brightness;

/// 屏幕亮度
+ (CGFloat)screenBrightness;

/// 设置屏幕常亮
/// @param keep 是否常亮
+ (void)setKeepScreenOn:(BOOL)keep;

/// 可以容量，单位KB。若失败返回0
+ (float)systemFreeSize;


/// 获取运营商名称，中国移动｜中国联通 | 中国电信 | 其他
+ (NSString *)carrierName;

/// 运营商信息
+ (NSArray <NSDictionary *>*)carriers;

/// 网络信息，wifi｜2g｜3g｜4g｜未知
+ (NSString *)networkType;


/// 是否移动数据网络连接
+ (BOOL)isReachableViaWWAN;


/// 是否WIFI连接
+ (BOOL)isReachableViaWIFI;

/// 是否联网
+ (BOOL)isReachable;


/// sim卡个数
+ (NSUInteger)simCount;


/// 屏幕scale
+ (CGFloat)pixelRatio;

/// 状态栏高度
+ (CGFloat)statusBarHeight;

/// tabbar高度
+ (CGFloat)stantardTabbarHeight;

/// wifi是否打开
+ (BOOL)isWifiOn;


/// 根据编码获取小程序QRCode对应编码
/// @param type 编码
+ (NSString *)scanTypeFromType:(NSString *)type;

@end

NS_ASSUME_NONNULL_END
