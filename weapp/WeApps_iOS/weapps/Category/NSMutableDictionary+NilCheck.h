//
//  NSMutableDictionary+NilCheck.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary (NilCheck)
- (nullable id)WA_objectForKey:(nonnull id<NSCopying>)key;
- (void)WA_setObject:(nullable id)anObject forKey:(nonnull id<NSCopying>)aKey;
@end

NS_ASSUME_NONNULL_END
