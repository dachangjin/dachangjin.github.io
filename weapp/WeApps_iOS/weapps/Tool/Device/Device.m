//
//  Device.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "Device.h"
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "AFNetworkReachabilityManager.h"
#import "sys/utsname.h"
#import <UIKit/UIKit.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <net/if.h>
#import <AVFoundation/AVFoundation.h>


@implementation Device

+ (NSString *)systemName
{
    return [[UIDevice currentDevice] systemName];
}


+ (NSString *)systemVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)model
{
    return [[UIDevice currentDevice] model];
}

+ (NSString *)platformString{
    
    
    NSString *platform = [self _platform];
    if (kStringEqualToString(platform, @"i386")) {
        return @"Simulator";
    }
    if (kStringEqualToString(platform, @"x86_64")) { 
        return @"Simulator";
    }
    if(kStringContainString(platform, @"iPhone")){
        return [self _iPhonePlatform:platform];
    }
    if(kStringContainString(platform, @"iPad")){
        return [self _iPadPlatform:platform];
    }
    if(kStringContainString(platform, @"iPod")){
        return [self _iPodPlatform:platform];
    }
    if(kStringEqualToString(platform, @"AirPods")){
        return [self _AirPodsPlatform:platform];
    }
    if(kStringContainString(platform, @"AppleTV")){
        return [self _AppleTVPlatform:platform];
    }
    if(kStringContainString(platform, @"Watch")){
        return [self _AppleWatchPlatform:platform];
    }
    if(kStringContainString(platform, @"HomePod")){
        return [self _HomePodPlatform:platform];
    }
    
    return @"Unknown iOS Device";
}

+ (float)batteryLevel
{
    if (![UIDevice currentDevice].isBatteryMonitoringEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    float level = [UIDevice currentDevice].batteryLevel;
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    return level;
}


+ (BOOL)isCharging
{
    if (![UIDevice currentDevice].isBatteryMonitoringEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    BOOL isCharging = [UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging;
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    return isCharging;
}

+ (void)setScreenBrightness:(CGFloat)brightness
{
    [[UIScreen mainScreen] setBrightness:brightness];
}

+ (CGFloat)screenBrightness
{
    return [UIScreen mainScreen].brightness;
}


+ (void)setKeepScreenOn:(BOOL)keep
{
    [UIApplication sharedApplication].idleTimerDisabled = keep;
}

+ (float)systemFreeSize
{
    NSError * error;
    NSDictionary * infoDic = [[NSFileManager defaultManager] attributesOfFileSystemForPath: NSHomeDirectory() error: &error];
    if (infoDic && !error) {
        NSNumber * fileSystemFreeSize = [infoDic objectForKey: NSFileSystemFreeSize];
        return [fileSystemFreeSize floatValue] / 1024.0f;
    } else {
        return 0;
    }
}


+ (NSArray <NSDictionary *>*)carriers
{
    CTTelephonyNetworkInfo *networkInfo = [self _telephonyNetworkInfo];
    NSMutableArray *carriers = [NSMutableArray array];
    if (@available(iOS 12.0, *)) {
         NSDictionary *ctDict = networkInfo.serviceSubscriberCellularProviders;
        for (CTCarrier *carrier in [ctDict allValues]) {
            NSString *name = [self nameByCarrier:carrier];
            NSDictionary *dic = @{
                @"name": name,
                @"allowsVOIP": [NSNumber numberWithBool:carrier.allowsVOIP]
            };
            [carriers addObject:dic];
        }
    }else {
         CTCarrier *carrier = [networkInfo subscriberCellularProvider];
         NSString *name = [self nameByCarrier:carrier];
         NSDictionary *dic = @{
             @"name": name,
             @"allowsVOIP": [NSNumber numberWithBool:carrier.allowsVOIP]
         };
         [carriers addObject:dic];
    }
    return carriers;
}

+ (NSString *)carrierName{
    
    NSString *carrierName = @"";
    CTTelephonyNetworkInfo *telephonyNetworkInfo = [self _telephonyNetworkInfo];
    CTCarrier *ca = telephonyNetworkInfo.subscriberCellularProvider;
    NSString *code = [ca mobileNetworkCode];
    if (kStringEqualToString(code,@"00") || kStringEqualToString(code,@"02") || kStringEqualToString(code,@"07")) {
        carrierName = @"中国移动";
    } else if (kStringEqualToString(code,@"03") || kStringEqualToString(code,@"05") || kStringEqualToString(code,@"11")) {
        carrierName =  @"中国电信";
    } else if (kStringEqualToString(code,@"01") || kStringEqualToString(code,@"06")) {
        carrierName =  @"中国联通";
    } else if (kStringEqualToString(code,@"20")) {
        carrierName =  @"中国铁通";
    } else {
        carrierName = @"其他";
    }
    return carrierName;
   
}


+ (NSString *)networkType
{
    if (![self isReachable]) {
        return @"none";
    }
    if ([self isReachableViaWIFI]) {
        return @"wifi";
    }
    CTTelephonyNetworkInfo *telephonyNetworkInfo = [self _telephonyNetworkInfo];
    NSString *radioAccessTech = telephonyNetworkInfo.currentRadioAccessTechnology;
    NSString *networkType = @"unknow";
    
    if (kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyEdge") ||
        kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyGPRS")) {
        networkType = @"2G";
    }
    else if (kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyWCDMA") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyCDMA1x") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyCDMAEVDORev0") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyCDMAEVDORevA") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyCDMAEVDORevB") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyHSDPA") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyHSUPA")) {
        networkType = @"3G";
    }
    else if (kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyLTE") ||
             kStringEqualToString(radioAccessTech,@"CTRadioAccessTechnologyeHRPD")) {
        networkType = @"4G";
    }
    
    return networkType;;
}


