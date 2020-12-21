//
//  WADebugInfo.h
//  weapps
//
//  Created by tommywwang on 2020/7/14.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WADebugInfo : NSObject

@property(nonatomic, assign) BOOL canShow;

+ (nonnull instancetype)sharedInstance;

- (void)show;

- (void)hide;

- (void)setButtonClickBlock:(void(^)(__kindof UIControl *sender))block;
@end

NS_ASSUME_NONNULL_END
