//
//  WANetworkManager.m
//  weapps
//
//  Created by tommywwang on 2020/7/6.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAWebViewNetworkManager.h"
#import "AFHTTPSessionManager.h"
#import "Weapps.h"
#import "EventListenerList.h"
#import "WKWebViewHelper.h"

typedef NSURLRequest *(^HTTPRedirectionBlock)(NSURLSession *session,
                                              NSURLSessionTask *task,
                                              NSURLResponse *response,
                                              NSURLRequest *request);
typedef NSURLSessionAuthChallengeDisposition(^AuthenticationChallengeBlock)(NSURLSession *session,
                                                                            NSURLAuthenticationChallenge *challenge,
                                                                            NSURLCredential * _Nullable __autoreleasing * _Nullable credential);
typedef void(^TaskDidSendBodyDataBlock)(NSURLSession *session,
                                        NSURLSessionTask *task,
                                        int64_t bytesSent, int64_t
                                        totalBytesSent, int64_t
                                        totalBytesExpectedToSend);

typedef NSURLSessionResponseDisposition(^TaskDidReceiveResponseBlock)(NSURLSession *session,
                                                                      NSURLSessionDataTask *dataTask,
                                                                      NSURLResponse *response);

typedef NS_ENUM(NSInteger, WANetworkTaskState) {
    WANetworkTaskStateInit,
    WANetworkTaskStateSending,
    WANetworkTaskStateReceivedHeader,
    WANetworkTaskStateReceivedData,
    WANetworkTaskStateFinished,
    WANetworkTaskStateError,
};

@interface WANetworkTaskModel : NSObject

@property (nonatomic, readonly) NSString* taskIdKey;
@property (nonatomic, copy) NSString *responseType;
@property (nonatomic, assign) WANetworkTaskState state;
@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) NSString* errMsg;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, strong) NSDictionary* headers;
@property (nonatomic, strong) NSMutableData* data;
// webView对应监听callbacks字典。key为webView地址，value为webView监听的callback数组
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *headersReceivedCallbacksDic;
// 监听当前任务的webView,可能多页面监听
@property (nonatomic, strong) EventListenerList *webViews;
@property (nonatomic, strong) NSLock *lock;

- (void)doHeadersReceivedcallbackWithResult:(NSDictionary *)result;

- (void)webView:(WebView *)webView addHeadersReceivedCallback:(NSString *)callback;

- (void)webView:(WebView *)webView removeHeadersReceivedCallback:(NSString *)callback;

/// 清除webView
/// @param webView webView
- (void)cleanWebView:(WebView *)webView;
@end

@implementation WANetworkTaskModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _headersReceivedCallbacksDic = [NSMutableDictionary dictionary];
        _webViews = [[EventListenerList alloc] init];
        _lock = [[NSLock alloc] init];
    }
    return self;
}

- (NSString *)taskIdKey
{
    return @"identifier";
}

//处理HeadersReceived回调
- (void)doHeadersReceivedcallbackWithResult:(NSDictionary *)result
{
    @weakify(self)
    [self.webViews fireListeners:^(WebView *listener) {
        @strongify(self)
        NSString *key = [self getKeyByWebView:listener];
        [self.lock lock];
        NSArray *callbacks = self.headersReceivedCallbacksDic[key];
        if (callbacks.count) {
            for (NSString *callback in callbacks) {
                [WKWebViewHelper successWithResultData:result
                                               webView:listener
                                              callback:callback];
            }
        }
        [self.lock unlock];
    }];
}


- (void)webView:(WebView *)webView addHeadersReceivedCallback:(NSString *)callback
{
    if (![_webViews containsListener:webView]) {
        [_webViews addListener:webView];
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.headersReceivedCallbacksDic[key];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
        self.headersReceivedCallbacksDic[key] = callbacks;
    }
    [callbacks addObject:callback];
    [self.lock unlock];
}

