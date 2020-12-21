//
//  ScanQRCodeMaskView.h
//  weapps
//
//  Created by tommywwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ScanQRCodeMaskView : UIView

- (id)initWithFrame:(CGRect)frame andMaskFrame:(CGRect)maskFrame;

- (void)startAnimation;

- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END