+ (BOOL)isReachableViaWWAN
{
   
   return [[AFNetworkReachabilityManager sharedManager] isReachableViaWWAN];
   
}


+ (BOOL)isReachableViaWIFI
{
    return [[AFNetworkReachabilityManager sharedManager] isReachableViaWiFi];
}


+ (BOOL)isReachable
{
    return [[AFNetworkReachabilityManager sharedManager] isReachable];
}

+ (NSUInteger)simCount
{
    CTTelephonyNetworkInfo *networkInfo = [self _telephonyNetworkInfo];
    if (@available(iOS 12.0, *)) {
         NSDictionary *ctDict = networkInfo.serviceSubscriberCellularProviders;
         if ([ctDict allKeys].count > 1) {
              NSArray *keys = [ctDict allKeys];
              CTCarrier *carrier1 = [ctDict objectForKey:[keys firstObject]];
              CTCarrier *carrier2 = [ctDict objectForKey:[keys lastObject]];
              if (carrier1.mobileCountryCode.length && carrier2.mobileCountryCode.length) {
                   return 2;
              }else if (!carrier1.mobileCountryCode.length && !carrier2.mobileCountryCode.length) {
                   return 0;
              }else {
                   return 1;
              }
         }else if ([ctDict allKeys].count == 1) {
              NSArray *keys = [ctDict allKeys];
              CTCarrier *carrier1 = [ctDict objectForKey:[keys firstObject]];
              if (carrier1.mobileCountryCode.length) {
                   return 1;
              }else {
                   return 0;
              }
         }else {
              return 0;
         }
    }else {
         CTCarrier *carrier = [networkInfo subscriberCellularProvider];
         NSString *carrierName = carrier.mobileCountryCode;
         if (carrierName.length) {
              return 1;
         }else {
              return 0;
         }
    }
}

+ (CGFloat)pixelRatio
{
    return [UIScreen mainScreen].scale;
}


+ (CGFloat)statusBarHeight
{
    CGFloat statusBarHeight = 0;
    if (@available(iOS 13.0, *)) {
        statusBarHeight = [UIApplication sharedApplication].windows.firstObject.windowScene.statusBarManager.statusBarFrame.size.height;
    } else {
        statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    return statusBarHeight;
}


+ (CGFloat)stantardTabbarHeight
{
    return [self _isIPhoneXSeries] ? 83 : 49;
}


+ (BOOL)isWifiOn
{
    NSCountedSet * cset = [[NSCountedSet alloc] init];
    struct ifaddrs *interfaces;
    if( ! getifaddrs(&interfaces) ) {
       for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
           if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
               [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
           }
       }
    }
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}