- (void)webView:(WebView *)webView removeHeadersReceivedCallback:(NSString *)callback
{
    if (![_webViews containsListener:webView]) {
        return;
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.headersReceivedCallbacksDic[key];
    if (callbacks) {
        [callbacks removeObject:callback];
        if (callbacks.count == 0) {
            [self.headersReceivedCallbacksDic removeObjectForKey:key];
        }
    }
    [self.lock unlock];
}

//webView销毁清除对应数据
- (void)cleanWebView:(WebView *)webView
{
    //删除webView
    [_webViews removeListener:webView];
    //清除对应callbacks
    [_lock lock];
    [_headersReceivedCallbacksDic removeObjectForKey:[self getKeyByWebView:webView]];
    [_lock unlock];
}

//获取webView内存地址
- (NSString *)getKeyByWebView:(WebView *)webView
{
    return [NSString stringWithFormat:@"%p",webView];
}

@end


@interface WANetworkDownlaodTaskModel : WANetworkTaskModel

@property (nonatomic, copy) NSString *filePath;
// webView对应监听callbacks字典。key为webView地址，value为webView监听的callback数组
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *progressDownloadCallbacksDic;

- (void)webView:(WebView *)webView addProgressDownloadCallback:(NSString *)callback;

- (void)webView:(WebView *)webView removeProgressDownloadCallback:(NSString *)callback;

- (void)doDownloadProgressCallbackWithResult:(NSDictionary *)result;

@end

@implementation WANetworkDownlaodTaskModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _progressDownloadCallbacksDic = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)webView:(WebView *)webView addProgressDownloadCallback:(NSString *)callback
{
    if (![self.webViews containsListener:webView]) {
        [self.webViews addListener:webView];
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.progressDownloadCallbacksDic[key];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
        self.progressDownloadCallbacksDic[key] = callbacks;
    }
    [callbacks addObject:callback];
    [self.lock unlock];
}

