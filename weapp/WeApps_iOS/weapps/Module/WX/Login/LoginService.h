//
//  LoginService.h
//  weapps
//
//  Created by tommywwang on 2020/5/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ArgsCallBlock)(NSDictionary *result);
typedef void(^ErrorBlok)(NSError *error);
typedef void(^CompleteBlock)(void);

@interface LoginService : NSObject


/**
 *  严格单例，唯一获得实例的方法.
 *
 *  @return 实例对象.
 */
+ (instancetype)sharedService;

- (void)loginWithSuccess:(ArgsCallBlock)success
                    fail:(ErrorBlok)fail            
        inViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
