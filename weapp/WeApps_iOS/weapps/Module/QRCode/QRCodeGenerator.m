//
//  QRCodeGenerator.m
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "QRCodeGenerator.h"

@implementation QRCodeGenerator

+ (UIImage *)qRImageFromString:(NSString *)string imageSize:(CGFloat)size
{
    NSData *inputData = [string dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:inputData forKey:@"inputMessage"];
    
    //设置高容错率
    [filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    
    CIImage *ciImage = filter.outputImage;
    ciImage = [ciImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, 10.0, 10.0)];
    UIImage *image = [UIImage imageWithCIImage:ciImage];
    
    UIGraphicsBeginImageContext(CGSizeMake(size, size));
    [image drawInRect:CGRectMake(0, 0, size, size)];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;;
}

@end
