//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MANewCache.h"
#import <MMKV/MMKV.h>

static NSString *const kStorageSize = @"storageSize";

typedef NS_ENUM(UInt8, WACodecObjectType) {
    WACodecObjectTypeUnknown = 0,
    WACodecObjectTypeBoolean,
    WACodecObjectTypeNumber,
    WACodecObjectTypeString,
    WACodecObjectTypeArray,
    WACodecObjectTypeObject,
};

@interface MANewCache ()

@property (nonatomic, copy) MADataCacheEncoder encoder;
@property (nonatomic, copy) MADataCacheDecoder decoder;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation MANewCache

- (instancetype)initWithPath:(NSString *)path
{
    if (self = [super init]) {
        [MMKV initializeMMKV:nil];

        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _encoder = getEncoder();
        _decoder = getDecoder();
    }
    return self;
}


#pragma mark - 同步接口 -
- (id)objectForKey:(NSString *)key
{
    MMKV *kv = [MMKV defaultMMKV];
    if (![kv containsKey:key]) {
        return @"null";
    }
    NSData *data = [kv getDataForKey:key];
    return self.decoder(data);
}
- (BOOL)setObject:(id <NSCoding>)object forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    NSData *data = self.encoder(object);
    if (!data) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"data encode fail"
            }];
        }
        return NO;
    }
    
    MMKV *kv = [MMKV defaultMMKV];
    double size = [kv getDoubleForKey:kStorageSize];
    
    if ([self limitSize] * 1024 < size + data.length - 1) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"beyond storage size limit:%f",size]
            }];
        }
        return NO;
    }
    
    NSData *oringinalData = [kv getDataForKey:key];
    if (oringinalData) {
        [kv setDouble:size + data.length - oringinalData.length forKey:kStorageSize];
    } else {
        [kv setDouble:size + data.length -1 forKey:kStorageSize];
    }
    return [[MMKV defaultMMKV] setData:data forKey:key];
}

- (void)removeObjectForKey:(NSString *)key
{
    MMKV *kv = [MMKV defaultMMKV];
    double size = [kv getDoubleForKey:kStorageSize];
    NSData *oringinalData = [kv getDataForKey:key];
    if (oringinalData) {
        size -= oringinalData.length - 1;
        [kv setDouble:size forKey:kStorageSize];
    }
    [kv removeValueForKey:key];
}

- (void)removeAllObjects
{
    [[MMKV defaultMMKV] clearAll];
    [[MMKV defaultMMKV] clearMemoryCache];
}
#pragma mark - 异步接口 -
- (void)objectForKeyAsync:(NSString *)key completion:(MADataCacheObjectBlock)block
{
    if (block == nil) {
        return;
    }
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        id object = [self objectForKey:key];
        block(key, object);
    }];
    
    [_operationQueue addOperation:blockOperation];
}
- (void)setObjectAsync:(id <NSCoding>)object forKey:(NSString *)key completion:(MADataCacheResultBlock)block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSError *error;
        BOOL success = [self setObject:object forKey:key error:&error];
        if (block) {
            block(success,error);
        }
    }];
    
    [_operationQueue addOperation:blockOperation];
}
- (void)removeObjectForKeyAsync:(NSString *)key completion:(MADataCacheResultBlock)block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self removeObjectForKey:key];
        if (block) {
            block(YES,nil);
        }
    }];
    
    [_operationQueue addOperation:blockOperation];
}
- (void)removeAllObjectsAsync:(MADataCacheResultBlock)block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        [self removeAllObjects];
        if (block) {
            block(YES,nil);
        }
    }];
    
    [_operationQueue addOperation:blockOperation];
}
// 当前缓存中所有的key
- (NSArray <NSString *> *)keys
{
    return [[MMKV defaultMMKV] allKeys];
}

- (void)dataCacheInfoAsync:(MADataCacheInfoBlock)block
{
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        if (block) {
            NSDictionary *cacheInfo = @{ @"currentSize": @([self currentSize]),
                                         @"limitSize": @([self limitSize]),
                                         @"keys": [self keys]?:@[]
                                         };
            
            block(cacheInfo);
        }
    }];
    
    [_operationQueue addOperation:blockOperation];
}

