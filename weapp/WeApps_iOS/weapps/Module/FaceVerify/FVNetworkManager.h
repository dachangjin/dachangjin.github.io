//
//  FVNetworkManager.h
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface FaceIdRequestParams : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *idNO;
@property (nonatomic, copy) NSString *sourcePhotoStr;
@property (nonatomic, copy) NSString *sourcePhotoType;
@property (nonatomic, copy) NSString *sign;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *nonce;
@property (nonatomic, copy) NSString *orderNO;
@property (nonatomic, copy) NSString *faceId;

@end


typedef void(^CompletionBlock)(FaceIdRequestParams * _Nullable result,NSError * _Nullable error);


@interface FVNetworkManager : NSObject

+ (instancetype)sharedManager;

/// 获取人脸识别前参数相关信心
/// @param name 姓名
/// @param idNO 证件号码
/// @param sourcePhotoStr 比对源照片base64，注意：原始图片不能超过 500k，且必须为 JPG 或 PNG 格式。 参数有值：使用合作伙伴提供的比对源照片进行比对，必须注照片是正脸可信照片，照片质量由合作方保证。参数为空 ：根据身份证号 + 姓名使用权威数据源比对
/// @param sourcePhotoType 比对源照片类型，参数值为1 时是：水纹正脸照。参数值为 2 时是：高清正脸照
/// @param block 回调
- (void)faceVerifyParamsWithName:(NSString *)name
                            idNO:(NSString *)idNO
                  sourcePhotoStr:(NSString * _Nullable)sourcePhotoStr
                 sourcePhotoType:(NSString *)sourcePhotoType
                      completion:(CompletionBlock)block;

@end


NS_ASSUME_NONNULL_END
