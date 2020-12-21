//
//  JSONHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONHelper : NSObject

+ (NSString *)exchengeDictionaryToString:(id)dic;

+ (id)exchangeStringToDictionary:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
