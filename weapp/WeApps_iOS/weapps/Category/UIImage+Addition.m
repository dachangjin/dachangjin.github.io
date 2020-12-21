//
//  UIImage+Addition.m
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "UIImage+Addition.h"

@implementation UIImage (Addition)

- (NSData *)thumbImageData
{
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGSize imageSie = self.size;
    if (imageSie.height / imageSie.width > size.height / size.width) {
        
        imageSie.width = imageSie.width * (size.height / imageSie.height);
        imageSie.height = size.height;
    }else{
        
        imageSie.height = imageSie.height * (size.width / imageSie.width);
        imageSie.width = size.width;
    }
    UIImage *thumb = [self imageByScalingAndCroppingForSize:imageSie];
    return UIImageJPEGRepresentation(thumb, 0.1);
}

- (UIImage *)imageByScaleToTotalpPixes:(CGFloat)pixes
{
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    if (width * height <= pixes) return self;
    CGFloat scale = width / height;
    CGFloat squarePixes = pixes / (1 + scale);
    height = sqrt(squarePixes);
    width = height * scale;
    return [self imageByScalingAndCroppingForSize:CGSizeMake(width, height)];
}

- (UIImage *)imageByLongestSideLength:(CGFloat)length
{
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    if (width > height && width > length) {
        height = height / width * length ;
        width = length;
    }else if (height > width && height > length){
        width = width / height * length;
        height = length;
    }
    return [self imageByScalingAndCroppingForSize:CGSizeMake(width, height)];
}

- (UIImage *)imageByCroppingToSquareWithSideLength:(CGFloat)length
{
    CGFloat maxSize = MAX(self.size.width, self.size.height);
    if (length > maxSize) {
        CGFloat minSize = MIN(self.size.width, self.size.height);
        return [self imageByScalingAndCroppingForSize:CGSizeMake(minSize, minSize)];
    }else{
        return [self imageByScalingAndCroppingForSize:CGSizeMake(length, length)];
    }
}

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize
{
    UIImage *sourceImage = self;
    
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
    {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            scaleFactor = widthFactor; // scale to fit height
        else
            scaleFactor = heightFactor; // scale to fit width
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
        {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else
            if (widthFactor < heightFactor)
            {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
    }
    
//    UIGraphicsBeginImageContext(targetSize); // this will crop
//
//    CGRect thumbnailRect = CGRectZero;
//    thumbnailRect.origin = thumbnailPoint;
//    thumbnailRect.size.width  = scaledWidth;
//    thumbnailRect.size.height = scaledHeight;
//
//    [sourceImage drawInRect:thumbnailRect];
//
//    newImage = UIGraphicsGetImageFromCurrentImageContext();
//    if(newImage == nil)
//        NSLog(@"could not scale image");
//
//    //pop the context to get back to the default
//    UIGraphicsEndImageContext();
    UIImage *newImage = [self scaledWithSize:targetSize];
    return newImage;
}

+ (UIImage *)imageNamed:(NSString *)name
resizedImageforwidthPercent:(CGFloat)widthPercent
       andheightPercent:(CGFloat)heightPercent
{
    UIImage *image = [UIImage imageNamed:name];
    return [image stretchableImageWithLeftCapWidth:image.size.width * widthPercent
                                      topCapHeight:image.size.height * heightPercent];
}

- (UIImage *)waterMaskWithString:(NSString *)str andWaterMaskLocation:(WaterMaskLocation)location
{
    
    // 1. 建立图像的上下文，需要指定新生成的图像大小
    UIGraphicsBeginImageContext(self.size);
    
    // 2. 绘制内容
    
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    
    // 3. 添加水印文字
    
    CGRect rect;
    switch (location) {
        case WaterMaskLocationBottom:
            rect = CGRectMake(0, self.size.height - 40, self.size.width, 40);
            break;
        case WaterMaskLocationCenter:
            rect = CGRectMake(0, (self.size.height - 40) / 2, self.size.width, 40);
            break;
        case WaterMaskLocationTop:
            rect = CGRectMake(0, 40, self.size.width, 40);
            break;
        default:
            break;
    }
    // 绘制矩形
    [[UIColor colorWithWhite:0.8 alpha:0.5]set];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathEOFill);
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    CGSize strSize = [str sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                              [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0],
                                              NSForegroundColorAttributeName,
                                              shadow,
                                              NSShadowAttributeName,
                                              [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:25.0], NSFontAttributeName, nil]];
    
    CGPoint point = CGPointMake(rect.size.width / 2.0,rect.size.height / 2.0);
    CGRect strRect = CGRectMake(point.x - strSize.width / 2, rect.origin.y, strSize.width, strSize.height);
    
    [str drawInRect:strRect
     withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                     [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0],
                     NSForegroundColorAttributeName,
                     shadow,
                     NSShadowAttributeName,
                     [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:25.0], NSFontAttributeName, nil]];
    
    // 4. 获取到新生成的图像，从当前上下文获取到新绘制的图像
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 5. 关闭图像上下文
    UIGraphicsEndImageContext();
    
    return newImage;
    
}


