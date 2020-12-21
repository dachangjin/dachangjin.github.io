//
//  QRCodeGenerator.h
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface QRCodeGenerator : NSObject

+ (UIImage *)qRImageFromString:(NSString *)string imageSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
