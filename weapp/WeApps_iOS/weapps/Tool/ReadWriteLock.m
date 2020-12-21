//
//  ReadWriteLock.m
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "ReadWriteLock.h"
#import <libkern/OSAtomic.h>


@implementation ReadWriteLock
{
    @private
    volatile int32_t _readLockCount;
    volatile int32_t _writeLockFlag;
    NSRecursiveLock *_lock;
}

-(id) init {
    if(self = [super init]) {
        _readLockCount = 0;
        _writeLockFlag = 0;
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

-(void) readLockLock {

    if(!OSAtomicCompareAndSwap32(0, 0, &_writeLockFlag)) {
        
        //Has write lock

        [_lock lock];
        //Add read lock
        OSAtomicIncrement32(&_readLockCount);
        [_lock unlock];

    } else {
        //Add read lock
        OSAtomicIncrement32(&_readLockCount);
    }
}

-(void) writeLockLock {

    while(true) {
        [_lock lock];
        //Try block when has read lock
        OSAtomicCompareAndSwap32(0, 1, &_writeLockFlag);
        if(OSAtomicCompareAndSwap32(0, 0, &_readLockCount)) {
            //No read lock
            //[_writeLock lock];
            break;
        } else {
            [_lock unlock];
        }
    }


}

-(void) writeLockUnlock {
     OSAtomicCompareAndSwap32(1, 0, &_writeLockFlag);
    [_lock unlock];
    //[_writeLock unlock];
}

-(void) readLockUnlock {
    OSAtomicDecrement32(&_readLockCount);
}
@end
