//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MADataCacheResultBlock)(BOOL success, NSError *errpr);
typedef void (^MADataCacheObjectBlock)(NSString *key, id object);
typedef void (^MADataCacheInfoBlock)(NSDictionary *cacheInfo);
typedef NSData *(^MADataCacheEncoder)(id object);
typedef id (^MADataCacheDecoder)(NSData *data);

@protocol MACacheProtocol <NSObject>
#pragma mark -同步接口 -
- (id)objectForKey:(NSString *)key;

- (BOOL)setObject:(id <NSCoding>)object forKey:(NSString *)key error:(NSError *__autoreleasing *)error;
// 从本地缓存中移除指定key
- (void)removeObjectForKey:(NSString *)key;

// 清理本地数据缓存
- (void)removeAllObjects;

#pragma mark - 异步接口 -
- (void)objectForKeyAsync:(NSString *)key completion:(MADataCacheObjectBlock)block;

- (void)setObjectAsync:(id <NSCoding>)object forKey:(NSString *)key completion:(MADataCacheResultBlock)block;

- (void)removeObjectForKeyAsync:(NSString *)key completion:(MADataCacheResultBlock)block;

- (void)removeAllObjectsAsync:(MADataCacheResultBlock)block;

@optional
// 当前缓存中所有的key
- (NSArray <NSString *> *)keys;

- (void)dataCacheInfoAsync:(MADataCacheInfoBlock)block;

//  限制的空间大小，单位 KB
- (long)limitSize;

// 当前占用的空间大小, 单位 KB
- (long)currentSize;

@end