+ (NSString *)scanTypeFromType:(NSString *)type
{
    NSString *scanType = @"";
    if ([type isEqualToString:AVMetadataObjectTypeAztecCode]) {
        scanType = @"AZTEC";
    } else if ([type isEqualToString:AVMetadataObjectTypeUPCECode]) {
        scanType = @"UPC_E";
    } else if ([type isEqualToString:AVMetadataObjectTypeCode39Code]) {
        scanType = @"CODE_39";
    } else if ([type isEqualToString:AVMetadataObjectTypeCode39Mod43Code]) {
        scanType = @"CODE_39_MOD_43";
    } else if ([type isEqualToString:AVMetadataObjectTypeEAN13Code]) {
        scanType = @"EAN_13";
    } else if ([type isEqualToString:AVMetadataObjectTypeEAN8Code]) {
        scanType = @"EAN_8";
    } else if ([type isEqualToString:AVMetadataObjectTypeCode93Code]) {
        scanType = @"CODE_93";
    } else if ([type isEqualToString:AVMetadataObjectTypeCode128Code]) {
        scanType = @"CODE_128";
    } else if ([type isEqualToString:AVMetadataObjectTypePDF417Code]) {
        scanType = @"PDF_417";
    } else if ([type isEqualToString:AVMetadataObjectTypeQRCode]) {
        scanType = @"QR_CODE";
    } else if ([type isEqualToString:AVMetadataObjectTypeAztecCode]) {
        scanType = @"AZTEC";
    }  else if ([type isEqualToString:AVMetadataObjectTypeInterleaved2of5Code]) {
        scanType = @"INTERLEAVE";
    }  else if ([type isEqualToString:AVMetadataObjectTypeITF14Code]) {
        scanType = @"ITF";
    }  else if ([type isEqualToString:AVMetadataObjectTypeDataMatrixCode]) {
        scanType = @"DATA_MATRIX";
    }
    
    return scanType;
}

#pragma mark private

+ (BOOL)_isIPhoneXSeries
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    return (CGSizeEqualToSize(size, CGSizeMake(276, 597)) ||
            CGSizeEqualToSize(size, CGSizeMake(597, 276)) ||
            CGSizeEqualToSize(size, CGSizeMake(375, 812)) ||
            CGSizeEqualToSize(size, CGSizeMake(812, 375)) ||
            CGSizeEqualToSize(size, CGSizeMake(360, 780)) ||
            CGSizeEqualToSize(size, CGSizeMake(780, 360)) ||
            CGSizeEqualToSize(size, CGSizeMake(390, 844)) ||
            CGSizeEqualToSize(size, CGSizeMake(844, 390)) ||
            CGSizeEqualToSize(size, CGSizeMake(414, 896)) ||
            CGSizeEqualToSize(size, CGSizeMake(896, 414)) ||
            CGSizeEqualToSize(size, CGSizeMake(428, 926)) ||
            CGSizeEqualToSize(size, CGSizeMake(926, 428))
            );
}

