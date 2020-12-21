//
//  LocationCoordinate2DExchanger.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocationCoordinate2DExchanger : NSObject

/*
 *WGS-84 gps 转 高德 腾讯 goole GCJ－02
 */
+ (CLLocationCoordinate2D) WGSToGCJ:(CLLocationCoordinate2D)coordinate;
/*
 *高德 腾讯 goole GCJ－02 转 WGS-84 gps
 */
+ (CLLocationCoordinate2D) GCJToWGS:(CLLocationCoordinate2D)coordinate;

@end

NS_ASSUME_NONNULL_END
