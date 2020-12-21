//
//  gIdentifierDict
//  weapps
//
//  Created by tommywwang on 2020/8/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "IdGenerator.h"

static NSMutableDictionary <NSString *, NSNumber *>*gIdentifierDict = nil;

@implementation IdGenerator

+ (NSUInteger)generateIdWithClass:(Class)clz
{
    if (clz == NULL) {
        return 0;
    }
    if (!gIdentifierDict) {
        gIdentifierDict = [NSMutableDictionary dictionary];
    }
    NSNumber *number = gIdentifierDict[NSStringFromClass(clz)];
    if (number) {
        number = @([number unsignedIntegerValue] + 1);
    } else {
        number = @(1);
    }
    gIdentifierDict[NSStringFromClass(clz)] = number;
    return [number unsignedIntegerValue];
}

+ (NSUInteger)generateIdWithClassName:(NSString *)clzName
{
    if (clzName == nil) {
        return 0;
    }
    if (!gIdentifierDict) {
        gIdentifierDict = [NSMutableDictionary dictionary];
    }
    NSNumber *number = gIdentifierDict[clzName];
    if (number) {
        number = @([number unsignedIntegerValue] + 1);
    } else {
        number = @(1);
    }
    gIdentifierDict[clzName] = number;
    return [number unsignedIntegerValue];
}


@end
