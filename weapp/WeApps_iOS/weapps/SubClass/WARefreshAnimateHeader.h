//
//  WARefreshAnimateHeader.h
//  weapps
//
//  Created by tommywwang on 2020/7/7.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MJRefreshNormalHeader.h"

typedef NS_ENUM(NSUInteger, WARefreshAnimateHeaderStyle) {
    WARefreshAnimateHeaderStyleDark,
    WARefreshAnimateHeaderStyleLight,
};

NS_ASSUME_NONNULL_BEGIN

@interface WARefreshAnimateHeader : MJRefreshStateHeader

- (void)setStyle:(WARefreshAnimateHeaderStyle)sytle;

@end

NS_ASSUME_NONNULL_END
