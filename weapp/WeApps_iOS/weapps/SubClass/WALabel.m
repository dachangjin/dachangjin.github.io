//
//  WALabel.m
//  weapps
//
//  Created by tommywwang on 2020/7/3.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALabel.h"

@implementation WALabel

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize superSize = [super sizeThatFits:size];
    if (superSize.width < K_SCREEN_WIDTH - 80) {
        return CGSizeMake(K_SCREEN_WIDTH - 80, superSize.height);
    } else {
        return superSize;
    }
}

@end
