//
//  NSObject+KVO.m
//  SimpleKVO
//
//  Created by wangwei on 2019/5/10.
//  Copyright © 2019 WW. All rights reserved.
//

#import "NSObject+Helper.h"
#import <objc/runtime.h>


typedef void(^DeallocBlock)(void);
@interface ObjectPro : NSObject
@property(nonatomic,strong)NSMutableArray *blockArray;
@end

@implementation ObjectPro

- (void)dealloc
{
    for (DeallocBlock block in self.blockArray) {
        block();
    }
}
@end

@interface NSObject (KVOObj)
@property(nonatomic,strong)NSMutableDictionary<NSString *,NSMutableDictionary<NSString *,KVOBlock> *> *objDict;
@property(nonatomic,strong)ObjectPro *property;
@end

@implementation NSObject (KVOObj)

- (ObjectPro *)property
{
    return objc_getAssociatedObject(self, @selector(property));
}

- (void)setProperty:(ObjectPro *)property
{
    objc_setAssociatedObject(self, @selector(property), property,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)objDict
{
    return objc_getAssociatedObject(self, @selector(objDict));
}

- (void)setObjDict:(NSMutableDictionary *)objDict
{
    objc_setAssociatedObject(self, @selector(objDict), objDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation NSObject (KVO)

- (void)addObservedObject:(NSObject *)obj forKeyPath:(NSString *)keyPath block:(KVOBlock)block
{
    if (!obj) return;
    [obj addObserver:self
          forKeyPath:keyPath
             options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
             context:nil];
    NSMutableDictionary *dict = self.objDict;
    if(!dict){
        dict = [NSMutableDictionary dictionary];
        self.objDict = dict;
    }
    //将被监听对象的地址作为key，找到以被监听对象的keyPath为key，对应block为value的字典
    NSMutableDictionary *blockDict = [dict objectForKey:[NSString stringWithFormat:@"%p",obj]];
    if(!blockDict){
        blockDict = [NSMutableDictionary dictionary];
        [dict setObject:blockDict forKey:[NSString stringWithFormat:@"%p",obj]];
    }
    [blockDict setObject:block forKey:keyPath];
    //对调用对象添加属性，当对象销毁时遍历block数组移除KVO监听
    if(!self.property){
        self.property = [[ObjectPro alloc] init];
        self.property.blockArray = [NSMutableArray array];
    }
    __unsafe_unretained typeof(self) weakSelf = self;
//    __weak typeof(obj) weakObj = obj;
    [self.property.blockArray addObject:^{
//        [weakObj removeObserver:weakSelf forKeyPath:keyPath];
        [obj removeObserver:weakSelf forKeyPath:keyPath];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSString *key = [NSString stringWithFormat:@"%p",object];
    NSMutableDictionary *blockDict = [self.objDict objectForKey:key];
    if(blockDict){
        KVOBlock block = blockDict[keyPath];
        if(block){
            block(change[NSKeyValueChangeOldKey],change[NSKeyValueChangeNewKey]);
        }
    }
}

@end