- (UIImage *) circleImageWithImage:(UIImage *)image
{
//    CGFloat radius=image.size.height>image.size.width?(image.size.width/2):(image.size.height/2);
//    radius -=2.0;
    UIGraphicsBeginImageContext(image.size );
    
    CGContextRef ctr=UIGraphicsGetCurrentContext();
//    double centerx=image.size.width/2;
//    double centery=image.size.height/2;
    
    //   CGContextSetLineWidth(ctr, border);
//    CGContextAddArc(ctr, centerx, centery, radius, 0, M_PI_2*4, YES);
//    CGContextFillPath(ctr);
//
//    CGContextAddArc(ctr, centerx, centery, radius, 0, M_PI_2*4, YES);
//
    CGContextAddEllipseInRect(ctr, CGRectMake(0, 0, image.size.width, image.size.height));

    CGContextClip(ctr);
    
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    [[UIColor whiteColor] setFill];
    UIImage *newImg=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImg;
}

- (UIImage *)imageByScalingAspectToFitForSize:(CGSize)targetSize {
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (width > targetSize.width) {
        CGFloat factor = targetSize.width / width;
        width = targetSize.width;
        height = height * factor;
        //        thumbnailPoint.x = 0;
        //        thumbnailPoint.y = (targetSize.height - height) / 2;
    }
    if (height > targetSize.height) {
        CGFloat factor = targetSize.height / height;
        height = targetSize.height;
        width = width * factor;
        //        thumbnailPoint.y = 0;
        //        thumbnailPoint.x = (targetSize.width - width) / 2;
    }
    UIGraphicsBeginImageContext(CGSizeMake(width, height)); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = width;
    thumbnailRect.size.height = height;
    
    [self drawInRect:thumbnailRect];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    if(newImage == nil)
        NSLog(@"could not scale image");
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}


#pragma mark private

- (UIImage *)scaledWithSize:(CGSize)size
{
    NSData *data = UIImagePNGRepresentation(self);
    CGFloat maxPixelSize = MAX(size.width, size.height);
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    NSDictionary *options = @{(__bridge id)kCGImageSourceCreateThumbnailFromImageAlways:(__bridge id)kCFBooleanTrue,
                              (__bridge id)kCGImageSourceThumbnailMaxPixelSize:[NSNumber numberWithFloat:maxPixelSize]};

    CGImageRef  imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
    UIImage *resultImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CFRelease(sourceRef);

    return resultImage;
}

- (UIImage*)compressWithcompressionQuality:(CGFloat)compressionQuality
{
    NSData* destImageData = UIImageJPEGRepresentation(self, compressionQuality);
    return [UIImage imageWithData:destImageData];
}


- (UIImage *)imageName:(NSString *)name inBundle:(NSString *)bundleName
{
    static NSBundle *resourceBundle = nil;
    if (!resourceBundle) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *resourcePath = [mainBundle pathForResource:bundleName ofType:@"bundle"];
        resourceBundle = [NSBundle bundleWithPath:resourcePath] ?: mainBundle;
    }
    UIImage *image = [UIImage imageNamed:name inBundle:resourceBundle compatibleWithTraitCollection:nil];
    return image;
}


- (UIImage *)fixOrientation {
    
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}
@end