+ (CTTelephonyNetworkInfo *)_telephonyNetworkInfo
{
    static CTTelephonyNetworkInfo * telephonyNetworkInfo = nil;
    static dispatch_once_t creatTelephonyNetworkInfoOnceToken;//保证多线程访问情况下，此对象仍然只生成一次
    dispatch_once(& creatTelephonyNetworkInfoOnceToken, ^{
        telephonyNetworkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    return telephonyNetworkInfo;
}






+ (NSString *)nameByCarrier:(CTCarrier *)carrier
{
    if (carrier.carrierName) {
        return carrier.carrierName;
    }
    NSString *code = [carrier mobileNetworkCode];
    if (kStringEqualToString(code,@"00") || kStringEqualToString(code,@"02") || kStringEqualToString(code,@"07")) {
         return @"中国移动";
    } else if (kStringEqualToString(code,@"03") || kStringEqualToString(code,@"05") || kStringEqualToString(code,@"11")) {
        return @"中国电信";
    } else if (kStringEqualToString(code,@"01") || kStringEqualToString(code,@"06")) {
        return @"中国联通";
    } else if (kStringEqualToString(code,@"20")) {
        return @"中国铁通";
    } else {
        return @"其他";
    }
}


+ (NSString *)_platform{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return deviceString;
}


+ (NSString *)_iPhonePlatform:(NSString *)platform{
    
    
    if (kStringEqualToString(platform, @"iPhone1,1"))    return @"iPhone";
    if (kStringEqualToString(platform, @"iPhone1,2"))    return @"iPhone 3G";
    if (kStringEqualToString(platform, @"iPhone2,1"))    return @"iPhone 3GS";
    if (kStringEqualToString(platform, @"iPhone3,1"))    return @"iPhone 4";
    if (kStringEqualToString(platform, @"iPhone3,2"))    return @"iPhone 4";
    if (kStringEqualToString(platform, @"iPhone3,3"))    return @"iPhone 4";
    if (kStringEqualToString(platform, @"iPhone4,1"))    return @"iPhone 4s";
    if (kStringEqualToString(platform, @"iPhone5,1"))    return @"iPhone 5";
    if (kStringEqualToString(platform, @"iPhone5,2"))    return @"iPhone 5";
    if (kStringEqualToString(platform, @"iPhone5,3"))   return @"iPhone 5c";
    if (kStringEqualToString(platform, @"iPhone5,4"))   return @"iPhone 5c";
    if (kStringEqualToString(platform, @"iPhone6,1"))    return @"iPhone 5s";
    if (kStringEqualToString(platform, @"iPhone6,2"))    return @"iPhone 5s";
    if (kStringEqualToString(platform, @"iPhone7,2"))    return @"iPhone 6";
    if (kStringEqualToString(platform, @"iPhone7,1"))    return @"iPhone 6 Plus";
    if (kStringEqualToString(platform, @"iPhone8,1"))    return @"iPhone 6s";
    if (kStringEqualToString(platform, @"iPhone8,2"))    return @"iPhone 6s Plus";
    if (kStringEqualToString(platform, @"iPhone8,4"))    return @"iPhone SE";
    if (kStringEqualToString(platform, @"iPhone9,1"))    return @"iPhone 7";
    if (kStringEqualToString(platform, @"iPhone9,3"))    return @"iPhone 7";
    if (kStringEqualToString(platform, @"iPhone9,2"))    return @"iPhone 7 Plus";
    if (kStringEqualToString(platform, @"iPhone9,4"))    return @"iPhone 7 Plus";
    if (kStringEqualToString(platform, @"iPhone10,1"))  return @"iPhone 8";
    if (kStringEqualToString(platform, @"iPhone10,4"))  return @"iPhone 8";
    if (kStringEqualToString(platform, @"iPhone10,2"))  return @"iPhone 8 Plus";
    if (kStringEqualToString(platform, @"iPhone10,5"))  return @"iPhone 8 Plus";
    if (kStringEqualToString(platform, @"iPhone10,3"))  return @"iPhone X";
    if (kStringEqualToString(platform, @"iPhone10,6"))  return @"iPhone X";
    if (kStringEqualToString(platform, @"iPhone11,8"))  return  @"iPhone XR";
    if (kStringEqualToString(platform, @"iPhone11,2"))  return @"iPhone XS";
    if (kStringEqualToString(platform, @"iPhone11,4"))  return @"iPhone XS Max";
    if (kStringEqualToString(platform, @"iPhone11,6"))  return @"iPhone XS Max";
    if (kStringEqualToString(platform, @"iPhone12,1"))  return  @"iPhone 11";
    if (kStringEqualToString(platform, @"iPhone12,3"))  return  @"iPhone 11 Pro";
    if (kStringEqualToString(platform, @"iPhone12,5"))  return  @"iPhone 11 Pro Max";
    if (kStringEqualToString(platform, @"iPhone12,8"))  return  @"iPhone SE (2nd generation)";
    
    return [NSString stringWithFormat:@"Unknown iPhone Identifier:%@", platform];
}


+ (NSString *)_iPadPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"iPad1,1"))   return @"iPad";
    if (kStringEqualToString(platform, @"iPad2,1"))   return @"iPad 2";
    if (kStringEqualToString(platform, @"iPad2,2"))   return @"iPad 2";
    if (kStringEqualToString(platform, @"iPad2,3"))   return @"iPad 2";
    if (kStringEqualToString(platform, @"iPad2,4"))   return @"iPad 2";
    if (kStringEqualToString(platform, @"iPad3,1"))   return @"iPad (3rd generation)";
    if (kStringEqualToString(platform, @"iPad3,2"))   return @"iPad (3rd generation)";
    if (kStringEqualToString(platform, @"iPad3,3"))   return @"iPad (3rd generation)";
    if (kStringEqualToString(platform, @"iPad3,4"))   return @"iPad (4th generation)";
    if (kStringEqualToString(platform, @"iPad3,5"))   return @"iPad (4th generation)";
    if (kStringEqualToString(platform, @"iPad3,6"))   return @"iPad (4th generation)";
    if (kStringEqualToString(platform, @"iPad6,11"))  return @"iPad (5th generation)";
    if (kStringEqualToString(platform, @"iPad6,12"))  return @"iPad (5th generation)";
    if (kStringEqualToString(platform, @"iPad7,5"))   return @"iPad (6th generation)";
    if (kStringEqualToString(platform, @"iPad7,6"))   return @"iPad (6th generation)";
    if (kStringEqualToString(platform, @"iPad7,11"))   return @"iPad (7th generation)";
    if (kStringEqualToString(platform, @"iPad7,12"))   return @"iPad (7th generation)";
    if (kStringEqualToString(platform, @"iPad4,1"))   return @"iPad Air";
    if (kStringEqualToString(platform, @"iPad4,2"))   return @"iPad Air";
    if (kStringEqualToString(platform, @"iPad4,3"))   return @"iPad Air";
    if (kStringEqualToString(platform, @"iPad5,3"))   return @"iPad Air 2";
    if (kStringEqualToString(platform, @"iPad5,4"))   return @"iPad Air 2";
    if (kStringEqualToString(platform, @"iPad11,3"))   return @"iPad Air (3rd generation)";
    if (kStringEqualToString(platform, @"iPad11,4"))   return @"iPad Air (3rd generation)";
    if (kStringEqualToString(platform, @"iPad6,7"))   return @"iPad Pro (12.9-inch) ";
    if (kStringEqualToString(platform, @"iPad6,8"))   return @"iPad Pro (12.9-inch) ";
    if (kStringEqualToString(platform, @"iPad6,3"))   return @"iPad Pro (9.7-inch)";
    if (kStringEqualToString(platform, @"iPad6,4"))   return @"iPad Pro (9.7-inch)";
    if (kStringEqualToString(platform, @"iPad7,1"))   return @"iPad Pro (12.9-inch) (2nd generation) ";
    if (kStringEqualToString(platform, @"iPad7,2"))   return @"iPad Pro (12.9-inch) (2nd generation) ";
    if (kStringEqualToString(platform, @"iPad7,3"))   return @"iPad Pro (10.5-inch)";
    if (kStringEqualToString(platform, @"iPad7,4"))   return @"iPad Pro (10.5-inch)";
    if (kStringEqualToString(platform, @"iPad8,1"))   return @"iPad Pro (11-inch)";
    if (kStringEqualToString(platform, @"iPad8,2"))   return @"iPad Pro (11-inch)";
    if (kStringEqualToString(platform, @"iPad8,3"))   return @"iPad Pro (11-inch)";
    if (kStringEqualToString(platform, @"iPad8,4"))   return @"iPad Pro (11-inch)";
    if (kStringEqualToString(platform, @"iPad8,5"))   return @"iPad Pro (12.9-inch) (3rd generation)";
    if (kStringEqualToString(platform, @"iPad8,6"))   return @"iPad Pro (12.9-inch) (3rd generation)";
    if (kStringEqualToString(platform, @"iPad8,7"))   return @"iPad Pro (12.9-inch) (3rd generation)";
    if (kStringEqualToString(platform, @"iPad8,8"))   return @"iPad Pro (12.9-inch) (3rd generation)";
    if (kStringEqualToString(platform, @"iPad8,9"))   return @"iPad Pro (11-inch) (2nd generation)";
    if (kStringEqualToString(platform, @"iPad8,10"))   return @"iPad Pro (11-inch) (2nd generation)";
    if (kStringEqualToString(platform, @"iPad8,11"))   return @"iPad Pro (12.9-inch) (4th generation)";
    if (kStringEqualToString(platform, @"iPad8,12"))   return @"iPad Pro (12.9-inch) (4th generation)";
    if (kStringEqualToString(platform, @"iPad2,5"))   return @"iPad mini";
    if (kStringEqualToString(platform, @"iPad2,6"))   return @"iPad mini";
    if (kStringEqualToString(platform, @"iPad2,7"))   return @"iPad mini";
    if (kStringEqualToString(platform, @"iPad4,4"))   return @"iPad mini 2";
    if (kStringEqualToString(platform, @"iPad4,5"))   return @"iPad mini 2";
    if (kStringEqualToString(platform, @"iPad4,6"))   return @"iPad mini 2";
    if (kStringEqualToString(platform, @"iPad4,7"))   return @"iPad mini 3";
    if (kStringEqualToString(platform, @"iPad4,8"))   return @"iPad mini 3";
    if (kStringEqualToString(platform, @"iPad4,9"))   return @"iPad mini 3";
    if (kStringEqualToString(platform, @"iPad5,1"))   return @"iPad mini 4";
    if (kStringEqualToString(platform, @"iPad5,2"))   return @"iPad mini 4";
    if (kStringEqualToString(platform, @"iPad11,1"))   return @"iPad mini 5";
    if (kStringEqualToString(platform, @"iPad11,2"))   return @"iPad mini 5";

    return @"Unknown iPad";
}

