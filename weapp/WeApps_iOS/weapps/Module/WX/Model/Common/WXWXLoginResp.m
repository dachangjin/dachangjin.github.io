//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "WXWXLoginResp.h"
#import "WXBaseResp.h"
#import "NSMutableDictionary+NilCheck.h"


NSString *const kADWXLoginRespBaseResp = @"base_resp";


NSString *const kADWXLoginAccessToken = @"access_token";
NSString *const kADWXLoginRefreshToken = @"refresh_token";
NSString *const kADWXLoginExpiresIn = @"expires_in";
NSString *const kADWXLoginOpenId = @"openid";
NSString *const kADWXLoginScope = @"scope";



@implementation WXWXLoginResp

@synthesize baseResp = _baseResp;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict
{
    return [[self alloc] initWithDictionary:dict];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    
    // This check serves to make sure that a non-NSDictionary object
    // passed into the model class doesn't break the parsing.
    if(self && [dict isKindOfClass:[NSDictionary class]]) {
        self.baseResp = [WXBaseResp modelObjectWithDictionary:[dict objectForKey:kADWXLoginRespBaseResp]];
    
        self.accessToken = [dict objectForKey:kADWXLoginAccessToken];
        self.refreshToken = [dict objectForKey:kADWXLoginRefreshToken];
        self.expiresTime = [[dict objectForKey:kADWXLoginExpiresIn] intValue];
        self.openId = [dict objectForKey:kADWXLoginOpenId];
        self.scope = [dict objectForKey:kADWXLoginScope];
        

    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict WA_setObject:[self.baseResp dictionaryRepresentation] forKey:kADWXLoginRespBaseResp];
    [mutableDict WA_setObject:self.accessToken forKey:kADWXLoginAccessToken];
    [mutableDict WA_setObject:self.refreshToken forKey:kADWXLoginRefreshToken];
    [mutableDict WA_setObject:self.scope forKey:kADWXLoginScope];
    [mutableDict WA_setObject:@(self.expiresTime) forKey:kADWXLoginExpiresIn];
    [mutableDict WA_setObject:self.openId forKey:kADWXLoginOpenId];
    
    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
}



#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.baseResp = [aDecoder decodeObjectForKey:kADWXLoginRespBaseResp];
    self.openId = [aDecoder decodeObjectForKey:kADWXLoginOpenId];
    self.scope = [aDecoder decodeObjectForKey:kADWXLoginScope];
    self.accessToken = [aDecoder decodeObjectForKey:kADWXLoginAccessToken];
    self.refreshToken = [aDecoder decodeObjectForKey:kADWXLoginRefreshToken];
    self.expiresTime = [aDecoder decodeIntForKey:kADWXLoginExpiresIn];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_baseResp forKey:kADWXLoginRespBaseResp];
    [aCoder encodeObject:self.openId forKey:kADWXLoginOpenId];
    [aCoder encodeObject:self.scope forKey:kADWXLoginScope];
    [aCoder encodeObject:self.accessToken forKey:kADWXLoginAccessToken];
    [aCoder encodeObject:self.refreshToken forKey:kADWXLoginRefreshToken];
    [aCoder encodeObject:@(self.expiresTime) forKey:kADWXLoginExpiresIn];
}



- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    WXWXLoginResp *copy = [[WXWXLoginResp alloc] init];
    
    if (copy) {

        copy.baseResp = [self.baseResp copyWithZone:zone];
        copy.accessToken = [self.accessToken copyWithZone:zone];
        copy.expiresTime = self.expiresTime;
        copy.refreshToken = [self.refreshToken copyWithZone:zone];
        copy.openId = [self.openId copyWithZone:zone];
        copy.scope = [self.scope copyWithZone:zone];
    }
    
    return copy;
}

@end
