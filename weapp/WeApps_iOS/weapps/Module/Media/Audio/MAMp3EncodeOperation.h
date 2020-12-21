   //
//  MAMp3EncodeOperation.h
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/3/1.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MARecordTools;

@interface MAMp3EncodeOperation : NSOperation
@property (nonatomic, strong) NSString *formatType;
@property (nonatomic, assign) UInt32 encodeBitRate;
@property (nonatomic, assign) AudioStreamBasicDescription format;
@property (nonatomic, strong) NSMutableArray *recordQueue;
@property (nonatomic, strong) NSString *currentMp3File;
@property (nonatomic, strong) NSString *innerPathFile;
@property (nonatomic, weak) MARecordTools *recordTools;

- (void)stop;

- (BOOL)prepareEncoder;

@end