- (void)webView:(WebView *)webView removeProgressDownloadCallback:(NSString *)callback
{
    if (![self.webViews containsListener:webView]) {
        return;
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.progressDownloadCallbacksDic[key];
    if (callbacks) {
        [callbacks removeObject:callback];
        if (callbacks.count == 0) {
            [self.progressDownloadCallbacksDic removeObjectForKey:key];
        }
    }
    [self.lock unlock];
}

//处理下载进度回调
- (void)doDownloadProgressCallbackWithResult:(NSDictionary *)result
{
    @weakify(self)
    [self.webViews fireListeners:^(WebView *listener) {
        @strongify(self)
        NSString *key = [self getKeyByWebView:listener];
        [self.lock lock];
        NSArray *callbacks = self.progressDownloadCallbacksDic[key];
        if (callbacks.count) {
            for (NSString *callback in callbacks) {
                [WKWebViewHelper successWithResultData:result
                                               webView:listener
                                              callback:callback];
            }
        }
        [self.lock unlock];
    }];
}

- (void)cleanWebView:(WebView *)webView
{
    [self.webViews removeListener:webView];
    [self.lock lock];
    [self.headersReceivedCallbacksDic removeObjectForKey:[self getKeyByWebView:webView]];
    [self.progressDownloadCallbacksDic removeObjectForKey:[self getKeyByWebView:webView]];
    [self.lock unlock];
}

@end


@interface WANetworkUploadTaskModel : WANetworkTaskModel

//webView对应监听callbacks字典。key为webView地址，value为webView监听的callback数组
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *progressUploadCallbacksDic;

- (void)webView:(WebView *)webView addProgressUplaodCallback:(NSString *)callback;

- (void)webView:(WebView *)webView removeProgressUploadCallback:(NSString *)callback;

@end

@implementation WANetworkUploadTaskModel

- (void)webView:(WebView *)webView addProgressUplaodCallback:(NSString *)callback
{
    if (![self.webViews containsListener:webView]) {
        [self.webViews addListener:webView];
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.progressUploadCallbacksDic[key];
    if (!callbacks) {
        callbacks = [NSMutableArray array];
        self.progressUploadCallbacksDic[key] = callbacks;
    }
    [callbacks addObject:callback];
    [self.lock unlock];
}

- (void)webView:(WebView *)webView removeProgressUploadCallback:(NSString *)callback
{
    if (![self.webViews containsListener:webView]) {
        return;
    }
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    NSMutableArray *callbacks = self.progressUploadCallbacksDic[key];
    if (callbacks) {
        [callbacks removeObject:callback];
        if (callbacks.count == 0) {
            [self.progressUploadCallbacksDic removeObjectForKey:key];
        }
    }
    [self.lock unlock];
}

//处理上传回调
- (void)doUploadProgressCallbackWithResult:(NSDictionary *)result
{
    @weakify(self)
    [self.webViews fireListeners:^(WebView *listener) {
        @strongify(self)
        NSString *key = [self getKeyByWebView:listener];
        [self.lock lock];
        NSArray *callbacks = self.progressUploadCallbacksDic[key];
        if (callbacks.count) {
            for (NSString *callback in callbacks) {
                [WKWebViewHelper successWithResultData:result
                                               webView:listener
                                              callback:callback];
            }
        }
        [self.lock unlock];
    }];
}

- (void)cleanWebView:(WebView *)webView
{
    [self.webViews removeListener:webView];
    [self.lock lock];
    [self.headersReceivedCallbacksDic removeObjectForKey:[self getKeyByWebView:webView]];
    [self.progressUploadCallbacksDic removeObjectForKey:[self getKeyByWebView:webView]];
    [self.lock unlock];
}

@end

@interface WAWebViewNetworkManager ()
@property (nonatomic, strong) EventListenerList *networkChangeListeners;
@end

@implementation WAWebViewNetworkManager
{
    NSMutableDictionary<NSNumber *, WANetworkTaskModel *> *_taskModels;
    NSLock *_taskModelLock;
    __weak Weapps *_app;
    AFHTTPSessionManager *_sessionManager;
    
    AFNetworkReachabilityManager *_reachabilityManager;

    
}

- (id)initWithApp:(Weapps *)app
{
    if (self = [super init]) {
        _app = app;
        _taskModels = [NSMutableDictionary dictionary];
        _taskModelLock = [[NSLock alloc] init];
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.requestSerializer= [AFHTTPRequestSerializer serializer];
        _sessionManager.responseSerializer= [AFHTTPResponseSerializer serializer];
        _networkChangeListeners = [[EventListenerList alloc] init];
        _reachabilityManager = [AFNetworkReachabilityManager sharedManager];
        [_reachabilityManager startMonitoring];
        __weak typeof(self)weakSelf = self;
        [_reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [weakSelf.networkChangeListeners fireListeners:^(id  _Nonnull listener) {
                if ([listener respondsToSelector:@selector(weappsReachabilityStatusDidChange:)]) {
                    [listener weappsReachabilityStatusDidChange:status];
                }
            }];
        }];
        [self setUpBlocks];
    }
    return self;
}


- (void)setUpBlocks
{
    
    //onHeadersReceived回调分发给model处理,只有request和uploadTask请求会收到此回调,downloadTask不会
    @weakify(self)
    [_sessionManager setDataTaskDidReceiveResponseBlock:^NSURLSessionResponseDisposition(NSURLSession * _Nonnull session,
                                                                                         NSURLSessionDataTask * _Nonnull dataTask,
                                                                                         NSURLResponse * _Nonnull response) {
        @strongify(self)
        WANetworkTaskModel* taskModel = [self taskModelByKey:@(dataTask.taskIdentifier)];
        if (taskModel == nil) {
            WALOG(@"|didRecvResponse... task(%tu) NOT found", dataTask.taskIdentifier);
            return NSURLSessionResponseCancel;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            taskModel.state = WANetworkTaskStateError;
            taskModel.errMsg = [NSString stringWithFormat:@"response should be NSHTTPURLResponse instead of %@", NSStringFromClass([httpResponse class])];
            return NSURLSessionResponseCancel;
        }
        //状态改为WANetworkTaskStateReceivedHeader。downloadTask收不到DidReceiveResponse回调，需要根据此状态来判断
        taskModel.state = WANetworkTaskStateReceivedHeader;
        taskModel.statusCode = httpResponse.statusCode;
        taskModel.headers = httpResponse.allHeaderFields;
    
        NSDictionary *result = @{
                                taskModel.taskIdKey: @(taskModel.task.taskIdentifier),
                                @"state": @"headersReceived",
                                @"statusCode": @(taskModel.statusCode),
                                @"header": taskModel.headers ?: @{},
                                };
        [taskModel doHeadersReceivedcallbackWithResult:result];
        return NSURLSessionResponseAllow;
    }];
    
    //DownloadTaskDidWriteData回调，downlaodTask需要在此处理headerReceiced回调和progressUpdate回调
    [_sessionManager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session,
                                                        NSURLSessionDownloadTask * _Nonnull downloadTask,
                                                        int64_t bytesWritten, int64_t totalBytesWritten,
                                                        int64_t totalBytesExpectedToWrite) {
        @strongify(self)
        WANetworkTaskModel* model = [self taskModelByKey:@(downloadTask.taskIdentifier)];
        if (model == nil || ![model isKindOfClass:[WANetworkDownlaodTaskModel class]]) {
            WALOG(@"|didWriteData... task(%tu) NOT found", downloadTask.taskIdentifier);
            return;
        }
        //下载任务还没调用receivedHeader回调
        if (model.state == WANetworkTaskStateSending) {
            do {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)downloadTask.response;
                if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                    // 都收不到httpResponse了，直接失败
                    model.state = WANetworkTaskStateError;
                    model.errMsg = [NSString stringWithFormat:@"response should be NSHTTPURLResponse instead of %@", NSStringFromClass([httpResponse class])];
                    break;
                }
                
                // 转换状态
                model.state = WANetworkTaskStateReceivedHeader;
                model.headers = httpResponse.allHeaderFields;
                model.statusCode = httpResponse.statusCode;
                
                NSDictionary *result = @{
                                        model.taskIdKey: @(model.task.taskIdentifier),
                                        @"state": @"headersReceived",
                                        @"statusCode": @(model.statusCode),
                                        @"header": model.headers ?: @{},
                                        };
                [model doHeadersReceivedcallbackWithResult:result];
            } while (0);
        }
        //下载任务已完成receivedHeader回调
        do {
            //若不是WANetworkTaskModel类型，返回
            if (![model isKindOfClass:[WANetworkDownlaodTaskModel class]]) {
                break;
            }
            BOOL shouldRecvData = NO;
            switch (model.state) {
                case WANetworkTaskStateReceivedHeader:
                case WANetworkTaskStateReceivedData:
                    shouldRecvData = YES;
                    break;
                default:
                    shouldRecvData = NO;
                    break;
            }
            if (!shouldRecvData) {
                break;
            }
            
            // 更改状态为接收数据
            model.state = WANetworkTaskStateReceivedData;
            
            NSInteger progressInInteger = (NSInteger)(totalBytesWritten * 100.0 / totalBytesExpectedToWrite);
            NSDictionary *result = @{
                                    model.taskIdKey: @(model.task.taskIdentifier),
                                    @"progress": @(progressInInteger),
                                    @"totalBytesWritten": @(totalBytesWritten),
                                    @"totalBytesExpectedToWrite": @(totalBytesExpectedToWrite),
                                    };
            WALOG(@"progress:%ld ||totalBytesWritten: %lld || totalBytesExpectedToWrite: %lld",(long)progressInInteger,totalBytesWritten,totalBytesExpectedToWrite);
            WANetworkDownlaodTaskModel *downloadTaskModel = (WANetworkDownlaodTaskModel *)model;
            [downloadTaskModel doDownloadProgressCallbackWithResult:result];
        } while (0);
    }];
    
    //uploadTaskDidSendBodyData回调，uploadTask需要在此处理updateProgress回调
    [_sessionManager setTaskDidSendBodyDataBlock:^(NSURLSession * _Nonnull session,
                                                   NSURLSessionTask * _Nonnull task,
                                                   int64_t bytesSent, int64_t totalBytesSent,
                                                   int64_t totalBytesExpectedToSend) {
        @strongify(self)
        if ([task isKindOfClass:[NSURLSessionUploadTask class]]) {
            WANetworkUploadTaskModel* model = (WANetworkUploadTaskModel *)[self taskModelByKey:@(task.taskIdentifier)];
            if (model == nil || ![model isKindOfClass:[WANetworkUploadTaskModel class]]) {
                WALOG(@"|didSendBody... task(%tu) NOT found", task.taskIdentifier);
                return;
            }
            
            NSInteger progress = (NSInteger)(totalBytesSent * 100.0 / totalBytesExpectedToSend);
            NSDictionary *resultDic = @{
                                         model.taskIdKey: @(model.task.taskIdentifier),
                                         @"progress": @(progress),
                                         @"totalBytesSent": @(totalBytesSent),
                                         @"totalBytesExpectedToSend": @(totalBytesExpectedToSend),
                                         };
            WALOG(@"progress:%ld ||totalBytesSent: %lld || totalBytesExpectedToSend: %lld",(long)progress,totalBytesSent,totalBytesExpectedToSend);
            [model doUploadProgressCallbackWithResult:resultDic];
        }
    }];
}


