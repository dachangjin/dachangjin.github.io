//
//  KeyChainWrap.h
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyChainWrap : NSObject

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key;

+ (NSData *)getDataForKey:(NSString *)key;

+ (BOOL)deleteDataForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
