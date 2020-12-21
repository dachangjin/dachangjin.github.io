//
//  FVNetworkManager.m
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "FVNetworkManager.h"
#import "AFURLSessionManager+JSONRequest.h"
#import "AppConfig.h"
#import "AccessTokenResult.h"
#import "TicketResult.h"
#import "FaceIdResult.h"
#include <mach/mach_time.h>
#import "NSString+Base64.h"
#import "NSMutableDictionary+NilCheck.h"



@implementation FaceIdRequestParams

@end


static NSString *const kAccessTokenURL = @"https://idasc.webank.com/api/oauth2/access_token";
static NSString *const kTicketURL = @"https://idasc.webank.com/api/oauth2/api_ticket";
static NSString *const kFaceIdURL = @"https://idasc.webank.com/api/server/getfaceid";
static NSString *const kVersion = @"1.0.0";
#define K_RANDOM_LENGTH 32
static const NSString *kRandomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

static NSString* createUuid(){
    NSMutableString *randomString = [NSMutableString stringWithCapacity:K_RANDOM_LENGTH];
    for (int i = 0; i < K_RANDOM_LENGTH; i++) {
        [randomString appendFormat: @"%C", [kRandomAlphabet characterAtIndex:arc4random_uniform((u_int32_t)[kRandomAlphabet length])]];
    }
    return randomString;
}

@interface FVNetworkManager ()

@property (nonatomic, strong) AFURLSessionManager *manager;

@end

@implementation FVNetworkManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static FVNetworkManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[FVNetworkManager alloc] init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        instance.manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];
        AFJSONResponseSerializer *serializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        serializer.acceptableContentTypes = [serializer.acceptableContentTypes setByAddingObject:@"text/plain"];
        instance.manager.responseSerializer = serializer;
    });
    return instance;
}

- (void)faceVerifyParamsWithName:(NSString *)name
                            idNO:(NSString *)idNO
                  sourcePhotoStr:(NSString *)sourcePhotoStr
                 sourcePhotoType:(NSString *)sourcePhotoType
                      completion:(CompletionBlock)block
{
    NSParameterAssert(name);
    NSParameterAssert(idNO);
    NSParameterAssert(sourcePhotoType);
    FaceIdRequestParams *params = [[FaceIdRequestParams alloc] init];
    params.name = name;
    params.idNO = idNO;
    params.sourcePhotoStr = sourcePhotoStr;
    params.sourcePhotoType = sourcePhotoType;
//    params.userId = [NSString stringWithFormat:@"userID%llu", mach_absolute_time()];
    params.userId = [[NSUUID UUID] UUIDString];
    params.version = kVersion;
    params.nonce = createUuid();
    params.orderNO = [NSString stringWithFormat:@"orderNO%llu", mach_absolute_time()];

    NSMutableDictionary *paramsDic = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(paramsDic, @"app_id", kCloudFaceId);
    kWA_DictSetObjcForKey(paramsDic, @"secret", kCloudFaceKey);
    kWA_DictSetObjcForKey(paramsDic, @"grant_type", @"client_credential");
    kWA_DictSetObjcForKey(paramsDic, @"version", params.version);

    [[_manager JSONTaskForURL:kAccessTokenURL
                       method:@"GET"
                       params:paramsDic
               withCompletion:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
        if (error) {
            if (block) {
                block(nil,error);
            }
        } else {
            if (dict) {
                if ([dict[@"success"] boolValue]) {
                    AccessTokenResult *result = [AccessTokenResult objectWithDic:dict];
                    [self _getTicketWithAccessToken:result
                                       faceIdParams:params
                                         completion:block];
                } else {
                    if (block) {
                        block(nil,[NSError errorWithDomain:kAccessTokenURL code:-1 userInfo:dict]);
                    }
                }
            }
        }
    }] resume];
}


- (void)_getTicketWithAccessToken:(AccessTokenResult *)token faceIdParams:(FaceIdRequestParams *)faceIdparams completion:(CompletionBlock)block
{
    NSMutableDictionary *paramsDic = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(paramsDic, @"app_id", kCloudFaceId);
    kWA_DictSetObjcForKey(paramsDic, @"access_token", token.access_token);
    kWA_DictSetObjcForKey(paramsDic, @"type", @"NONCE");
    kWA_DictSetObjcForKey(paramsDic, @"version", faceIdparams.version);
    kWA_DictSetObjcForKey(paramsDic, @"user_id", faceIdparams.userId);
    [[_manager JSONTaskForURL:kTicketURL
                       method:@"GET"
                       params:paramsDic
               withCompletion:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
        if (error) {
            if (block) {
                block(nil,error);
            }
        } else {
            if (dict) {
                if ([dict[@"success"] boolValue]) {
                    TicketResult *result = [TicketResult objectWithDic:dict];
                    [self _getFaceIdWithTicket:result faceIdParams:faceIdparams completion:block];
                } else {
                    if (block) {
                        block(nil,[NSError errorWithDomain:kAccessTokenURL code:-1 userInfo:dict]);
                    }
                }
                
            }
        }
    }] resume];
}


- (void)_getFaceIdWithTicket:(TicketResult *)ticket faceIdParams:(FaceIdRequestParams *)faceIdparams completion:(CompletionBlock)block
{
    NSMutableArray *values = [NSMutableArray array];
    kWA_ArrayAddObject(values, kCloudFaceId);
    kWA_ArrayAddObject(values, faceIdparams.userId);
    kWA_ArrayAddObject(values, faceIdparams.nonce);
    kWA_ArrayAddObject(values, faceIdparams.version);
    kWA_ArrayAddObject(values, ticket.ticket);
    
    [values sortUsingComparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
        return [obj1 compare:obj2];
    }];
    faceIdparams.sign = [[values componentsJoinedByString:@""] SHA1String];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(params, @"webankAppId", kCloudFaceId);
    kWA_DictSetObjcForKey(params, @"orderNo", faceIdparams.orderNO);
    kWA_DictSetObjcForKey(params, @"name", faceIdparams.name);
    kWA_DictSetObjcForKey(params, @"idNo", faceIdparams.idNO);
    kWA_DictSetObjcForKey(params, @"userId", faceIdparams.userId);
    kWA_DictSetObjcForKey(params, @"sourcePhotoStr", faceIdparams.sourcePhotoStr);
    kWA_DictSetObjcForKey(params, @"sourcePhotoType", faceIdparams.sourcePhotoType);
    kWA_DictSetObjcForKey(params, @"version", faceIdparams.version);
    kWA_DictSetObjcForKey(params, @"sign", faceIdparams.sign);

    [[_manager JSONTaskForURL:kFaceIdURL
                       method:@"POST"
                       params:params
               withCompletion:^(NSDictionary * _Nullable dict, NSError * _Nullable error) {
        if (dict && !error) {
            if (kWA_DictContainKey(dict, @"code") && [dict[@"code"] intValue] == 0) {
                faceIdparams.faceId = dict[@"result"][@"faceId"];
                if (block) {
                    block(faceIdparams,nil);
                }
            } else {
                if (block) {
                    NSString *msg = dict[@"msg"] ? dict[@"msg"] : @"获取faceId失败";
                    block(nil,[NSError errorWithDomain:kFaceIdURL code:-1 userInfo:@{NSLocalizedDescriptionKey: msg}]);
                }
            }
        } else {
            if (block) {
                block(nil,error);
            }
        }
    }] resume];
}
@end