- (NSNumber *)dataTaskWithRequest:(NSURLRequest *)request
                     responseType:(NSString *)responseType
                          webView:(WebView *)webView
                completionHandler:(void (^)(BOOL success,
                                            NSDictionary *_Nullable result,
                                            NSError * _Nullable error))completionHandler
{
    WANetworkTaskModel *model = [[WANetworkTaskModel alloc] init];
    model.responseType = responseType;
    model.state = WANetworkTaskStateSending;
    [model.webViews addListener:webView];
    [self addLifeCycleManager:webView withModel:model];
    @weakify(model)
    @weakify(self)
    NSURLSessionDataTask *task = [_sessionManager dataTaskWithRequest:request
                          uploadProgress:nil
                        downloadProgress:nil
                       completionHandler:^(NSURLResponse * _Nonnull response,
                                           id  _Nullable responseObject,
                                           NSError * _Nullable error) {
        @strongify(model)
        @strongify(self)
        if (!error) {
            if (completionHandler) {
                NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:model.headers forURL:request.URL];
                NSMutableArray *cookiesObject = [NSMutableArray array];
                for (NSHTTPCookie *cookie in cookies) {
                    if (cookie.name && cookie.value) {
                        [cookiesObject addObject:[NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value]];
                    }
                }
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                id respData = [NSNull null];
                //若responseObject为NSData类型则转为utf8编码string
                if ([responseObject isKindOfClass:[NSData class]]) {
                    // 尝试转utf8
                    respData = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                    
                } else {
                    if (responseObject) {
                        respData = responseObject;
                    }
                }
                kWA_DictSetObjcForKey(result, @"data", respData);
                kWA_DictSetObjcForKey(result, @"statusCode", @(model.statusCode));
                kWA_DictSetObjcForKey(result, @"header", model.headers);
                kWA_DictSetObjcForKey(result, @"cookies", cookiesObject);
                kWA_DictSetObjcForKey(result, @"profile", @{});

                completionHandler(YES, result,nil);
            }
        } else {
            if (completionHandler) {
                if (model.errMsg) {
                    //若errMsg有内容使用errMsg
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                    dic[NSLocalizedDescriptionKey] = model.errMsg;
                    completionHandler(NO, nil, [NSError errorWithDomain:error.domain code:error.code userInfo:dic]);
                } else {
                    completionHandler(NO, nil, error);
                }
            }
        }
        [model cleanWebView:webView];
        [self removeTaskModelByKey:@(model.task.taskIdentifier)];
    }];
    model.task = task;
    [self addTaskModel:model withKey:@(task.taskIdentifier)];
    [task resume];
    return @(task.taskIdentifier);
}


