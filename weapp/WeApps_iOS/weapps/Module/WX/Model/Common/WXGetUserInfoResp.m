//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "WXGetUserInfoResp.h"
#import "WXBaseResp.h"


NSString *const kADGetUserInfoRespOpenid = @"openid";
NSString *const kADGetUserInfoRespNickname = @"nickname";
NSString *const kADGetUserInfoRespBaseResp = @"base_resp";
NSString *const kADGetUserInfoRespHeadimgurl = @"headimgurl";
NSString *const kADGetUserInfoRespUnionid = @"unionid";
NSString *const kADGetUserInfoRespSex = @"sex";
NSString *const kADGetUserInfoRespCity = @"city";
NSString *const kADGetUserInfoRespProvince = @"province";
NSString *const kADGetUserInfoRespCountry = @"country";

@interface WXGetUserInfoResp ()


@end

@implementation WXGetUserInfoResp

@synthesize mail = _mail;
@synthesize openid = _openid;
@synthesize nickname = _nickname;
@synthesize baseResp = _baseResp;
@synthesize headimgurl = _headimgurl;
@synthesize unionid = _unionid;
@synthesize sex = _sex;
@synthesize city = _city;
@synthesize province = _province;
@synthesize country = _country;

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
        self.openid = [self objectOrNilForKey:kADGetUserInfoRespOpenid fromDictionary:dict];
        self.nickname = [self objectOrNilForKey:kADGetUserInfoRespNickname fromDictionary:dict];
        self.baseResp = [WXBaseResp modelObjectWithDictionary:[dict objectForKey:kADGetUserInfoRespBaseResp]];
        self.headimgurl = [self objectOrNilForKey:kADGetUserInfoRespHeadimgurl fromDictionary:dict];
        self.unionid = [self objectOrNilForKey:kADGetUserInfoRespUnionid fromDictionary:dict];
        self.sex = [[self objectOrNilForKey:kADGetUserInfoRespSex fromDictionary:dict] intValue];
        self.city = [self objectOrNilForKey:kADGetUserInfoRespCity
                             fromDictionary:dict];
        self.province = [self objectOrNilForKey:kADGetUserInfoRespProvince
                                 fromDictionary:dict];
        self.country = [self objectOrNilForKey:kADGetUserInfoRespCountry
                                fromDictionary:dict];
        self.city = [self objectOrNilForKey:kADGetUserInfoRespCity fromDictionary:dict];
        self.originalData = dict;
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
//    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
//    [mutableDict setObject:self.openid forKey:kADGetUserInfoRespOpenid];
//    [mutableDict setObject:self.nickname forKey:kADGetUserInfoRespNickname];
//    [mutableDict setObject:[self.baseResp dictionaryRepresentation] forKey:kADGetUserInfoRespBaseResp];
//    [mutableDict setObject:self.headimgurl forKey:kADGetUserInfoRespHeadimgurl];
//    [mutableDict setObject:self.unionid forKey:kADGetUserInfoRespUnionid];
//    [mutableDict setObject:[NSNumber numberWithDouble:self.sex] forKey:kADGetUserInfoRespSex];
//    [mutableDict setObject:self.province forKey:kADGetUserInfoRespProvince];
//    [mutableDict setObject:self.country forKey:kADGetUserInfoRespCountry];
//    [mutableDict setObject:self.city forKey:kADGetUserInfoRespCity];
//    return [NSDictionary dictionaryWithDictionary:mutableDict];
    return self.originalData;
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self originalData]];
}

#pragma mark - Helper Method
- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict
{
    id object = [dict objectForKey:aKey];
    return [object isEqual:[NSNull null]] ? nil : object;
}


#pragma mark - NSCoding Methods

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

    self.openid = [aDecoder decodeObjectForKey:kADGetUserInfoRespOpenid];
    self.nickname = [aDecoder decodeObjectForKey:kADGetUserInfoRespNickname];
    self.baseResp = [aDecoder decodeObjectForKey:kADGetUserInfoRespBaseResp];
    self.headimgurl = [aDecoder decodeObjectForKey:kADGetUserInfoRespHeadimgurl];
    self.unionid = [aDecoder decodeObjectForKey:kADGetUserInfoRespUnionid];
    self.sex = [aDecoder decodeDoubleForKey:kADGetUserInfoRespSex];
    self.country = [aDecoder decodeObjectForKey:kADGetUserInfoRespCountry];
    self.province = [aDecoder decodeObjectForKey:kADGetUserInfoRespProvince];
    self.city = [aDecoder decodeObjectForKey:kADGetUserInfoRespCity];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:self.country forKey:kADGetUserInfoRespCountry];
    [aCoder encodeObject:self.province forKey:kADGetUserInfoRespProvince];
    [aCoder encodeObject:self.city forKey:kADGetUserInfoRespCity];
    [aCoder encodeObject:_openid forKey:kADGetUserInfoRespOpenid];
    [aCoder encodeObject:_nickname forKey:kADGetUserInfoRespNickname];
    [aCoder encodeObject:_baseResp forKey:kADGetUserInfoRespBaseResp];
    [aCoder encodeObject:_headimgurl forKey:kADGetUserInfoRespHeadimgurl];
    [aCoder encodeObject:_unionid forKey:kADGetUserInfoRespUnionid];
    [aCoder encodeDouble:_sex forKey:kADGetUserInfoRespSex];
}

- (id)copyWithZone:(NSZone *)zone
{
    WXGetUserInfoResp *copy = [[WXGetUserInfoResp alloc] init];
    
    if (copy) {

        copy.mail = [self.mail copyWithZone:zone];
        copy.openid = [self.openid copyWithZone:zone];
        copy.nickname = [self.nickname copyWithZone:zone];
        copy.baseResp = [self.baseResp copyWithZone:zone];
        copy.headimgurl = [self.headimgurl copyWithZone:zone];
        copy.unionid = [self.unionid copyWithZone:zone];
        copy.sex = self.sex;
        copy.city = self.city;
        copy.country = self.country;
        copy.province = self.province;

    }
    
    return copy;
}


@end
