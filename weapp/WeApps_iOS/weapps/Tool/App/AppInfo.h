//
//  AppInfo.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppInfo : NSObject

+ (NSString *)appName;

+ (NSString *)appId;

+ (NSString *)appVersion;

+ (NSString *)appBuildVersion;

@end

NS_ASSUME_NONNULL_END
