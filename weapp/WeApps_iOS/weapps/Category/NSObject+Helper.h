//
//  NSObject+KVO.h
//  SimpleKVO
//
//  Created by wangwei on 2019/5/10.
//  Copyright © 2019 WW. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^KVOBlock)(id oldValue,id newValue);
@interface NSObject (KVO)
- (void)addObservedObject:(NSObject *)obj
               forKeyPath:(NSString *)keyPath
                    block:(KVOBlock)block;
@end

NS_ASSUME_NONNULL_END