//  限制的空间大小(10M)，单位 kB
- (long)limitSize
{
    return 10 * 1024;
}

// 当前占用的空间大小, 单位 kB
- (long)currentSize
{
    MMKV *kv = [MMKV defaultMMKV];
    double size = [kv getDoubleForKey:kStorageSize];
    return ceil(size / 1024);
}

#pragma mark codec

MADataCacheEncoder getEncoder()
{
    return ^NSData *(id object){
        @try {
            WACodecObjectType objcType = codecObjectTypeTypeOfObject(object);
            if (objcType == WACodecObjectTypeUnknown) {
                return nil;
            } else {
                NSMutableData *data = [[NSMutableData alloc] init];
                [data appendBytes:&objcType length:1];
                if (objcType == WACodecObjectTypeBoolean) {
                    BOOL value = [object boolValue];
                    [data appendBytes:&value length:sizeof(value)];
                } else if (objcType == WACodecObjectTypeNumber) {
                    double value = [object doubleValue];
                    [data appendBytes:&value length:sizeof(value)];
                } else if (objcType == WACodecObjectTypeObject || objcType == WACodecObjectTypeArray) {
                    NSError *error = nil;
                    NSData *objcData = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingFragmentsAllowed error:&error];
                    if (error) {
                        return nil;
                    } else {
                        [data appendData:objcData];
                    }
                } else if (objcType == WACodecObjectTypeString) {
                    NSData *objcData = [object dataUsingEncoding:NSUTF8StringEncoding];
                    [data appendData:objcData];
                }
                return data;
            }
        } @catch (NSException *exception) {
            //可能要做日志
            return nil;
        }
    };
}

MADataCacheDecoder getDecoder()
{
    //data 的前一个字节为类型，后面为数据
    return ^id(NSData *data){
        @try {
            //data 长度不可能小于2，类型占一个字节，内容大于等于一个字节
            if (data.length <= 1) {
                return nil;
            }
            //验证类型
            WACodecObjectType objcType;
            Byte* buf = (Byte *)data.bytes;
            memcpy(&objcType, buf, 1);
            
            if (objcType == WACodecObjectTypeUnknown) {
                return nil;
            } else if (objcType == WACodecObjectTypeBoolean) {
                BOOL value;
                memcpy(&value, buf + 1, sizeof(value));
                return @(value);
            } else if (objcType == WACodecObjectTypeNumber) {
                //number类型统一用double，避免js中number类型精度损失
                double value;
                memcpy(&value, buf + 1, sizeof(value));
                return @(value);
            } else if (objcType == WACodecObjectTypeObject || objcType == WACodecObjectTypeArray) {
                //字典或数组类型
                NSData *jsonData = [NSData dataWithBytes:buf + 1 length:data.length - 1];
                NSError *error = nil;
                id objc = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
                if (error) {
                    return nil;
                } else {
                    return objc;
                }
            }else if (objcType == WACodecObjectTypeString) {
                return [[NSString alloc] initWithData:[NSData dataWithBytes:buf + 1 length:data.length - 1] encoding:NSUTF8StringEncoding];
            } else {
                return nil;
            }
        } @catch (NSException *exception) {
            return nil;
        }
    };
}

WACodecObjectType codecObjectTypeTypeOfObject(id objc)
{
    if ([objc isKindOfClass:[NSString class]]) {
        return WACodecObjectTypeString;
    } else if ([objc isKindOfClass:[NSArray class]]) {
        return WACodecObjectTypeArray;
    } else if ([objc isKindOfClass:[NSDictionary class]]) {
        return WACodecObjectTypeObject;
    } else if ([objc isKindOfClass:[NSNumber class]]) {
        if ([[objc stringValue] isEqualToString:@"true"] || [[objc stringValue] isEqualToString:@"false"]) {
            return WACodecObjectTypeBoolean;
        } else {
            return WACodecObjectTypeNumber;
        }
    }
    return WACodecObjectTypeUnknown;
}

@end
 