- (NSNumber *)downloadTaskWithRequest:(NSURLRequest *)request
                                 path:(NSString *)path
                              webView:(WebView *)webView
                    completionHandler:(void (^)(BOOL success,
                                                NSDictionary *_Nullable result,
                                                NSError * _Nullable error))completionHandler
{

    WANetworkDownlaodTaskModel *model = [[WANetworkDownlaodTaskModel alloc] init];
    model.filePath = path;
    model.state = WANetworkTaskStateSending;
    [model.webViews addListener:webView];
    [self addLifeCycleManager:webView withModel:model];
    @weakify(model)
    @weakify(self)
    NSURLSessionDownloadTask *task = [_sessionManager downloadTaskWithRequest:request
                                                                     progress:nil
                                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath,
                                                                                                NSURLResponse * _Nonnull response)
    {
        if (path) {
            return [NSURL fileURLWithPath:path];
        }
        return targetPath;
    }
                                                            completionHandler:^(NSURLResponse * _Nonnull response,
                                                                                NSURL * _Nullable filePath,
                                                                                NSError * _Nullable error) {
        @strongify(model)
        @strongify(self)
        if (!error) {
            if (completionHandler) {
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                if (model.filePath) {
                    kWA_DictSetObjcForKey(result, @"filePath", model.filePath);
                } else {
                    kWA_DictSetObjcForKey(result, @"tempFilePath", [filePath path]);
                }
                kWA_DictSetObjcForKey(result, @"statusCode", @(model.statusCode));
                kWA_DictSetObjcForKey(result, @"profile", @{});
                completionHandler(YES, result, nil);
            }
        } else {
            if (completionHandler) {
                if (model.errMsg) {
                    //若errMsg有内容使用errMsg
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                    dic[NSLocalizedDescriptionKey] = model.errMsg;
                    completionHandler(NO, nil, [NSError errorWithDomain:error.domain code:error.code userInfo:dic]);
                } else {
                    completionHandler(NO, nil, error);
                }
            }
        }
        [model cleanWebView:webView];
        [self removeTaskModelByKey:@(model.task.taskIdentifier)];
    }];
    model.task = task;
    [self addTaskModel:model withKey:@(task.taskIdentifier)];
    [task resume];
    return @(task.taskIdentifier);
}


