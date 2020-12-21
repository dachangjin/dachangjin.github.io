//
//  EventListenerList.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "EventListenerList.h"
#import "ReadWriteLock.h"

@implementation WeakReferenceWrapper {
    __weak id _weakReference;
}

+ (id)wrapNonretainedObject:(id)obj {
    return [[WeakReferenceWrapper alloc] initWithNonretainedObject:obj];
}


- (id)initWithNonretainedObject:(id)obj {
    self = [super init];
    if (self) {
        _weakReference = obj;
    }
    return self;
}

- (id)get {
    return _weakReference;
}

- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    WeakReferenceWrapper* other = (WeakReferenceWrapper*) object;
    return ([self get] == [other get]);
}

- (NSUInteger)hash {
    if (_weakReference) {
        return [_weakReference hash];
    }
    return 0;
}
@end

@implementation EventListenerList {
    @private
    ReadWriteLock *_lock;
    NSMutableSet <WeakReferenceWrapper *>*_listeners;
}
- (id)init {
    if(self = [super init]) {
        _lock = [[ReadWriteLock alloc] init];
        _listeners = [NSMutableSet set];
    }
    return self;
}

- (void)addListener:(id)listener {
    [_lock writeLockLock];
    [_listeners addObject:[WeakReferenceWrapper wrapNonretainedObject:listener]];
    [_lock writeLockUnlock];
}

- (void)removeListener:(id)listener {
    [_lock writeLockLock];
    NSMutableArray *array = [NSMutableArray array];
    for (WeakReferenceWrapper *weak in _listeners) {
        id weakObj = [weak get];
        if (weakObj == listener || !weakObj) {
            [array addObject:weak];
        }
    }
    for (WeakReferenceWrapper *weak in array) {
        [_listeners removeObject:weak];
    }
    [_lock writeLockUnlock];
}

- (NSInteger)size {
    [_lock readLockLock];
    @try {
        return [_listeners count];
    } @finally {
        [_lock readLockUnlock];
    }
}

- (void)fireListeners:(void (^)(id l))block {
    [_lock readLockLock];
    @try {
        for(id l in _listeners) {
            if ([l get]) {
                 block([l get]);
            }
        }
    } @finally {
        [_lock readLockUnlock];
    }
}

- (BOOL)containsListener:(id)listener
{
    [_lock readLockLock];
    @try {
        for(id l in _listeners) {
            if ([[l get] isEqual:listener]) {
                return YES;
            }
        }
        return NO;
    } @finally {
        [_lock readLockUnlock];
    }
}

- (void)clear
{
    [_lock writeLockLock];
    [_listeners removeAllObjects];
    [_lock writeLockUnlock];
}
@end
