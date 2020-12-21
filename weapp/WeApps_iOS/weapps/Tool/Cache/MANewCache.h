//
//  WKWebViewHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MACacheProtocol.h"

NS_ASSUME_NONNULL_BEGIN
// 这个类将所有storage存放到一个文件中
@interface MANewCache : NSObject <MACacheProtocol>

- (instancetype)initWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
