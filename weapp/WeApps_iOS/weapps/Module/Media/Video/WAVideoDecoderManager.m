//
//  WAVideoDecoderManager.m
//  weapps
//
//  Created by tommywwang on 2020/8/21.
//  Copyright © 2020 tencent. All rights reserved.
//

//单页面ap，不考虑多页面webView了
#import "WAVideoDecoderManager.h"
#import "WKWebViewHelper.h"

@interface WAVideoDecoderModel : NSObject

@property (nonatomic, strong) WAVideoDecoder *decoder;
@property (nonatomic, weak) WebView *webView;
@property (nonatomic, strong) NSMutableArray *startCallbacks;
@property (nonatomic, strong) NSMutableArray *stopCallbacks;
@property (nonatomic, strong) NSMutableArray *seekCallbacks;
@property (nonatomic, strong) NSMutableArray *bufferChangeCallbacks;
@property (nonatomic, strong) NSMutableArray *endedCallbacks;
@property (nonatomic, strong) NSLock *lock;

- (void)onStartCallback:(NSString *)callback;

- (void)onStopCallback:(NSString *)callback;

- (void)onSeekCallback:(NSString *)callback;

- (void)onBufferChangerCallback:(NSString *)callback;

- (void)onEndedCallback:(NSString *)callback;

- (void)offStartCallback:(NSString *)callback;

- (void)offStopCallback:(NSString *)callback;

- (void)offSeekCallback:(NSString *)callback;

- (void)offBufferChangerCallback:(NSString *)callback;

- (void)offEndedCallback:(NSString *)callback;

- (void)doStartCallbacksWithSize:(CGSize)size;

- (void)doStopCallbacks;

- (void)doSeekCallbacksWithPosition:(CGFloat)position;

- (void)doBufferChangeCallbacks;

- (void)doEndedCallbacks;

@end


@implementation WAVideoDecoderModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSLock alloc] init];
        _startCallbacks = [NSMutableArray array];
        _stopCallbacks = [NSMutableArray array];
        _seekCallbacks = [NSMutableArray array];
        _bufferChangeCallbacks = [NSMutableArray array];
        _endedCallbacks = [NSMutableArray array];
    }
    return self;
}

- (void)onStartCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_startCallbacks addObject:callback];
        [_lock unlock];
    }
}

- (void)onStopCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_stopCallbacks addObject:callback];
        [_lock unlock];
    }
}

- (void)onSeekCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_seekCallbacks addObject:callback];
        [_lock unlock];
    }
}

- (void)onBufferChangerCallback:(NSString *)callback
{
    
    if (callback) {
        [_lock lock];
        [_bufferChangeCallbacks addObject:callback];
        [_lock unlock];
    }
}

- (void)onEndedCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_endedCallbacks addObject:callback];
        [_lock unlock];
    }
    
}

- (void)offStartCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_startCallbacks removeObject:callback];
        [_lock unlock];
    }
}

- (void)offStopCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_stopCallbacks removeObject:callback];
        [_lock unlock];
    }
}

- (void)offSeekCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_seekCallbacks removeObject:callback];
        [_lock unlock];
    }
}

- (void)offBufferChangerCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_bufferChangeCallbacks removeObject:callback];
        [_lock unlock];
    }
}

- (void)offEndedCallback:(NSString *)callback
{
    if (callback) {
        [_lock lock];
        [_endedCallbacks removeObject:callback];
        [_lock unlock];
    }
}

- (void)doStartCallbacksWithSize:(CGSize)size
{
    [self doCallbacks:self.startCallbacks withResult:@{
        @"width"    : @(size.width),
        @"height"   : @(size.height)
    }];
}

- (void)doStopCallbacks
{
    [self doCallbacks:self.stopCallbacks withResult:nil];
}

- (void)doSeekCallbacksWithPosition:(CGFloat)position
{
    [self doCallbacks:self.seekCallbacks withResult:@{
        @"position": @(position)
    }];
}

