//
//  KeyChainWrap.m
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "KeyChainWrap.h"
#import <Security/Security.h>


@implementation KeyChainWrap

+ (BOOL)setData:(NSData *)data forKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForKey:key];
    if (keychainQuery == nil) {
        return NO;
    }
    SecItemDelete((__bridge_retained CFDictionaryRef)keychainQuery);
    keychainQuery[(__bridge_transfer id)kSecValueData] = data;
    return SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, NULL) == noErr;
}

+ (NSData *)getDataForKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForKey:key];
    [keychainQuery setObject:(__bridge_transfer id)kCFBooleanTrue
                      forKey:(__bridge_transfer id)kSecReturnData];
    [keychainQuery setObject:(__bridge_transfer id)kSecMatchLimitOne
                      forKey:(__bridge_transfer id)kSecMatchLimit];
    CFDataRef keyData = NULL;
    NSData *ret = nil;

    if (SecItemCopyMatching((__bridge_retained CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr) {
        ret = (__bridge_transfer NSData*)keyData;
    }
    return ret;
}

+ (BOOL)deleteDataForKey:(NSString *)key {
    NSMutableDictionary *keychainQuery = [self getKeychainQueryForKey:key];
    return SecItemDelete((__bridge_retained CFDictionaryRef)keychainQuery) == noErr;
}

#pragma mark - Private Methods
+ (NSMutableDictionary *)getKeychainQueryForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    return [@{
              (__bridge_transfer id)kSecClass: (__bridge_transfer id)kSecClassGenericPassword,
              (__bridge_transfer id)kSecAttrService: key
              } mutableCopy];
}

@end
