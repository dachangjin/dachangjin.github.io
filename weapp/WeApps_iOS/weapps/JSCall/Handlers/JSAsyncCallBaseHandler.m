//
//  JSCallBaseHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "JSAsyncCallBaseHandler.h"

@implementation JSAsyncCallBaseHandler


- (NSString *)handleEvent:(JSAsyncEvent *)event
{
    NSString *selectorStr = [NSString stringWithFormat:@"js_%@:",event.funcName];
    SEL sel = NSSelectorFromString(selectorStr);
    if ([self respondsToSelector:sel]) {
        IMP imp = [self methodForSelector:sel];
        NSString *(*func)(id, SEL, JSAsyncEvent *) = (void *)imp;
        return func(self, sel, event);
    } else {
        if (event.fail) {
            event.fail([NSError errorWithDomain:event.funcName code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"客户端不支持"
            }]);
        }
        return @"客户端不支持";
    }
}


- (void)event:(JSAsyncEvent *)event
    successWithDic:(NSDictionary *)dic
{
    if (event.success) {
        event.success(dic);
    }
}

- (void)event:(JSAsyncEvent *)event
    failWithError:(NSError *)error
{
    if (event.fail) {
        event.fail(error);
    }
}


- (BOOL)checkValueClass:(Class)clz
                  ofKey:(NSString *)key
                 inDict:(NSDictionary *)dict
               canBeNil:(BOOL)canBeNil
        withErrorString:(NSString *_Nullable *_Nullable)string
{
    return [self checkValueClass:clz
                           ofKey:key
                          inDict:dict
                        canBeNil:canBeNil
                       isBoolean:NO
                 withErrorString:string];
}

- (BOOL)checkValueClass:(Class)clz
                  ofKey:(NSString *)key
                 inDict:(NSDictionary *)dict
               canBeNil:(BOOL)canBeNil
              isBoolean:(BOOL)isBoolean
        withErrorString:(NSString **)string
{
    id object = dict[key];
    if (canBeNil) {
        if ([self isInvalidObject:object ofClass:clz]) {
            if (string != NULL) {
                *string = [NSString stringWithFormat:@"parameter error: paremeter.%@ should be %@ instead of %@", key, [self jsTypeOfClass:clz isBoolean:isBoolean], [self jsTypeOfObject:object]];
            }
            return NO;
        } else {
            return YES;
        }
    } else {
        if (!object) {
            if (string != NULL) {
                *string = [NSString stringWithFormat:@"parameter error: paremeter.%@ should not be null",key];
            }
            return NO;
        } else if ([self isValidObject:object ofClass:clz]) {
            return YES;
        } else {
            if (string != NULL) {
                *string = [NSString stringWithFormat:@"parameter error: paremeter.%@ should be %@ instead of %@", key, [self jsTypeOfClass:clz isBoolean:isBoolean], [self jsTypeOfObject:object]];
            }
            return NO;
        }
    }
}


- (NSString *)jsTypeOfClass:(Class)clz isBoolean:(BOOL)isBoolean
{
    if (clz == [NSString class]) {
        return @"String";
    } else if (clz == [NSArray class]) {
        return @"Array";
    } else if (clz == [NSDictionary class]) {
        return @"Object";
    } else if (clz == [NSNumber class]) {
        if (isBoolean) {
            return @"Boolean";
        }
        return @"Number";
    }
    return @"";
}

- (NSString *)jsTypeOfObject:(id)objc
{
    if ([objc isKindOfClass:[NSString class]]) {
        return @"String";
    } else if ([objc isKindOfClass:[NSArray class]]) {
        return @"Array";
    } else if ([objc isKindOfClass:[NSDictionary class]]) {
        return @"Object";
    } else if ([objc isKindOfClass:[NSNumber class]]) {
        if ([[objc stringValue] isEqualToString:@"true"] || [[objc stringValue] isEqualToString:@"false"]) {
            return @"Boolean";
        } else {
            return @"Number";
        }
    }
    return @"";
}

- (BOOL)isInvalidObject:(id)object ofClass:(Class)clz
{
    return object && ![object isKindOfClass:clz];
}

- (BOOL)isValidObject:(id)object ofClass:(Class)clz
{
    return object && [object isKindOfClass:clz];
}

- (BOOL)isValidArrayArgs:(id)object withCount:(NSUInteger)count
{
    NSArray *array = object;
    return array && [array isKindOfClass:[NSArray class]] && array.count == count;
}

- (BOOL)isValidParameterType:(Class)clz inArray:(NSArray *)args atIndex:(NSUInteger)index
{
    if (index < 0 || index >= args.count) {
        return NO;
    }
    id objc = args[index];
    return [objc isKindOfClass:clz];
}
@end