- (void)doBufferChangeCallbacks
{
    [self doCallbacks:self.bufferChangeCallbacks withResult:nil];
}

- (void)doEndedCallbacks
{
    [self doCallbacks:self.endedCallbacks withResult:nil];
}

#pragma mark - private
- (void)doCallbacks:(NSArray *)callbacks withResult:(NSDictionary *)result
{
    [_lock lock];
    for (NSString *callback in callbacks) {
        [WKWebViewHelper successWithResultData:result webView:self.webView callback:callback];
    }
    [_lock unlock];
}

@end

@interface WAVideoDecoderManager ()

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, WAVideoDecoderModel *> *modelDict;

@end


@implementation WAVideoDecoderManager


- (instancetype)init
{
    self = [super init];
    if (self) {
        _modelDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSNumber *)createMediaContainerWithWebView:(WebView *)webView
{
    WAVideoDecoder *decoder = [[WAVideoDecoder alloc] init];
    WAVideoDecoderModel *model = [[WAVideoDecoderModel alloc] init];
    model.decoder = decoder;
    model.webView = webView;
    _modelDict[decoder.decoderId] = model;
    @weakify(model)
    decoder.didStartBlock = ^(CGSize size) {
        @strongify(model)
        [model doStartCallbacksWithSize:size];
    };
    decoder.didStopBlock = ^{
      @strongify(model)
        [model doStopCallbacks];
    };
    decoder.didSeekBlock = ^(CGFloat position) {
        @strongify(model)
        [model doSeekCallbacksWithPosition:position];
    };
    decoder.didBufferChangeBlock = ^{
      @strongify(model)
        [model doBufferChangeCallbacks];
    };
    decoder.didEndBlock = ^{
      @strongify(model)
        [model doEndedCallbacks];
    };
    return decoder.decoderId;
}

- (void)startWithDecoder:(NSNumber *)decoderId
                 webView:(WebView *)webView
                  source:(NSString *)source
                  inMode:(WAVideoDecoderMode)mode
       completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model.decoder startWithSource:source
                              mode:mode
                 completionHandler:completionHandler];
}

- (void)stopWithDecoder:(NSNumber *)decoderId
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model.decoder stopWithCompletionHandler:completionHandler];
}

- (void)seekTo:(NSNumber *)position withDecoder:(NSNumber *)decoderId
    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model.decoder seekTo:[position floatValue] completionHandler:completionHandler];
}

- (void)removeDecoder:(NSNumber *)decoderId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:completionHandler];
    if (!model) {
        return;
    }
    [model.decoder stopWithCompletionHandler:nil];
    [_modelDict removeObjectForKey:decoderId];
    
}

- (NSDictionary *)getFrameDataWithDecoder:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = _modelDict[decoderId];
    if (!model) {
        return nil;
    }
    return [model.decoder getFrameData];
}


- (void)onStartCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model onStartCallback:callback];
}

- (void)onStopCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model onStopCallback:callback];
}

- (void)onSeekCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model onSeekCallback:callback];
}

- (void)onBufferChangeCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model onBufferChangerCallback:callback];
}

- (void)onEndCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model onEndedCallback:callback];
}

- (void)offStartCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model offStartCallback:callback];
}

- (void)offStopCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model offStopCallback:callback];
}

- (void)offSeekCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model offSeekCallback:callback];
}

- (void)offBufferChangeCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model offBufferChangerCallback:callback];
}

- (void)offEndCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId
{
    WAVideoDecoderModel *model = [self getDecoderModelWithId:decoderId completionHandler:nil];
    if (!model) {
        return;
    }
    [model offEndedCallback:callback];
}


#pragma mark - private

- (WAVideoDecoderModel *)getDecoderModelWithId:(NSNumber *)decoderId
                             completionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    WAVideoDecoderModel *model = _modelDict[decoderId];
    if (!model) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find VideoDecoder with id {%@}", decoderId]
            }]);
        }
    }
    return model;
}

@end
