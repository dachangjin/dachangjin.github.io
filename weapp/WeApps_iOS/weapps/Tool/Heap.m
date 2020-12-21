//
//  Heap.m
//  weapps
//
//  Created by tommywwang on 2020/8/20.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "Heap.h"

@interface Heap ()
@property(nonatomic,strong)NSMutableArray *array;
@property(nonatomic,copy)Comparator comparator;
@end

@implementation Heap

- (id)initWithComparator:(Comparator)comparator
{
    NSAssert(comparator, @"comparator should not be nil");
    if (self = [super init]) {
        _comparator = comparator;
        _array = [NSMutableArray array];
    }
    return self;
}

- (id)initWithArray:(NSArray *)array comparator:(Comparator)comparator
{
    if (self = [self initWithComparator:comparator]) {
        [_array addObjectsFromArray:array];
        [self heapify];
    }
    return self;
}


- (void)heapify
{
    for (NSInteger i = _array.count >> 1; i >= 0; i --) {
        [self siftDown:i];
    }
}

- (void)add:(id)objc
{
    [self checkUnNil:objc];
    [_array addObject:objc];
    [self siftUp:_array.count - 1];
}

- (id)remove
{
    if (!_array.count) {
        return nil;
    }
    id objc = [_array firstObject];
    id lastObjc = [_array lastObject];
    [_array replaceObjectAtIndex:0 withObject:lastObjc];
    [_array removeLastObject];
    if (_array.count) {
        [self siftDown:0];
    }
    return objc;
}

- (id)replace:(id)objc
{
    [self checkUnNil:objc];
    if (!_array.count) {
        [_array addObject:objc];
        return nil;
    }
    id object = [_array firstObject];
    [_array replaceObjectAtIndex:0 withObject:objc];
    [self siftDown:0];
    return object;
}

- (id)peek
{
    if (_array.count) {
        return [_array firstObject];
    }
    return nil;
}

- (NSUInteger)size
{
    return _array.count;
}

- (void)clear
{
    [_array removeAllObjects];
}

- (BOOL)isEmpty
{
    return _array.count == 0;
}

- (void)siftUp:(NSUInteger)index
{
    id objc = _array[index];
    while (index > 0) {
        NSUInteger nextIndex = (index - 1) >> 1;
        id nextObjc = _array[nextIndex];
        if(self.comparator(objc,nextObjc) <= 0) break;
        [_array replaceObjectAtIndex:index withObject:nextObjc];
        index = nextIndex;
    }
    [_array replaceObjectAtIndex:index withObject:objc];
}

- (void)siftDown:(NSUInteger)index
{
    NSUInteger size = _array.count;
    id objc = _array[index];
    while (index < size / 2) {
        NSUInteger nextIndex = (index << 1) + 1;
        NSUInteger rightIndex = (index << 1) + 2;
        id nextObjc = _array[nextIndex];
        if (rightIndex < size){
            id right = _array[rightIndex];
            nextIndex = self.comparator(nextObjc, right) >= 0 ? nextIndex : rightIndex;
            nextObjc = _array[nextIndex];
        }
        if (self.comparator(objc,nextObjc) >= 0) break;
        [_array replaceObjectAtIndex:index withObject:nextObjc];
        index = nextIndex;
    }
    [_array replaceObjectAtIndex:index withObject:objc];
}

- (void)checkUnNil:(id)objc
{
    NSAssert(objc, @"objc shoul not be nil");
}

@end
