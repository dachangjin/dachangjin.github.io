//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import "WXNetworkConfigItem.h"

NSString *const kADNetworkConfigItemCgiName = @"cgi_name";
NSString *const kADNetworkConfigItemRequestPath = @"request_path";
NSString *const kADNetworkConfigItemDecryptKeyPath = @"decrypt_key_path";
NSString *const kADNetworkConfigItemHttpMethod = @"http_method";
NSString *const kADNetworkConfigItemSysErrKeyPath = @"sys_err_key_path";

NSString *const kEncryptWholePacketParaKey = @"kEncryptWholePacketParaKey";


@interface WXNetworkConfigItem ()

- (id)objectOrNilForKey:(id)aKey fromDictionary:(NSDictionary *)dict;

@end

@implementation WXNetworkConfigItem


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
        self.cgiName = [self objectOrNilForKey:kADNetworkConfigItemCgiName fromDictionary:dict];
        self.requestPath = [self objectOrNilForKey:kADNetworkConfigItemRequestPath fromDictionary:dict];
        self.httpMethod = [self objectOrNilForKey:kADNetworkConfigItemHttpMethod fromDictionary:dict];
    }
    
    return self;
    
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *mutableDict = [NSMutableDictionary dictionary];
    [mutableDict setValue:self.cgiName forKey:kADNetworkConfigItemCgiName];
    [mutableDict setValue:self.requestPath forKey:kADNetworkConfigItemRequestPath];
    [mutableDict setValue:self.httpMethod forKey:kADNetworkConfigItemHttpMethod];
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

    self.cgiName = [aDecoder decodeObjectForKey:kADNetworkConfigItemCgiName];
    self.requestPath = [aDecoder decodeObjectForKey:kADNetworkConfigItemRequestPath];
    self.httpMethod = [aDecoder decodeObjectForKey:kADNetworkConfigItemHttpMethod];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{

    [aCoder encodeObject:_cgiName forKey:kADNetworkConfigItemCgiName];
    [aCoder encodeObject:_requestPath forKey:kADNetworkConfigItemRequestPath];
    [aCoder encodeObject:_httpMethod forKey:kADNetworkConfigItemHttpMethod];
}

- (id)copyWithZone:(NSZone *)zone
{
    WXNetworkConfigItem *copy = [[WXNetworkConfigItem alloc] init];
    
    if (copy) {
        copy.cgiName = [self.cgiName copyWithZone:zone];
        copy.requestPath = [self.requestPath copyWithZone:zone];
        copy.httpMethod = [self.httpMethod copyWithZone:zone];
    }
    
    return copy;
}


@end