+ (NSString *)_iPodPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"iPod1,1"))      return @"iPod Touch";
    if (kStringEqualToString(platform, @"iPod2,1"))      return @"iPod touch (2nd generation)";
    if (kStringEqualToString(platform, @"iPod3,1"))      return @"iPod touch (3rd generation)";
    if (kStringEqualToString(platform, @"iPod4,1"))      return @"iPod touch (4th generation)";
    if (kStringEqualToString(platform, @"iPod5,1"))      return @"iPod Touch (5th generation)";
    if (kStringEqualToString(platform, @"iPod7,1"))      return @"iPod touch (6th generation)";
    if (kStringEqualToString(platform, @"iPod9,1"))      return @"iPod touch (7th generation)";

    return @"Unknown iPod";
}

+ (NSString *)_AirPodsPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"AirPods1,1"))      return @"AirPods (1st generation)";
    if (kStringEqualToString(platform, @"AirPods2,1"))      return @"AirPods (2nd generation)";
    if (kStringEqualToString(platform, @"AirPods8,1"))      return @"AirPods Pro";

    return @"Unknown AirPods";
}

+ (NSString *)_AppleTVPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"AppleTV2,1"))      return @"Apple TV (2nd generation)";
    if (kStringEqualToString(platform, @"AppleTV3,1"))      return @"Apple TV (3rd generation)";
    if (kStringEqualToString(platform, @"AppleTV5,3"))      return @"Apple TV (4th generation)";
    if (kStringEqualToString(platform, @"AppleTV6,2"))      return @"Apple TV 4K ";

    return @"Unknown Apple TV";
}

