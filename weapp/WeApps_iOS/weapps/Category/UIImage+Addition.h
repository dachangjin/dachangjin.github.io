//
//  UIImage+Addition.h
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


typedef enum : NSUInteger {
    WaterMaskLocationTop,
    WaterMaskLocationCenter,
    WaterMaskLocationBottom,
} WaterMaskLocation;

@interface UIImage (Addition)

- (NSData *)thumbImageData;
- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize;
+ (UIImage *)imageNamed:(NSString *)name resizedImageforwidthPercent:(CGFloat)widthPercent andheightPercent:(CGFloat)heightPercent;
- (UIImage *)waterMaskWithString:(NSString *)str andWaterMaskLocation:(WaterMaskLocation)location;
- (UIImage *)imageByLongestSideLength:(CGFloat)length;
- (UIImage *)imageByCroppingToSquareWithSideLength:(CGFloat)length;
- (UIImage *)imageByScaleToTotalpPixes:(CGFloat)pixes;
- (UIImage *) circleImageWithImage:(UIImage *)image;
- (UIImage *)imageByScalingAspectToFitForSize:(CGSize)targetSize;
- (UIImage*)compressWithcompressionQuality:(CGFloat)compressionQuality;

- (UIImage *)imageName:(NSString *)name inBundle:(NSString *)bundleName;

- (UIImage *)fixOrientation;
@end

NS_ASSUME_NONNULL_END
