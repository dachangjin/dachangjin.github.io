//
//  QMAAudioSessionHelper.m
//  QQMainProject
//
//  Created by 冯华威 on 2019/3/22.
//  Copyright © 2019年 tencent. All rights reserved.
//
#import "QMAAudioSessionHelper.h"
#import "QQAudioSessionManager.h"

@implementation QMAAudioSessionHelper
#pragma mark - QQAudioSessionManagerDelegate
//被内部业务打断回调
- (void)onAudioSessionActive {
    if (self.pauseBlock) {
        self.pauseBlock();
    }
}

//被第三方APP打断回调
- (void)onIntterruptBegin {
    if (self.pauseBlock) {
        self.pauseBlock();
    }
}

//释放音频使用权，恢复第三方app回调
- (void)onDeactiveWithSystem {
    // do nothing;
}

//被内部业务恢复回调
- (void)onAudioSessionDeactive {
    if (self.resumePlayBlock) {
        self.resumePlayBlock();
    }
}

//被第三方app恢复回调
- (void)onIntterruptEnd {
    if (self.resumePlayBlock) {
        self.resumePlayBlock();
    }
}

@end
 
