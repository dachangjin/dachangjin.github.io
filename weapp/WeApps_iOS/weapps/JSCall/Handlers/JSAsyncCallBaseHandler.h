//
//  JSCallBaseHandler.h
//  weapps
//
//  Created by tommywwang on 2020/6/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSACallHandling.h"
#import "WebViewController.h"
#import "WebView.h"

#define JS_API(SEL) - (NSString *)js_##SEL:(JSAsyncEvent *)event
#define PRIVATE_API(SEL) - (NSString *)_##SEL:(JSAsyncEvent *)event

#define kFailWithError(_domain, _code, _info) \
if (event.fail) { \
       event.fail([NSError errorWithDomain:_domain code:_code userInfo:@{ NSLocalizedDescriptionKey: _info}]); \
   }

#define kFailWithErrorWithReturn(_domain, _code, _info) \
if (event.fail) { \
       event.fail([NSError errorWithDomain:_domain code:_code userInfo:@{ NSLocalizedDescriptionKey: _info}]); \
   } \
return _info;

#define kFailWithErr(_err) \
if (event.fail) {\
    event.fail(_err);\
}

#define kSuccessWithDic(_dic) \
if (event.success) { \
    event.success(_dic); \
}

#define kSELString(_name) \
static  NSString *const _name = @#_name;

#define kCheckArrayWithCount(_count) \
if (![self isValidArrayArgs:event.args withCount:_count]) { \
       return @""; \
   }

#define kCheckParamTypeAtIndex(_clz, index) \
if (![self isValidParameterType:_clz inArray:event.args atIndex:index]) { \
    return @""; \
}

#define kBeginCheck \
NSString *errorString = nil; \
   if (!(

#define kCheckInDict(_dict, _Class, _key, _canBeNil) \
[self checkValueClass:_Class ofKey:_key inDict:_dict canBeNil:_canBeNil withErrorString:&errorString] &&

#define kCheck(_Class, _key, _canBeNil) kCheckInDict(event.args, _Class, _key, _canBeNil)

//[self checkValueClass:_Class ofKey:_key inDict:event.args canBeNil:_canBeNil withErrorString:&errorString] &&


#define kCheckIsBooleanInDict(_dict, _Class, _key, _canBeNil, _isBoolean) \
[self checkValueClass:_Class ofKey:_key inDict:_dict canBeNil:_canBeNil isBoolean:_isBoolean withErrorString:&errorString] &&
#define kCheckIsBoolean(_Class, _key, _canBeNil, _isBoolean) \
kCheckIsBooleanInDict(event.args, _Class, _key, _canBeNil, _isBoolean)

//[self checkValueClass:_Class ofKey:_key inDict:event.args canBeNil:_canBeNil isBoolean:_isBoolean withErrorString:&errorString] &&

#define kEndCheckInDict(_dict, _Class, _key, _canBeNil) \
[self checkValueClass:_Class ofKey:_key inDict:_dict canBeNil:_canBeNil withErrorString:&errorString] \
    )) { \
    NSString *string = NSStringFromSelector(_cmd); \
    if ([string hasPrefix:@"js_"]) { \
        string = [string substringFromIndex:3]; \
    } \
    kFailWithErrorWithReturn(string, -1, errorString) \
}


#define kEndCheck(_Class, _key, _canBeNil) kEndCheckInDict(event.args, _Class, _key, _canBeNil)
//[self checkValueClass:_Class ofKey:_key inDict:event.args canBeNil:_canBeNil withErrorString:&errorString] \
//    )) { \
//    NSString *string = NSStringFromSelector(_cmd); \
//    if ([string hasPrefix:@"js_"]) { \
//        string = [string substringFromIndex:3]; \
//    } \
//    kFailWithErrorWithReturn(string, -1, errorString) \
//}

#define kEndChecIsBoonleanInDict(_dict, _key, _canBeNil) \
[self checkValueClass:[NSNumber class] ofKey:_key inDict:_dict canBeNil:_canBeNil isBoolean:YES withErrorString:&errorString] \
    )) { \
    NSString *string = NSStringFromSelector(_cmd); \
    if ([string hasPrefix:@"js_"]) { \
        string = [string substringFromIndex:3]; \
    } \
    kFailWithErrorWithReturn(string, -1, errorString) \
}

#define kEndChecIsBoonlean(_key, _canBeNil) \
kEndChecIsBoonleanInDict(event.args, _key, _canBeNil)
//[self checkValueClass:[NSNumber class] ofKey:_key inDict:event.args canBeNil:_canBeNil isBoolean:YES withErrorString:&errorString] \
//    )) { \
//    NSString *string = NSStringFromSelector(_cmd); \
//    if ([string hasPrefix:@"js_"]) { \
//        string = [string substringFromIndex:3]; \
//    } \
//    kFailWithErrorWithReturn(string, -1, errorString) \
//}

NS_ASSUME_NONNULL_BEGIN



@interface JSAsyncCallBaseHandler : NSObject <JSACallHandling>

- (void)event:(JSAsyncEvent *)event successWithDic:(NSDictionary *_Nullable)dic;

- (void)event:(JSAsyncEvent *)event failWithError:(NSError *_Nullable)error;


/// 检查字典里面的对象类型，非boolean
/// @param clz 类型
/// @param key key
/// @param dict 字典
/// @param canBeNil 是否可为空
/// @param string 返回的错误信息
- (BOOL)checkValueClass:(Class)clz
                  ofKey:(NSString *)key
                 inDict:(NSDictionary *)dict
               canBeNil:(BOOL)canBeNil
        withErrorString:(NSString *_Nullable *_Nullable)string;


/// 检查字典里面的对象类型
/// @param clz 类型
/// @param key key
/// @param dict 字典
/// @param canBeNil 是否可为空
/// @param isBoolean 是否为js Boolean类型
/// @param string 返回的错误信息
- (BOOL)checkValueClass:(Class)clz
                  ofKey:(NSString *)key
                 inDict:(NSDictionary *)dict
               canBeNil:(BOOL)canBeNil
              isBoolean:(BOOL)isBoolean
        withErrorString:(NSString *_Nullable *_Nullable)string;

/// 参数检查，对象类型是否符合clz
/// @param object 对象
/// @param clz 类型
- (BOOL)isInvalidObject:(id)object ofClass:(Class)clz;

/// 检查对象是否可用
/// @param object 对象
/// @param clz 类型
- (BOOL)isValidObject:(id)object ofClass:(Class)clz;


/// 检测args是否为数组，长度是否匹配
/// @param object args
/// @param count 长度
- (BOOL)isValidArrayArgs:(id)object withCount:(NSUInteger)count;

/// 检查数组参数对应index参数类型是否匹配
/// @param clz 类型
/// @param args 数组参数
/// @param index 参数index
- (BOOL)isValidParameterType:(Class)clz inArray:(NSArray *)args atIndex:(NSUInteger)index;

- (NSString *)jsTypeOfObject:(id)objc;

@end

NS_ASSUME_NONNULL_END