- (NSNumber *)uploadTaskWithRequest:(NSURLRequest *)request
                               from:(NSURL *)URL
                            webView:(WebView *)webView
                  completionHandler:(void (^)(BOOL success,
                                              NSDictionary *_Nullable result,
                                              NSError * _Nullable error))completionHandler
{
    WANetworkUploadTaskModel *model = [[WANetworkUploadTaskModel alloc] init];
    [model.webViews addListener:webView];
    [self addLifeCycleManager:webView withModel:model];
    @weakify(model)
    @weakify(self)
    NSURLSessionUploadTask *task = [_sessionManager uploadTaskWithRequest:request
                                                                 fromFile:URL
                                                                 progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response,
                          id  _Nullable responseObject,
                          NSError * _Nullable error) {
        @strongify(model)
        @strongify(self)
        if (!error) {
            if (completionHandler) {
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                kWA_DictSetObjcForKey(result, @"data", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                kWA_DictSetObjcForKey(result, @"statusCode", @(model.statusCode));
                completionHandler(YES, result, nil);
            }
        } else {
            if (completionHandler) {
                if (model.errMsg) {
                    //若errMsg有内容使用errMsg
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                    dic[NSLocalizedDescriptionKey] = model.errMsg;
                    completionHandler(NO, nil, [NSError errorWithDomain:error.domain code:error.code userInfo:dic]);
                } else {
                    completionHandler(NO, nil, error);
                }
            }
        }
        [model cleanWebView:webView];
        [self removeTaskModelByKey:@(model.task.taskIdentifier)];
    }];
    
    model.task = task;
    [self addTaskModel:model withKey:@(task.taskIdentifier)];
    [task resume];
    return @(task.taskIdentifier);
}


- (NSNumber *)uploadTaskWithRequest:(NSURLRequest *)request
                           fromData:(NSData *)fromData
                            webView:(WebView *)webView
                  completionHandler:(void (^)(BOOL success,
                                              NSDictionary *_Nullable result,
                                              NSError * _Nullable error))completionHandler
{
    WANetworkUploadTaskModel *model = [[WANetworkUploadTaskModel alloc] init];
    [model.webViews addListener:webView];
    [self addLifeCycleManager:webView withModel:model];
    @weakify(model)
    @weakify(self)
    NSURLSessionUploadTask *task = [_sessionManager uploadTaskWithRequest:request
                                                                 fromData:fromData
                                                                 progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } completionHandler:^(NSURLResponse * _Nonnull response,
                          id  _Nullable responseObject,
                          NSError * _Nullable error) {
        @strongify(model)
        @strongify(self)
        if (!error) {
            if (completionHandler) {
                NSMutableDictionary *result = [NSMutableDictionary dictionary];
                kWA_DictSetObjcForKey(result, @"data", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]);
                kWA_DictSetObjcForKey(result, @"statusCode", @(model.statusCode));
                completionHandler(YES, result, nil);
            }
        } else {
            if (completionHandler) {
                if (model.errMsg) {
                    //若errMsg有内容使用errMsg
                    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
                    dic[NSLocalizedDescriptionKey] = model.errMsg;
                    completionHandler(NO, nil, [NSError errorWithDomain:error.domain code:error.code userInfo:dic]);
                } else {
                    completionHandler(NO, nil, error);
                }
            }
        }
        [model cleanWebView:webView];
        [self removeTaskModelByKey:@(model.task.taskIdentifier)];
    }];
    
    model.task = task;
    [self addTaskModel:model withKey:@(task.taskIdentifier)];
    [task resume];
    return @(task.taskIdentifier);
}


