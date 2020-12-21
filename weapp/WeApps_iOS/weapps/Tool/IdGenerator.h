//
//  IdGenerator.h
//  weapps
//
//  Created by tommywwang on 2020/8/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IdGenerator : NSObject

+ (NSUInteger)generateIdWithClass:(Class)clz;

+ (NSUInteger)generateIdWithClassName:(NSString *)clzName;
@end

NS_ASSUME_NONNULL_END
