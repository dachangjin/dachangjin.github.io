//
//  NSString+UTF8Fixing.h
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (UTF8Fixing)

- (nullable NSData *)fix_dataUsingEncoding:(NSStringEncoding)encoding;
- (nullable instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

@end

NS_ASSUME_NONNULL_END
