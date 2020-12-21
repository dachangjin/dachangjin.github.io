//
//  NSMutableDictionary+NilCheck.m
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NSMutableDictionary+NilCheck.h"

@implementation NSMutableDictionary (NilCheck)
- (id)WA_objectForKey:(NSString *)key
{
    return [self objectForKey:key];
}

- (void)WA_setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (anObject) {
        [self setObject:anObject forKey:aKey];
    }
}
@end
