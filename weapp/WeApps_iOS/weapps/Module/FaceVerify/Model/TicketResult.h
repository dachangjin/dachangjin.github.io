//
//  TicketResult.h
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TicketResult : NSObject

@property (nonatomic, copy) NSString *ticket;
@property (nonatomic, copy) NSString *expire_time;
@property (nonatomic, assign) int expire_in;

+ (id)objectWithDic:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
