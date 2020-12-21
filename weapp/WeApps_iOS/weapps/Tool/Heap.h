//
//  Heap.h
//  weapps
//
//  Created by tommywwang on 2020/8/20.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef int(^Comparator)(id value1,id value2);

@interface Heap : NSObject

- (id)initWithComparator:(Comparator)comparator;
- (id)initWithArray:(NSArray *)array comparator:(Comparator)comparator;
- (void)add:(id)objc;
- (id)remove;
- (id)peek;
- (id)replace:(id)objc;
- (NSUInteger)size;
- (BOOL)isEmpty;
- (void)clear;
@end


NS_ASSUME_NONNULL_END
