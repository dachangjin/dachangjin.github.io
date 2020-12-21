//
//  WAContainerView.m
//  weapps
//
//  Created by tommywwang on 2020/10/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAContainerView.h"
#import <objc/runtime.h>

@interface WAContainerView ()

@property (nonatomic, strong) NSMutableArray *viewWillDeallocBlocks;

@end

@implementation WAContainerView

+ (void)load
{
    class_addProtocol([self class], NSProtocolFromString(@"WKNativelyInteractible"));
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.viewWillDeallocBlocks = [NSMutableArray array];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    //resignRect对应H5中video组件子节点的位置范围
    if (CGRectContainsPoint(self.resignRect, point)) {
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

- (void)addViewWillDeallocBlock:(WAContainerViewBlock)viewWillDeallocBlock
{
    @synchronized (self.viewWillDeallocBlocks) {
        [self.viewWillDeallocBlocks addObject:viewWillDeallocBlock];
    }
}

- (void)dealloc
{
    @synchronized (self.viewWillDeallocBlocks) {
        for (NSInteger i = 0; i < self.viewWillDeallocBlocks.count; i++) {
            WAContainerViewBlock block = self.viewWillDeallocBlocks[i];
            block(self);
        }
    }
    WALOG(@"WAContainerView die ++++++++++++");
}

@end