- (void)abortDataTaskWithIdentifier:(NSNumber *)identifier
                  completionHandler:(void (^)(BOOL success, NSError * _Nullable error))completionHandler
{
    NSParameterAssert(identifier);
    WANetworkTaskModel *model = [self taskModelByKey:identifier];
    //model不存在
    if (!model) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSURLErrorDomain
                                                      code:-1
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"task(%@) NOT found", identifier]
                                                  }]);
        }
        return;
    }
    model.state = WANetworkTaskStateError;
    model.errMsg = @"abort";
    [model.task cancel];
    [self removeTaskModelByKey:@(model.task.taskIdentifier)];
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)abortDownloadTaskWithIdentifier:(NSNumber *)identifier
                      completionHandler:(void (^)(BOOL success,
                                                  NSError * _Nullable error))completionHandler
{
    [self abortDataTaskWithIdentifier:identifier
                    completionHandler:completionHandler];
}

- (void)abortUploadTaskWithIdentifier:(NSNumber *)identifier
                    completionHandler:(void (^)(BOOL success,
                                                NSError * _Nullable error))completionHandler
{
    [self abortDataTaskWithIdentifier:identifier
                    completionHandler:completionHandler];
}


- (void)webView:(WebView *)webView
onRequestHeadersReceived:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkTaskModel *model = [self taskModelByKey:identifier];
    if (!model) {
        WALOG(@"task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView addHeadersReceivedCallback:callback];
    
}

- (void)webView:(WebView *)webView
offRequestHeadersReceived:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkTaskModel *model = [self taskModelByKey:identifier];
    if (!model) {
        WALOG(@"task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView removeHeadersReceivedCallback:callback];
}

- (void)webView:(WebView *)webView
onDownloadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkDownlaodTaskModel *model = (WANetworkDownlaodTaskModel *)[self taskModelByKey:identifier];
    if (!model && ![model isKindOfClass:[WANetworkDownlaodTaskModel class]]) {
        WALOG(@"download task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView addProgressDownloadCallback:callback];
}

- (void)webView:(WebView *)webView
offDownloadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkDownlaodTaskModel *model = (WANetworkDownlaodTaskModel *)[self taskModelByKey:identifier];
    if (!model && ![model isKindOfClass:[WANetworkDownlaodTaskModel class]]) {
        WALOG(@"download task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView removeProgressDownloadCallback:callback];
}

- (void)webView:(WebView *)webView
onUploadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkUploadTaskModel *model = (WANetworkUploadTaskModel *)[self taskModelByKey:identifier];
    if (!model && ![model isKindOfClass:[WANetworkUploadTaskModel class]]) {
        WALOG(@"upload task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView addProgressUplaodCallback:callback];
}
    

- (void)webView:(WebView *)webView
offUploadTaskProgress:(NSString *)callback
 withIdentifier:(NSNumber *)identifier
{
    NSParameterAssert(identifier);
    NSParameterAssert(webView);
    NSParameterAssert(callback);
    WANetworkUploadTaskModel *model = (WANetworkUploadTaskModel *)[self taskModelByKey:identifier];
    if (!model && ![model isKindOfClass:[WANetworkUploadTaskModel class]]) {
        WALOG(@"upload task with identifer:%@ not found",identifier);
        return;
    }
    [model webView:webView removeProgressUploadCallback:callback];
}


- (void)addReachabilityStatusChangeListener:(id<WeappsReachabilityProtocol>)listener
{
    [_networkChangeListeners addListener:listener];
}

- (void)removeReachabilityStatusChangeListener:(id<WeappsReachabilityProtocol>)listener
{
    [_networkChangeListeners removeListener:listener];
}

//随着webView的销毁，删除对应model删除对应的webView
- (void)addLifeCycleManager:(WebView *)webView withModel:(WANetworkTaskModel *)model{
    @weakify(model)
    [webView addViewWillDeallocBlock:^(WebView * webView) {
        @strongify(model);
        [model cleanWebView:webView];
    }];
}

- (void)addTaskModel:(WANetworkTaskModel *)model withKey:(NSNumber *)key
{
    NSParameterAssert(model);
    NSParameterAssert(key);
    [_taskModelLock lock];
    _taskModels[key] = model;
    [_taskModelLock unlock];
}

- (WANetworkTaskModel *)taskModelByKey:(NSNumber *)key
{
    NSParameterAssert(key);
    WANetworkTaskModel *task = nil;
    [_taskModelLock lock];
    task = _taskModels[key];
    [_taskModelLock unlock];
    return task;
}

- (void)removeTaskModelByKey:(NSNumber *)key
{
    NSParameterAssert(key);
    [_taskModelLock lock];
    [_taskModels removeObjectForKey:key];
    [_taskModelLock unlock];
}



@end
