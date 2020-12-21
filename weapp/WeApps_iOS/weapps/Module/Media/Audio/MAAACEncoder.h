//
//  MAAACEncoder.m
//
//
//  Created by jreeqiu on 3/20/19.
//  Copyright (c) 2019 Tencent. All rights reserved.
//
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MAAACEncoder : NSObject

@property (nonatomic) AudioStreamBasicDescription format;

@property (nonatomic) UInt32 encodeBitRate;

- (BOOL)setupEncoder;

- (NSData *)encodeBufferData:(NSData *)data;

@end
