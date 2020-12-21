//
//  FaceIdResult.h
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FaceIdResult : NSObject

@property (nonatomic, copy) NSString *bizSeqNo;
@property (nonatomic, copy) NSString *orderNo;
@property (nonatomic, copy) NSString *faceId;

+ (id)objectWithDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
