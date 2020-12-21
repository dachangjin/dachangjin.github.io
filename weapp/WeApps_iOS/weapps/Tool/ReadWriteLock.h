//
//  ReadWriteLock.h
//  weapps
//
//  Created by tommywwang on 2020/7/1.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReadWriteLock : NSObject
-(void) readLockLock;

-(void) writeLockLock;

-(void) readLockUnlock;

-(void) writeLockUnlock;

@end

NS_ASSUME_NONNULL_END
