//
//  WANetworkHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WANetworkHandler.h"
#import "NSString+Base64.h"
#import "Weapps.h"
#import "PathUtils.h"
#import "FileUtils.h"

static  NSString *const abortRequest = @"abort";

kSELString(request)
kSELString(downloadFile)
kSELString(uploadFile)
//kSELString(operateRequestTask)
//kSELString(operateDownloadTask)
//kSELString(operateUploadTask)
kSELString(onHeadersReceived)
kSELString(offHeadersReceived)
kSELString(offProgressUpdate)
kSELString(onProgressUpdate)



#pragma mark - 填充formData数据用的辅助分类
@interface NSMutableData (MiniAppFormData)
- (void)MAFormDataAppendKey:(NSString *)key
                       type:(NSString *)type
                      value:(id)value
                   boundary:(NSString *)boundary;
- (void)MAFormDataAppendKey:(NSString *)key
                   filePath:(NSString *)filePath
                   boundary:(NSString *)boundary;
- (void)MAFormDataAppendEndWithBoundary:(NSString *)boundary;
@end
@implementation NSMutableData (MiniAppFormData)
- (void)MAFormDataAppendKey:(NSString *)key
                       type:(NSString *)type
                      value:(id)value
                   boundary:(NSString *)boundary {
    // 1. 开始标记
    NSString* startBoundary = [NSString stringWithFormat:@"--%@\r\n", boundary];
    [self appendData:[startBoundary dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 2. header部分
    NSString *str = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key];
    [self appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (type) {
        str = [NSString stringWithFormat:@"Content-Type: %@\r\n", type];
        [self appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [self appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 3. 数据部分
    if ([value isKindOfClass:[NSString class]]) {
        [self appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([value isKindOfClass:[NSData class]]) {
        [self appendData:value];
    }
    [self appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)MAFormDataAppendKey:(NSString *)key filePath:(NSString *)filePath boundary:(NSString *)boundary {
    // 1. 开始标记
    NSString* startBoundary = [NSString stringWithFormat:@"--%@\r\n", boundary];
    [self appendData:[startBoundary dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 2. header部分
    NSString *fileName = [filePath lastPathComponent];
    NSString *str = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, fileName];
    [self appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    str = [NSString stringWithFormat:@"Content-Type: %@\r\n", [FileUtils getFileMimeType:filePath]];
    [self appendData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    [self appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 3. 数据部分
    // MARK: 因为用户可用的存储空间被限制为10M，所以单个文件上限是10M，这里全部读进内存是可以接受的
    NSData* fileData = [NSData dataWithContentsOfFile:filePath];
    [self appendData:fileData];
    [self appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
}
- (void)MAFormDataAppendEndWithBoundary:(NSString *)boundary {
    NSString* endBoundary = [NSString stringWithFormat:@"--%@--\r\n", boundary];
    [self appendData:[endBoundary dataUsingEncoding:NSUTF8StringEncoding]];
}
@end

@implementation WANetworkHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            request,
            downloadFile,
            uploadFile,
            onHeadersReceived,
            offHeadersReceived,
            onProgressUpdate,
            offProgressUpdate
        ];
    }
    return methods;
}

JS_API(abort){
    kBeginCheck
//    kCheck([NSString class], @"type", YES)
    kEndCheck([NSString class], @"identifier", NO)
    NSString *taskId = event.args[@"identifier"];
//    NSString *type = event.args[@"type"];
    [[Weapps sharedApps].networkManager abortDataTaskWithIdentifier:@([taskId integerValue])
                                                  completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithError(abortRequest, -1, error.userInfo[NSLocalizedDescriptionKey])
        }
    }];
    return @"";
}

JS_API(request){
    
    //data 可能为string/object/ArrayBuffer 类型，单独检测，dataType交给js处理。
    //    enableHttp2、enableQuic、enableCache目前先不支持
    kBeginCheck
    kCheck([NSString class], @"url", NO)
    kCheck([NSDictionary class], @"header", YES)
    kCheck([NSNumber  class], @"timeout", YES)
    kCheck([NSString class], @"method", YES)
    kEndCheck([NSString class], @"responseType", YES)
    
    NSNumber *taskId;
    do {
        NSString* failReason = nil;
        // --- 处理url参数 ---
        // 必填参数：
        // 1. 符合urlWithInputUrl逻辑
        NSString* urlString = event.args[@"url"];
        NSURL* url = [self urlWithInputUrl:urlString reason:&failReason];
        if (failReason) {
            kFailWithError(request, -1, failReason)
            break;
        }
        // --- 处理method参数 ---
        // 可选参数：可以不填，但填了就必须是合法值，否则报错
        NSArray* validMethods = @[@"OPTIONS", @"GET", @"HEAD", @"POST", @"PUT", @"DELETE", @"TRACE", @"CONNECT"];
        NSString* method = event.args[@"method"];
        if (method == nil) {
            method = @"GET";
        }
        if (![validMethods containsObject:method.uppercaseString]) {
            // 提示语已和微信对齐
            kFailWithError(request, -1, @"method is invalid")
            break;
        }
        // --- 处理header参数 ---
        NSDictionary *header = event.args[@"header"];
        NSMutableDictionary* validHeader = [self headerWithInputHeader:header reason:&failReason];
        if (failReason) {
            kFailWithError(request, -1, failReason)
            break;
        }
        // --- 处理dataType参数 ---
        // MARK: dataType这个参数由jssdk负责处理
        
        // --- 处理responseType参数 ---
        NSArray* validResponseTypes = @[@"text", @"arraybuffer"];
        NSString *responseType = event.args[@"responseType"];
        if (responseType == nil || ![validResponseTypes containsObject:responseType.lowercaseString]) {
            //没有设置，或者不合法的responseType都认为是text
            responseType = @"text";
        }
        
        // --- 处理data参数 ---
        // request接口支持number, string, object, array, arraybuffer，
        // 但js会提前处理一波，传入客户端的只有NSString
        NSData* bodyData = nil;
        
        id inputData = event.args[@"data"];
        if ([inputData isKindOfClass:[NSString class]]) {
            bodyData = [inputData dataUsingEncoding:NSUTF8StringEncoding];
        } else if ([inputData isKindOfClass:[NSData class]]) {
            bodyData = inputData;
        } else if ([inputData isKindOfClass:[NSDictionary class]]) {
            @try {
                NSError *error;
                NSData *data = [NSJSONSerialization dataWithJSONObject:inputData options:NSJSONWritingFragmentsAllowed error:&error];

                bodyData = data;
            } @catch (NSException *exception) {
                kFailWithError(request, -1, @"request: parameter error: data format is invalid")
                return @"";
            }
        } else {
            if (inputData != nil) {
                // 如果出现有输入数据，但类型无法处理
                kFailWithError(request, -1, @"request: parameter error: data should be string ,arraybuffer or object")
                return @"";
            }
        }
        
        if ([[method uppercaseString]isEqualToString:@"GET"]) {
            bodyData = nil;
        }
        
        // --- 生成Task ---
        NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.HTTPMethod = method;
        urlRequest.allHTTPHeaderFields = validHeader;
        urlRequest.HTTPBody = bodyData;
        
        // 设置超时
        
        NSNumber *timeOut = event.args[@"timeout"];
        if (!timeOut) {
            //设置默认的timeout
            [urlRequest setTimeoutInterval:60];
        } else {
            [urlRequest setTimeoutInterval:[timeOut floatValue] / 1000];
        }
        taskId = [[Weapps sharedApps].networkManager dataTaskWithRequest:urlRequest
                                                            responseType:responseType
                                                                 webView:event.webView
                                                       completionHandler:^(BOOL success,
                                                                           NSDictionary * _Nullable result,
                                                                           NSError * _Nullable error) {
            if (success) {
                kSuccessWithDic(result)
            } else {
                kFailWithError(request, -1, error.userInfo[NSLocalizedDescriptionKey])
            }
        }];
    } while (0);
    return taskId ? [NSString stringWithFormat:@"%@",taskId] : @"null";
}


JS_API(downloadFile){
    kBeginCheck
    kCheck([NSString class], @"url", NO)
    kCheck([NSDictionary class], @"header", YES)
    kCheck([NSNumber  class], @"timeout", YES)
    kEndCheck([NSString class], @"filePath", YES)
    NSNumber *taskId;
    do {
        NSString* failReason = nil;
        // --- 处理url参数 ---
        // 必填参数：
        // 1. 符合urlWithInputUrl逻辑
        NSString* urlString = event.args[@"url"];
        NSURL* url = [self urlWithInputUrl:urlString reason:&failReason];
        if (failReason) {
            kFailWithError(request, -1, failReason)
            break;
        }
        // --- 处理header参数 ---
        NSDictionary *header = event.args[@"header"];
        NSMutableDictionary* validHeader = [self headerWithInputHeader:header reason:&failReason];
        if (failReason) {
            kFailWithError(request, -1, failReason)
            break;
        }
        
        // --- 处理filePath参数 ---
        NSString *filePath = event.args[@"filePath"];
        BOOL filePathIsNil = NO;
        if (!filePath) {
            filePath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[url lastPathComponent]];
            filePathIsNil = YES;
        }
        // --- 生成Task ---
        NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url];
        urlRequest.allHTTPHeaderFields = validHeader;
        urlRequest.HTTPMethod = @"GET";
        // 设置超时
        
        NSNumber *timeOut = event.args[@"timeout"];
        if (!timeOut) {
            //设置默认的timeout
            [urlRequest setTimeoutInterval:60];
        } else {
            [urlRequest setTimeoutInterval:[timeOut floatValue] / 1000];
        }
        
        taskId = [[Weapps sharedApps].networkManager downloadTaskWithRequest:urlRequest
                                                                                  path:filePath
                                                                               webView:event.webView
                                                                     completionHandler:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
            if (success) {
                //没有传入filePath，会返回
                if (filePathIsNil) {
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:result];
                    kWA_DictSetObjcForKey(dic, @"tempFilePath", result[@"filePath"])
                    kSuccessWithDic(dic)
                } else {
                    kSuccessWithDic(result)
                }
            } else {
                kFailWithError(downloadFile, -1, error.userInfo[NSLocalizedDescriptionKey])
            }
        }];
        
    } while (0);
    return taskId ? [NSString stringWithFormat:@"%@",taskId] : @"null";
}


JS_API(uploadFile){
    kBeginCheck
    kCheck([NSString class], @"url", NO)
    kCheck([NSString class], @"filePath", NO)
    kCheck([NSString class], @"name", NO)
    kCheck([NSDictionary class], @"header", YES)
    kCheck([NSDictionary class], @"formData", YES)
    kEndCheck([NSNumber class], @"timeout", YES)
    NSNumber *taskId;
    do {
        NSString* failReason = nil;
        // --- 处理url参数 ---
        // 必填参数：
        // 1. 符合urlWithInputUrl逻辑
        NSString* urlString = event.args[@"url"];
        NSURL* url = [self urlWithInputUrl:urlString reason:&failReason];
        if (failReason) {
            kFailWithError(request, -1, failReason)
            break;
        }
        // --- 处理filePath参数 ---
        // 必填参数：
        // 1. 路径必须有可读权限
        // 2. 路径对应位置必须有文件
        NSString* filePath = event.args[@"filePath"];
        
        if (filePath.length == 0) {
            kFailWithError(uploadFile, -1, @"filePath is empty")
            break;
        }
        if (![FileUtils isValidFile:filePath]) {
            kFailWithError(uploadFile, -1, @"file path invalid")
            break;
        }
        // --- 处理name参数 ---
        // 必填参数：必须有值
        NSString* inputName = event.args[@"name"];
        if (inputName.length == 0) {
             kFailWithError(uploadFile, -1, @"name is empty")
                   break;
        }
        // --- 处理header参数 ---
        // 选填参数：
        // 1. 符合headerWithInputHeader逻辑
        // 2. Content-Type写死是form-data格式
        
        // --- 处理header参数 ---
        NSDictionary *header = event.args[@"header"];
        NSMutableDictionary* validHeader = [self headerWithInputHeader:header reason:&failReason];
        if (failReason) {
           kFailWithError(request, -1, failReason)
           break;
        }
        
        NSString* uploadFormBoundary = [[NSString stringWithFormat:@"time%lf", CFAbsoluteTimeGetCurrent()] MD5String];
        
        // 上传请求中Content-Type固定为form-data
        validHeader[@"content-type"] = [NSString stringWithFormat:@"multipart/form-data; boundary=%--@", uploadFormBoundary];
        
        // --- 处理formData参数 ---
        // 选填参数：类型不正确就跳过
        NSMutableData *binBodyData = [NSMutableData new];
        
        NSDictionary *formData = event.args[@"formData"];
        for (NSString* key in formData) {
            if (![key isKindOfClass:[NSString class]]) {
                // key不是string，无法处理，跳过
                continue;
            }
            
            id value = formData[key];
            if (![value isKindOfClass:[NSString class]]
                && ![value isKindOfClass:[NSData class]]) {
                // value不是string，也不是arrayBuffer，无法处理，跳过
                continue;
            }
            
            // 将key/value添加进表单数据
            [binBodyData MAFormDataAppendKey:key
                                        type:nil
                                       value:value
                                    boundary:uploadFormBoundary];
        }
        
        // 将absFilePath的文件内容添加进表单数据
        [binBodyData MAFormDataAppendKey:inputName filePath:filePath boundary:uploadFormBoundary];

        // 表单数据结束
        [binBodyData MAFormDataAppendEndWithBoundary:uploadFormBoundary];

        // --- 生成Task ---
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        request.allHTTPHeaderFields = validHeader;
        NSNumber *timeOut = event.args[@"timeout"];
        if (!timeOut) {
            //设置默认的timeout
            [request setTimeoutInterval:60];
        } else {
            [request setTimeoutInterval:[timeOut floatValue] / 1000];
        }
        taskId = [[Weapps sharedApps].networkManager uploadTaskWithRequest:request
                                                                  fromData:binBodyData
                                                                   webView:event.webView
                                                         completionHandler:^(BOOL success, NSDictionary * _Nullable result, NSError * _Nullable error) {
            if (success) {
//xCV curl -X PUT "http://www.httpbin.org/put" -H "accept: application/json"123q  AZ                kSuccessWithDic(result)
            } else {
                kFailWithError(downloadFile, -1, error.userInfo[NSLocalizedDescriptionKey])
            }
        }];
    } while (0);
    
    return taskId ? [NSString stringWithFormat:@"%@",taskId] : @"null";
}

JS_API(onHeadersReceived){
    NSString *taskId = event.args[@"identifier"];
    [[Weapps sharedApps].networkManager webView:event.webView
                       onRequestHeadersReceived:event.callbacak
              withIdentifier:@([taskId integerValue])];
    return @"";
}

JS_API(offHeadersReceived){
    NSString *taskId = event.args[@"identifier"];
    [[Weapps sharedApps].networkManager webView:event.webView
                      offRequestHeadersReceived:event.callbacak
              withIdentifier:@([taskId integerValue])];
    return @"";
}

JS_API(onProgressUpdate){
    NSString *taskId = event.args[@"identifier"];
    NSString *type = event.args[@"type"];
    if ([type isEqualToString:@"downloadTask"]) {
        [[Weapps sharedApps].networkManager webView:event.webView
                             onDownloadTaskProgress:event.callbacak
                                     withIdentifier:@([taskId integerValue])];
    } else if ([type isEqualToString:@"uploadTask"]) {
        [[Weapps sharedApps].networkManager webView:event.webView
                               onUploadTaskProgress:event.callbacak
                                     withIdentifier:@([taskId integerValue])];
    }
    return @"";
}

JS_API(offProgressUpdate){
    NSString *taskId = event.args[@"identifier"];
    NSString *type = event.args[@"type"];
    if ([type isEqualToString:@"downloadTask"]) {
        [[Weapps sharedApps].networkManager webView:event.webView
                             offDownloadTaskProgress:event.callbacak
                                     withIdentifier:@([taskId integerValue])];
    } else if ([type isEqualToString:@"uploadTask"]) {
        [[Weapps sharedApps].networkManager webView:event.webView
                               offUploadTaskProgress:event.callbacak
                                     withIdentifier:@([taskId integerValue])];
    }
    return @"";
}

- (NSURL *)urlWithInputUrl:(NSString *)urlString reason:(NSString **)outReason {
    // 处理逻辑：
    // 1. 必须有值，且类型是string
    // 2. 长度必须大于0
    // 3. 必须能初始化成NSURL对象（如果不行会尝试做一次urlencode，然后再试一次）
    
    if (outReason) {
        *outReason = nil;
    }
    
    NSURL* url = nil;
    do {
        if (![urlString isKindOfClass:[NSString class]]) {
            if (outReason) {
                // 提示语已和微信对齐
                *outReason = [NSString stringWithFormat:@"parameter error: parameter.url should be String instead of %@;", [self jsTypeOfObject:urlString]];
            }
            break;
        }
        
        if (urlString.length == 0) {
            if (outReason) {
                // 提示语已和微信对齐
                *outReason = @"url is empty";
            }
            break;
        }
        
        url = [NSURL URLWithString:urlString];
        if (url == nil) {
            // 尝试做非法字符（如中文）的encode，但不改变url的结构，即不encode ":/?=&"等符号
            url = [NSURL URLWithString:[urlString encodeURIString]];
            if (url == nil) {
                if (outReason) {
                    *outReason = @"url is invalid";
                }
                break;
            }
        }
        
        
    } while (0);
    
    return url;
}

- (NSMutableDictionary *)headerWithInputHeader:(NSDictionary *)inputHeader reason:(NSString **)outReason {
    // 处理逻辑：
    // 1. 遇到类型不正确的情况就跳过
    // 2. Referer 按固定的模式设置，不使用业务填过来的数据
    
    if (outReason) {
        *outReason = nil;
    }
    
    NSMutableDictionary* header = [NSMutableDictionary dictionary];
    
    if (![inputHeader isKindOfClass:[NSDictionary class]]) {
        // 不是合法类型就设置为nil，跳过这部分逻辑
        inputHeader = nil;
    }
    
    BOOL hasSetCookie = NO;
    for (NSString* key in inputHeader) {
        if (![key isKindOfClass:[NSString class]]) {
            // key不是string，不合法
            continue;
        }
        
        NSString* value = inputHeader[key];
        if (![value isKindOfClass:[NSString class]]) {
            // value不是string，也不合法
            continue;
        }
        
        header[key.lowercaseString] = value;
        if (hasSetCookie == NO // 这个条件是为了提高效率的
            && [key.lowercaseString isEqualToString:@"cookie"]) {
            hasSetCookie = YES;
        }
    }
    
//    header[@"referer"] = referer;
    
    if (!hasSetCookie) {
        // 如果业务没有主动设置cookie，那么我们发请求需要强行把cookie设置为空，避免iOS系统
        // 把NSHTTPCookieStorage中的cookie附带出去
        header[@"cookie"] = @"";
    }
    
    return header;
}



@end
