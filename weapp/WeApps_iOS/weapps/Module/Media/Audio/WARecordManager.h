//
//  WARecordManager.h
//  weapps
//
//  Created by tommywwang on 2020/7/9.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebView.h"
#import "MARecordTools.h"
#import "WACallbackModel.h"

NS_ASSUME_NONNULL_BEGIN


@interface WARecordConfig : NSObject

/// 录音长度，单位ms
@property (nonatomic, assign) NSTimeInterval duration;

/// 采样率
@property (nonatomic, assign) Float32 sampleRate;

/// 录音通道
@property (nonatomic, assign) UInt32 numberOfChannels;

/// 编码率
@property (nonatomic, assign) UInt32 encodeBitRate;

/// 音频格式
@property (nonatomic, copy) NSString *format;

/// 指定帧大小，单位 KB
@property (nonatomic, assign) UInt32 frameSize;

/// 录音的音频输入源
@property (nonatomic, copy) NSString *audioSource;

@end



@class Weapps;
/// 录音管理类
@interface WARecordManager : WACallbackModel <MARecordToolsDelegate>

- (instancetype)initWithWeapps:(Weapps *)app;

/// 根据配置开始录音
/// @param config 配置信息
/// /// @param webView 当前请求webView
/// @param completionHandler 完成回调
- (void)startWithConfig:(WARecordConfig *)config
              inWebView:(WebView *)webView
      completionHandler:(void (^)(BOOL success, NSDictionary *_Nullable result, NSError * _Nullable error))completionHandler;


/// 暂停
- (void)pause;

/// 恢复
- (void)resume;

/// 停止
- (void)stop;

/// 添加监听start回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onStart:(NSString *)callback;

/// 移除监听start回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offStart:(NSString *)callback;

/// 添加监听stop回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onStop:(NSString *)callback;

/// 移除监听stop回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offStop:(NSString *)callback;

/// 添加监听pause回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onPause:(NSString *)callback;

/// 移除监听pause回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offPause:(NSString *)callback;

/// 添加监听resume回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onResume:(NSString *)callback;

/// 移除监听resume回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offResume:(NSString *)callback;

/// 添加监听error
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onError:(NSString *)callback;

/// 移除监听error回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offError:(NSString *)callback;

/// 添加监听interruptBegin回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onInterruptionBegin:(NSString *)callback;

/// 移除监听interruptBegin回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offInterruptionBegin:(NSString *)callback;

/// 添加监听interruptEnd回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onInterruptionEnd:(NSString *)callback;

/// 移除监听interruptEnd回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offInterruptionEnd:(NSString *)callback;

/// 添加监听frameRecorded回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView onFrameRecorded:(NSString *)callback;

/// 移除监听frameRecorded回调
/// @param webView 当前请求webView，会被弱引用
/// @param callback 回调函数名
- (void)webView:(WebView *)webView offFrameRecorded:(NSString *)callback;


@end

NS_ASSUME_NONNULL_END
