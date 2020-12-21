//
//  EventListenerList.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WeakReferenceWrapper : NSObject

+ (id)wrapNonretainedObject:(id)obj;
- (id)initWithNonretainedObject:(id)obj;
- (id)get;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end

@interface EventListenerList : NSObject
- (id)init;
- (void)addListener:(id) listener;
- (void)removeListener:(id) listener;
- (void)fireListeners:(void(^)(id listener)) block;
- (NSInteger) size;
- (BOOL)containsListener:(id)listener;
- (void)clear;
@end


NS_ASSUME_NONNULL_END
