//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#import <Foundation/Foundation.h>



@interface WXUserInfo : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy) NSString *openid;
@property (nonatomic, copy) NSString *mail;
@property (nonatomic, copy) NSString *nickname;
@property (nonatomic, copy) NSString *unionid;
@property (nonatomic, copy) NSString *headimgurl;
@property (nonatomic, copy) NSString *country;
@property (nonatomic, assign) double sessionExpireTime;
@property (nonatomic, assign) WXSexType sex;

+ (instancetype)modelObjectWithDictionary:(NSDictionary *)dict;
- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

+ (instancetype)currentUser;
+ (instancetype)visitorUser;
- (BOOL)save;
- (BOOL)load;
- (void)clear;

@end
