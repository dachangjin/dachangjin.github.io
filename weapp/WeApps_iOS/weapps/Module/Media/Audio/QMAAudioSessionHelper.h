//
//  QMAAudioSessionHelper.h
//  QQMainProject
//
//  Created by 冯华威 on 2019/3/22.
//  Copyright © 2019年 tencent. All rights reserved.
//
#import <Foundation/Foundation.h>
@protocol QQAudioSessionManagerDelegate;
NS_ASSUME_NONNULL_BEGIN
@interface QMAAudioSessionHelper : NSObject <QQAudioSessionManagerDelegate>
@property(nonatomic, copy) void(^resumePlayBlock)(void);
@property(nonatomic, copy) void(^pauseBlock)(void);
@end
NS_ASSUME_NONNULL_END