+ (NSString *)_AppleWatchPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"Watch1,1"))      return @"Apple Watch (1st generation)";
    if (kStringEqualToString(platform, @"Watch1,2"))      return @"Apple Watch (1st generation)";
    if (kStringEqualToString(platform, @"Watch2,6"))      return @"Apple Watch Series 1";
    if (kStringEqualToString(platform, @"Watch2,7"))      return @"Apple Watch Series 1";
    if (kStringEqualToString(platform, @"Watch2,3"))      return @"Apple Watch Series 2";
    if (kStringEqualToString(platform, @"Watch2,4"))      return @"Apple Watch Series 2";
    if (kStringEqualToString(platform, @"Watch3,1"))      return @"Apple Watch Series 3";
    if (kStringEqualToString(platform, @"Watch3,2"))      return @"Apple Watch Series 3";
    if (kStringEqualToString(platform, @"Watch3,3"))      return @"Apple Watch Series 3";
    if (kStringEqualToString(platform, @"Watch3,4"))      return @"Apple Watch Series 3";
    if (kStringEqualToString(platform, @"Watch4,1"))      return @"Apple Watch Series 4";
    if (kStringEqualToString(platform, @"Watch4,2"))      return @"Apple Watch Series 4";
    if (kStringEqualToString(platform, @"Watch4,3"))      return @"Apple Watch Series 4";
    if (kStringEqualToString(platform, @"Watch4,4"))      return @"Apple Watch Series 4";

    return @"Unknown Apple Watch";
}

+ (NSString *)_HomePodPlatform:(NSString *)platform{
    
    if (kStringEqualToString(platform, @"AudioAccessory1,1"))      return @"HomePod";
    if (kStringEqualToString(platform, @"AudioAccessory1,2"))      return @"HomePod";

    return @"Unknown HomePod";
}


@end
