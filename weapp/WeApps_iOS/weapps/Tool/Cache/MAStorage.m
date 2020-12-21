//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MAStorage.h"
#import "MANewCache.h"

@implementation MAStorage

- (instancetype)initWithFolderPath:(NSString *)folderPath
{
    if (self = [super init]) {
        
        _cache = [[MANewCache alloc] initWithPath:folderPath];
    }
    return self;
}
#pragma mark -同步接口 -
- (id)objectForKey:(NSString *)key
{
    return [_cache objectForKey:key];
}
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key error:(NSError *__autoreleasing *)error
{
    [_cache setObject:object forKey:key error:error];
}
- (void)removeObjectForKey:(NSString *)key
{
    [_cache removeObjectForKey:key];
}
- (void)removeAllObjects
{
    [_cache removeAllObjects];
}
- (NSDictionary *)dataCacheInfo
{
    NSDictionary *result = @{ @"currentSize"  : @([_cache currentSize]),
                              @"limitSize"    : @([_cache limitSize]),
                              @"keys"         : [_cache keys]?:@[]
                              };
    return result;
}
#pragma mark - 异步接口 -
- (void)objectForKeyAsync:(NSString *)key completion:(MADataCacheObjectBlock)block
{
    [_cache objectForKeyAsync:key completion:block];
}
- (void)setObjectAsync:(id <NSCoding>)object forKey:(NSString *)key completion:(MADataCacheResultBlock)block
{
    [_cache setObjectAsync:object forKey:key completion:block];
}
- (void)removeObjectForKeyAsync:(NSString *)key completion:(MADataCacheResultBlock)block
{
    [_cache removeObjectForKeyAsync:key completion:block];
}
- (void)removeAllObjectsAsync:(MADataCacheResultBlock)block
{
    [_cache removeAllObjectsAsync:block];
}
- (void)dataCacheInfoAsync:(MADataCacheInfoBlock)block
{
    [_cache dataCacheInfoAsync:block];
}
@end
