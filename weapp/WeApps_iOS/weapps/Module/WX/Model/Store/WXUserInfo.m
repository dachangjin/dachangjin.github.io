//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "WXUserInfo.h"

static NSString *const kWXUserInfoOpenid = @"openid";
static NSString *const kWXUserInfoMail = @"mail";
static NSString *const kWXUserInfoNickname = @"nickname";
static NSString *const kWXUserInfoUnionid = @"unionid";
static NSString *const kWXUserInfoHeadimgurl = @"headimgurl";
static NSString *const kWXUserInfoSex = @"sex";

static NSString *const kSavedUserInfoKeyName = @"kSavedUserInfoKeyName";

@interface WXUserInfo ()


@end

@implementation WXUserInfo


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
            self.openid = [self objectOrNilForKey:kWXUserInfoOpenid fromDictionary:dict];
            self.mail = [self objectOrNilForKey:kWXUserInfoMail fromDictionary:dict];
            self.nickname = [self objectOrNilForKey:kWXUserInfoNickname fromDictionary:dict];
            self.unionid = [self objectOrNilForKey:kWXUserInfoUnionid fromDictionary:dict];
            self.headimgurl = [self objectOrNilForKey:kWXUserInfoHeadimgurl fromDictionary:dict];
            self.sex = [[self objectOrNilForKey:kWXUserInfoSex fromDictionary:dict] intValue];
    }
    
    return self;
    
}

+ (instancetype)currentUser {
    static dispatch_once_t onceToken;
    static WXUserInfo *currentUser_ = nil;
    dispatch_once(&onceToken, ^{
        currentUser_ = [[WXUserInfo alloc] init];
    });
    return currentUser_;
}


+ (instancetype)visitorUser {
    WXUserInfo *visitorUser = [[WXUserInfo alloc] init];
    visitorUser.nickname = @"访客";
    return visitorUser;
}

- (BOOL)save {
    return NO;
}

- (BOOL)load {
    
//    self.openid = [self objectOrNilForKey:kWXUserInfoOpenid fromDictionary:savedUserInfo];
//    self.mail = [self objectOrNilForKey:kWXUserInfoMail fromDictionary:savedUserInfo];
//    self.nickname = [self objectOrNilForKey:kWXUserInfoNickname fromDictionary:savedUserInfo];
//    self.unionid = [self objectOrNilForKey:kWXUserInfoUnionid fromDictionary:savedUserInfo];
//    self.headimgurl = [self objectOrNilForKey:kWXUserInfoHeadimgurl fromDictionary:savedUserInfo];
//    self.sex = [[self objectOrNilForKey:kWXUserInfoSex fromDictionary:savedUserInfo] intValue];
//    return self.openid.length && self.unionid.length;
    return NO;
}

- (void)clear {

    self.openid = nil;
    self.mail = nil;
    self.unionid = nil;
    self.headimgurl = nil;
    self.sex = WXSexTypeUnknown;
    self.sessionExpireTime = 0;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.openid forKey:kWXUserInfoOpenid];
    [mutableDict setValue:self.mail forKey:kWXUserInfoMail];
    [mutableDict setValue:self.nickname forKey:kWXUserInfoNickname];
    [mutableDict setValue:self.unionid forKey:kWXUserInfoUnionid];
    [mutableDict setValue:self.headimgurl forKey:kWXUserInfoHeadimgurl];
    [mutableDict setValue:@(self.sex) forKey:kWXUserInfoSex];
    
    return [NSDictionary dictionaryWithDictionary:mutableDict];
}

- (NSString *)description 
{
    return [NSString stringWithFormat:@"%@", [self dictionaryRepresentation]];
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

    self.openid = [aDecoder decodeObjectForKey:kWXUserInfoOpenid];
    self.mail = [aDecoder decodeObjectForKey:kWXUserInfoMail];
    self.nickname = [aDecoder decodeObjectForKey:kWXUserInfoNickname];
    self.unionid = [aDecoder decodeObjectForKey:kWXUserInfoUnionid];
    self.headimgurl = [aDecoder decodeObjectForKey:kWXUserInfoHeadimgurl];
    self.sex = [aDecoder decodeIntForKey:kWXUserInfoSex];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_openid forKey:kWXUserInfoOpenid];
    [aCoder encodeObject:_mail forKey:kWXUserInfoMail];
    [aCoder encodeObject:_nickname forKey:kWXUserInfoNickname];
    [aCoder encodeObject:_unionid forKey:kWXUserInfoUnionid];
    [aCoder encodeObject:_headimgurl forKey:kWXUserInfoHeadimgurl];
    [aCoder encodeInt:(int)_sex forKey:kWXUserInfoSex];
}

- (id)copyWithZone:(NSZone *)zone
{
    WXUserInfo *copy = [[WXUserInfo alloc] init];
    
    if (copy) {

        copy.openid = [self.openid copyWithZone:zone];
        copy.mail = [self.mail copyWithZone:zone];
        copy.nickname = [self.nickname copyWithZone:zone];
        copy.unionid = [self.unionid copyWithZone:zone];

        copy.headimgurl = [self.headimgurl copyWithZone:zone];
        copy.sex = self.sex;
    }
    
    return copy;
}


@end
