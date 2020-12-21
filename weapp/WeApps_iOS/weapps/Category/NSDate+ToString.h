//
//  NSDate+ToString.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (ToString)

- (NSString *)stringByFormat:(NSString *)format;

@end

NS_ASSUME_NONNULL_END
