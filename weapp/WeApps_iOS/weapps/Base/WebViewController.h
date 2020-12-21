//
//  ViewController.h
//  weapps
//
//  Created by tommywwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMUICommonViewController.h"
#import "WebView.h"
#import "QMUIKit.h"


@interface WebViewController : QMUICommonViewController <WebHost>

@property (nonatomic, copy) NSURL *URL;

@end

