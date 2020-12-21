//
//  LocationCoordinate2DExchanger.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "LocationCoordinate2DExchanger.h"
#include <math.h>


@implementation LocationCoordinate2DExchanger

const double a = 6378245.0;
const double ee = 0.00669342162296594323;
const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;


+ (BOOL)outOfChina:(CLLocationCoordinate2D)coordinate {
    if (coordinate.longitude < 72.004 || coordinate.longitude > 137.8347) {
        return YES;
    }
    if (coordinate.latitude < 0.8293 || coordinate.latitude > 55.8271) {
        return YES;
    }
    return NO;
}

+ (double)transformLatWithX:(double)x y:(double)y {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * M_PI) + 40.0 * sin(y / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * M_PI) + 320 * sin(y * M_PI / 30.0)) * 2.0 / 3.0;
    return ret;
}

+ (double)transformLonWithX:(double)x y:(double)y {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(fabs(x));
    ret += (20.0 * sin(6.0 * x * M_PI) + 20.0 * sin(2.0 * x * M_PI)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * M_PI) + 40.0 * sin(x / 3.0 * M_PI)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * M_PI) + 300.0 * sin(x / 30.0 * M_PI)) * 2.0 / 3.0;
    return ret;
}

+ (CLLocationCoordinate2D) dealta:(CLLocationCoordinate2D)coordinate
{
    double lat = coordinate.latitude,lon = coordinate.longitude;
    
    double dlat = [self transformLatWithX:lon-105.0 y:lat-35.0];
    double dlon = [self transformLonWithX:lon-105.0 y:lat-35.0];
    double radlat = lat/180.0*M_PI;
    double magic = sin(radlat);
    magic = 1 - ee*magic*magic;
    double sqrmagic = sqrt(magic);
    dlat = (dlat*180.0) / ((a*(1-ee))/ (magic*sqrmagic)*M_PI);
    dlon = (dlon * 180.0) / (a / sqrmagic * cos(radlat) * M_PI);
    return CLLocationCoordinate2DMake(dlat, dlon);
}

+ (CLLocationCoordinate2D)WGSToGCJ:(CLLocationCoordinate2D)coordinate
{
    //是否在中国大陆之外
    if ([[self class] outOfChina:coordinate]) {
        return coordinate;
    }
    if ([self outOfChina:coordinate]) {
        return coordinate;
    }
    
    CLLocationCoordinate2D location = [self dealta:coordinate];
    
    return CLLocationCoordinate2DMake(coordinate.latitude+location.latitude, coordinate.longitude+location.longitude);
}

+ (CLLocationCoordinate2D) GCJToWGS:(CLLocationCoordinate2D)coordinate
{
    if ([self outOfChina:coordinate]) {
        return coordinate;
    }
    
    CLLocationCoordinate2D location = [self dealta:coordinate];
    
    return CLLocationCoordinate2DMake(coordinate.latitude-location.latitude, coordinate.longitude-location.longitude);
}


@end
