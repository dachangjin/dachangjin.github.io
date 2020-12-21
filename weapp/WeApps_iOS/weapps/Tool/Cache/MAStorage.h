//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MACacheProtocol.h"
@interface MAStorage : NSObject
@property(nonatomic, strong) id <MACacheProtocol> cache;

- (instancetype)initWithFolderPath:(NSString *)folderPath;


#pragma mark -同步接口 -
- (id)objectForKey:(NSString *)key;

- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key error:(NSError *__autoreleasing *)error; 
// 从本地缓存中移除指定 key
- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;
// allKey: "currentSize"; "limitSize"; "keys"
- (NSDictionary *)dataCacheInfo;
#pragma mark - 异步接口 -
- (void)objectForKeyAsync:(NSString *)key completion:(MADataCacheObjectBlock)block;
- (void)setObjectAsync:(id <NSCoding>)object forKey:(NSString *)key completion:(MADataCacheResultBlock)block;
- (void)removeObjectForKeyAsync:(NSString *)key completion:(MADataCacheResultBlock)block;
- (void)removeAllObjectsAsync:(MADataCacheResultBlock)block;
- (void)dataCacheInfoAsync:(MADataCacheInfoBlock)block;
@end
