//Tencent is pleased to support the open source community by making WeDemo available.
//Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
//Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
//http://opensource.org/licenses/MIT
//Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

#ifndef AUTH_SDK_DEMO_DEFINITION
#define AUTH_SDK_DEMO_DEFINITION
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NSMutableDictionary+NilCheck.h"

#define K_SCREEN_WIDTH  ([UIScreen mainScreen].bounds.size.width)
#define K_SCREEN_HEIGHT  ([UIScreen mainScreen].bounds.size.height)
#define WEB_STORAGE @"webStorage"

#define kWAShowAlertView(_title, _message, _VC) do{\
UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:_title message:_message preferredStyle:UIAlertControllerStyleAlert];\
[_VC presentViewController:alertVC animated:YES completion:nil];\
}while(0)

#define kStringEqualToString(_aString, _bString) [_aString isEqualToString:_bString]
#define kStringContainString(_aString, _bStirng) [_aString containsString:_bStirng]

#define kWA_DictSetObjcForKey(_dict, _key, _objc) [_dict WA_setObject:_objc forKey:_key];
#define kWA_ArrayAddObject(_array, _object) if (_object) {\
    [_array addObject:_object];\
}

#define kWA_DictContainKey(_dict, _key) [_dict objectForKey:_key] != nil


#ifndef weakify

#define weakify( x ) \
autoreleasepool{} __weak __typeof__(x) __weak_##x##__ = x;

#endif

#ifndef strongify

#define strongify( x ) \
try{} @finally{} __typeof__(x) x = __weak_##x##__;

#endif


typedef enum : NSUInteger {
    WXSexTypeUnknown,
    WXSexTypeMale,
    WXSexTypeFemale
} WXSexType;


typedef enum : NSInteger {
    WXErrorCodeNoError = 0,
    WXErrorCodeUnknown = 1,
    WXErrorCodeInvalidCode = 40029,
    WXErrorCodeInvalidRefreshToken = 40030,
    WXErrorCodeInvalidOpenId = 40003,
    WXErrorCodeCanNotAccessOpenServer = -10001,
    WXErrorCodeRequestError = -10002,
    WXErrorCodeTicketNotMatch = 30001,
    WXErrorCodeSessionKeyExpired = -20003,
    WXErrorCodeUserExisted = 20001,
    WXErrorCodeAlreadyBind = 20002,
    WXErrorCodeUserNotExisted = 20003,
    WXErrorCodePasswordNotMatch = 20004,
    WXErrorCodeAuthDenied = 50000,
    WXErrorCodeAuthCancel = 50001,

} WXErrorCode;


typedef enum : NSUInteger {
    ADLoginTypeFromUnknown,
    ADLoginTypeFromApp,
    ADLoginTypeFromWX
}ADLoginType;

typedef void(^ButtonCallBack)(id sender);

//A better version of WALOG
#ifdef DEBUG
#define WALOG(fmt,...) NSLog((@"[函数名:%s]" "[行号:%d] :" fmt),__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define WALOG(...) ;
#endif

//A better version of extern
#ifdef __cplusplus
#define AUTH_DEMO_EXTERN	extern "C" __attribute__((visibility ("default")))
#else
#define AUTH_DEMO_EXTERN	    extern __attribute__((visibility ("default")))
#endif

//Show Error
#define WXShowErrorAlert(_title, _message)                      \
        UIViewController *VC = [UIApplication sharedApplication].keyWindow.rootViewController;                                                      \
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:_title message:_message preferredStyle:UIAlertControllerStyleAlert]; \
        [VC presentViewController:alert animated:YES completion:nil];                                                                               \
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];

@class UIActivityIndicatorView;

static UIActivityIndicatorView *gIndicatorView;
//Show ActivityIndicator
#define WX_SHOW_ACTIVITY(superView) do { \
    if (gIndicatorView == nil) { \
            gIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]; \
        }\
    if (![gIndicatorView isAnimating]){ \
            [superView addSubview:gIndicatorView]; \
            gIndicatorView.center = superView.center;\
            [gIndicatorView startAnimating]; \
        }   \
    } while(0)
//Hide ActivityIndicator
#define WX_HIDE_ACTIVITY do { \
    if ([gIndicatorView isAnimating]) { \
        [gIndicatorView stopAnimating];\
    } \
} while (0)

//#import "WXBaseResp.h"

#endif
