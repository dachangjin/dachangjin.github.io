//
//  WARecordManager.m
//  weapps
//
//  Created by tommywwang on 2020/7/9.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WARecordManager.h"
#import "EventListenerList.h"
#import "WebView.h"
#import "WKWebViewHelper.h"
#import "Weapps.h"
#import "QMAAudioSessionHelper.h"
#import "NSData+Base64.h"

@implementation WARecordConfig


@end

@interface WARecordManager () 

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *frameRecordedCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *interruptionBeginCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *interruptionEndnCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *pauseCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *resumeCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *startCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *stopCallbacksDic;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *errorCallbacksDic;

- (void)doFrameRecordedCallbackWithResult:(NSDictionary  *)result;

- (void)doInterruptionBeginCallback;

- (void)doInterruptionEndnCallback;

- (void)doPauseCallback;

- (void)doResumeCallback;

- (void)doStartCallback;

- (void)doStopCallbackWithResult:(NSDictionary  *)result;

- (void)doErrorCallbackWithResult:(NSDictionary  *)result;

@end

@implementation WARecordManager
{
    MARecordTools   *_recordTools;
    Weapps          *_weapps;
    WARecordConfig  *_config;
}


- (instancetype)initWithWeapps:(Weapps *)weapps
{
    self = [super init];
    if (self) {
        _weapps = weapps;
        _recordTools = [[MARecordTools alloc] initWithDelegate:self];
        _frameRecordedCallbacksDic = [NSMutableDictionary dictionary];
        _startCallbacksDic = [NSMutableDictionary dictionary];
        _stopCallbacksDic = [NSMutableDictionary dictionary];
        _pauseCallbacksDic = [NSMutableDictionary dictionary];
        _resumeCallbacksDic = [NSMutableDictionary dictionary];
        _errorCallbacksDic = [NSMutableDictionary dictionary];
        _interruptionBeginCallbacksDic = [NSMutableDictionary dictionary];
        _interruptionEndnCallbacksDic = [NSMutableDictionary dictionary];
    }
    return self;
}



- (void)startWithConfig:(WARecordConfig *)config
              inWebView:(WebView *)webView
      completionHandler:(void (^)(BOOL, NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    _config = config;
    [_recordTools setupWithDuration:config.duration
                         formatType:config.format
                      encodeBitRate:config.encodeBitRate
                          frameSize:config.frameSize
                        audioSource:config.audioSource
                         sampleRate:config.sampleRate
                   numberOfChannels:config.numberOfChannels];
    [_recordTools startWithCompletionHandler:completionHandler];
}

- (void)pause
{
    [_recordTools pause];
}

- (void)resume
{
    [_recordTools resume];
}

- (void)stop
{
    [_recordTools stop];
}


#pragma mark 添加监听，移除监听
- (void)webView:(WebView *)webView onStart:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.startCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offStart:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.startCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onStop:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.stopCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offStop:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.stopCallbacksDic callback:callback];
}


- (void)webView:(WebView *)webView onPause:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.pauseCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offPause:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.pauseCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onResume:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.resumeCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offResume:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.resumeCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onError:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.errorCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offError:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.errorCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onInterruptionBegin:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.interruptionBeginCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offInterruptionBegin:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.interruptionBeginCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onInterruptionEnd:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.interruptionEndnCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offInterruptionEnd:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.interruptionEndnCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView onFrameRecorded:(NSString *)callback
{
    [self webView:webView onEventWithDict:self.frameRecordedCallbacksDic callback:callback];
}

- (void)webView:(WebView *)webView offFrameRecorded:(NSString *)callback
{
    [self webView:webView offEventWithDict:self.frameRecordedCallbacksDic callback:callback];
}

- (void)clearCallbacks
{
    [self.webViews clear];
    [self.lock lock];
    [_startCallbacksDic removeAllObjects];
    [_stopCallbacksDic removeAllObjects];
    [_pauseCallbacksDic removeAllObjects];
    [_resumeCallbacksDic removeAllObjects];
    [_errorCallbacksDic removeAllObjects];
    [_frameRecordedCallbacksDic removeAllObjects];
    [_interruptionEndnCallbacksDic removeAllObjects];
    [_interruptionBeginCallbacksDic removeAllObjects];
    [self.lock unlock];
}

- (void)removeWebView:(WebView *)webView
{
    [self.webViews removeListener:webView];
    NSString *key = [self getKeyByWebView:webView];
    [self.lock lock];
    [_startCallbacksDic removeObjectForKey:key];
    [_stopCallbacksDic removeObjectForKey:key];
    [_pauseCallbacksDic removeObjectForKey:key];
    [_resumeCallbacksDic removeObjectForKey:key];
    [_errorCallbacksDic removeObjectForKey:key];
    [_frameRecordedCallbacksDic removeObjectForKey:key];
    [_interruptionEndnCallbacksDic removeObjectForKey:key];
    [_interruptionBeginCallbacksDic removeObjectForKey:key];
    [self.lock unlock];
}

#pragma mark MARecordToolsDelegate
- (void)onPause
{
    [self doPauseCallback];
}

- (void)onStart
{
    [self doStartCallback];
}

- (void)onResume
{
    [self doResumeCallback];
}

- (void)onError:(NSString *)msg
{
    
    [self doErrorCallbackWithResult:@{
        @"errMsg": msg ?: @"error"
    }];
}

- (void)onInterruptionEnd
{
    [self doInterruptionEndnCallback];
}

- (void)onInterruptionBegin
{
    [self doInterruptionBeginCallback];
}

- (void)onFrameRecorded:(BOOL)isLastFrame frameBuffer:(NSData *)frameBuffer
{
    [self doFrameRecordedCallbackWithResult:@{
        @"isLastFrame"  : @(isLastFrame),
        @"frameBuffer"  : [frameBuffer byteArray]
    }];
}

- (void)onStopWithDuration:(NSTimeInterval)duration tempFilePath:(NSString *)filePath fileSize:(unsigned long long)fileSize
{
    [self doStopCallbackWithResult:@{
        @"tempFilePath" : filePath,
        @"duration"     : @(duration),
        @"fileSize"     : @(fileSize)
    }];
}

#pragma mark 回调相关
- (void)doFrameRecordedCallbackWithResult:(NSDictionary *)result
{
    [self doCallbackInCallbackDict:self.frameRecordedCallbacksDic andResult:result];
}

- (void)doInterruptionBeginCallback
{
    [self doCallbackInCallbackDict:self.interruptionBeginCallbacksDic andResult:nil];
}

- (void)doInterruptionEndnCallback
{
    [self doCallbackInCallbackDict:self.interruptionEndnCallbacksDic andResult:nil];
}

- (void)doPauseCallback
{
    [self doCallbackInCallbackDict:self.pauseCallbacksDic andResult:nil];
}

- (void)doResumeCallback
{
    [self doCallbackInCallbackDict:self.resumeCallbacksDic andResult:nil];
}

- (void)doStartCallback
{
    [self doCallbackInCallbackDict:self.startCallbacksDic andResult:nil];
}

- (void)doStopCallbackWithResult:(NSDictionary  *)result
{
    [self doCallbackInCallbackDict:self.stopCallbacksDic andResult:result];
}

- (void)doErrorCallbackWithResult:(NSDictionary  *)result
{
    [self doCallbackInCallbackDict:self.errorCallbacksDic andResult:result];
}


@end
