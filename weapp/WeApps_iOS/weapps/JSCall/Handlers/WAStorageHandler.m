//
//  WAStorageHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAStorageHandler.h"
#import "MAStorage.h"
#import "JSONHelper.h"
#import "Weapps.h"

kSELString(setStorage)
kSELString(setStorageSync)
kSELString(removeStorage)
kSELString(getStorage)
kSELString(getStorageSync)
kSELString(clearStorage)
kSELString(getStorageInfo)


@implementation WAStorageHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            setStorage,
            setStorageSync,
            removeStorage,
            getStorage,
            getStorageSync,
            clearStorage,
            getStorageInfo
        ];
    }
    return methods;
}

JS_API(setStorage){
    
    kBeginCheck
    kCheck([NSString class], @"key", NO)
    kEndCheck([NSObject class], @"data", NO)
    
    NSString *key = event.args[@"key"];
    id data = event.args[@"data"];
    
    MAStorage *storage = [Weapps sharedApps].storage;
    [storage setObjectAsync:data forKey:key completion:^(BOOL success, NSError *error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithError(setStorage, -1, error.userInfo[NSLocalizedDescriptionKey] ?: @"fail to store");
        }
    }];
    return @"";
}


JS_API(setStorageSync){
    
    kCheckArrayWithCount(2)
    kCheckParamTypeAtIndex([NSString class], 0)
    
    NSString *key = event.args[0];
    id objc = event.args[1];
    
    MAStorage *storage = [Weapps sharedApps].storage;
    NSError *error;
    [storage setObject:objc forKey:key error:&error];
    return @"";
}


JS_API(removeStorage){
    
    kBeginCheck
    kEndCheck([NSString class], @"key", NO)
    
    NSString *key = event.args[@"key"];
    
    MAStorage *storage = [Weapps sharedApps].storage;
    [storage removeObjectForKeyAsync:key completion:^(BOOL success, NSError *error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            NSString *failReason = [NSString stringWithFormat:@"removeStorage fail. key:%@(%@)", key, NSStringFromClass(key.class)];
            kFailWithError(removeStorage, -1, failReason);
        }
    }];
    return @"";
}

JS_API(clearStorage){
    MAStorage *storage = [Weapps sharedApps].storage;
    [storage removeAllObjectsAsync:^(BOOL success, NSError *error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithError(clearStorage, -1, @"clear fail");
        }
    }];
    return @"";
}

JS_API(getStorage){
    kBeginCheck
    kEndCheck([NSString class], @"key", NO)
    
    NSString *key = event.args[@"key"];
    MAStorage *storage = [Weapps sharedApps].storage;
    [storage objectForKeyAsync:key completion:^(NSString *key, id object) {
        if (object) {
           kSuccessWithDic(@{
               @"data": object
                           })
        } else {
           kSuccessWithDic(@{
               @"data": @"null"
                           })
        }
    }];
    return @"";
}

JS_API(getStorageSync){
    
    kCheckArrayWithCount(1)
    kCheckParamTypeAtIndex([NSString class], 0)
    
    NSString *key = event.args[@"key"];
    
    MAStorage *storage = [Weapps sharedApps].storage;
    id object = [storage objectForKey:key];
    if (!object) {
        return @"null";
    }
    return [JSONHelper exchengeDictionaryToString:object];
}


JS_API(getStorageInfo){
    MAStorage *storage = [Weapps sharedApps].storage;
    [storage dataCacheInfoAsync:^(NSDictionary *cacheInfo) {
        if (cacheInfo) {
            kSuccessWithDic(cacheInfo)
        } else {
            kFailWithError(getStorageInfo, -1, @"getStorageInfo fail")
        }
    }];
    return @"";
}


@end
