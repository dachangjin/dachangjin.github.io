//
//  JSEvent.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "JSEvent.h"



NS_ASSUME_NONNULL_BEGIN

typedef void(^SuccessBlock)(NSDictionary *_Nullable result);
typedef void(^FailBlock)(NSError *_Nullable error);
typedef void(^StartBlock)(void);
typedef void(^ProgressBlock)(int progress);


@interface JSAsyncEvent : JSEvent
    
/// 成功回调
@property (nonatomic, copy, nullable) SuccessBlock success;

/// 失败回调
@property (nonatomic, copy, nullable) FailBlock fail;

/// 开始回调
@property (nonatomic, copy, nullable) StartBlock start;

/// 进度回调
@property (nonatomic, copy, nullable) ProgressBlock progress;

/// callback name
@property (nonatomic, copy) NSString *callbacak;

@end

NS_ASSUME_NONNULL_END
