//
//  WACameraManager.m
//  weapps
//
//  Created by tommywwang on 2020/7/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WACameraManager.h"
#import "MACameraView.h"
#import "WKWebViewHelper.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "NSData+Base64.h"
#import "PathUtils.h"
#import "WAMediaUtils.h"
#import "FileUtils.h"


@interface WACameraModel : NSObject
@property (nonatomic, weak) MACameraView *cameraView;
@property (nonatomic, assign) BOOL enableListenning; //是否监听
@property (nonatomic, weak) WebView *webView; //一个webView只能有一个cameraView
@property (nonatomic, copy) NSString *onStopCallback;
@property (nonatomic, copy) NSString *onErrorCallback;
@property (nonatomic, copy) NSString *onInitDoneCallback;
@property (nonatomic, copy) NSString *onScanCodeCallback;
@property (nonatomic, copy) NSString *onCameraFrame;
@property (nonatomic, copy) NSString *timeoutCallback;
@end

@implementation WACameraModel

@end

@interface WACameraManager ()
{
    __weak Weapps *_app;
    WACameraModel *_model;
}
@end

@implementation WACameraManager

- (id)initWithWeapps:(Weapps *)app
{
    if (self = [super init]) {
        _app = app;
    }
    return self;
}

- (void)setCameraState:(NSDictionary *)state
{
    if (!_model || !state) {
        return;
    }
    NSString *onStop = state[@"bindstop"];
    NSString *onError = state[@"binderror"];
    NSString *onInitDone = state[@"bindinitdone"];
    NSString *onScanCode = state[@"bindscancode"];
    NSString *devicePosition = state[@"devicePosition"];
    NSString *flash = state[@"flash"];
    NSString *frameSize = state[@"frameSize"];
    if (onStop) {
        _model.onStopCallback = onStop;
    }
    if (onError) {
        _model.onErrorCallback = onError;
    }
    if (onInitDone) {
        _model.onInitDoneCallback = onInitDone;
    }
    if (onScanCode) {
        _model.onScanCodeCallback = onScanCode;
    }
    NSArray *devicePositions = @[@"back", @"front"];
    if ([devicePositions containsObject:devicePosition]) {
        _model.cameraView.devicePosition = devicePosition;
    }
    NSArray *flashs = @[@"auto", @"on", @"off"];
    if ([flashs containsObject:flash]) {
        _model.cameraView.flash = flash;
    }
    NSArray *frameSizes = @[@"small", @"medium", @"large"];
    if ([frameSizes containsObject:frameSize]) {
        _model.cameraView.frameSize = frameSize;
    }
}

- (void)createCameraViewWithWebView:(WebView *)webview
                           position:(NSDictionary *)position
                              state:(NSDictionary *)state
                    completionBlock:(void(^)(BOOL success, NSError *error))block
{
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webview withParams:position];
    if (!container) {
        if (block) {
            block(NO, [NSError errorWithDomain:@"createCameraView" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find camere container in webView"
            }]);
        }
        return ;
    }
    NSString *onStop = state[@"bindstop"];
    NSString *onError = state[@"binderror"];
    NSString *onInitDone = state[@"bindinitdone"];
    NSString *onScanCode = state[@"bindscancode"];
    NSString *resolution = state[@"resolution"]?: @"medium";
    WACameraModel *model = [[WACameraModel alloc] init];
    @weakify(webview)
    MACameraView *cameraView = [[MACameraView alloc] initCameraWithFrame:container.bounds
                                                              resolution:resolution
                                                                  result:^(BOOL success, CGFloat maxZoomFator) {
        @strongify(webview)
        if (success) {
            if (onInitDone) {
                [WKWebViewHelper successWithResultData:@{
                    @"maxZoom": @(maxZoomFator)
                }
                                               webView:webview
                                              callback:onInitDone];
            }
        } else {
            if (onError) {
                [WKWebViewHelper successWithResultData:nil
                                               webView:webview
                                              callback:onError];
            }
        }
    }];
    @weakify(model)
    @weakify(self)
    [cameraView addViewWillDeallocBlock:^(WAContainerView * _Nonnull containerView) {
        @strongify(model)
        @strongify(self)
        if (model) {
            [model.cameraView clean];
            self->_model = nil;
        }
    }];
    
    cameraView.mode = state[@"mode"] ?: @"normal";
    cameraView.flash = state[@"flash"] ?: @"auto";
    cameraView.devicePosition = state[@"devicePosition"] ?: @"back";
    cameraView.frameSize = state[@"frameSize"] ?: @"medium";
    cameraView.videoFrameBlock = ^(CGFloat width, CGFloat height, NSData *bytes) {
        @strongify(webview)
        @strongify(model)
        if (model.onCameraFrame && model.enableListenning) {
            [WKWebViewHelper successWithResultData:@{
                @"width"    : @(width),
                @"height"   : @(height),
                @"data"     : [bytes base64String] ?: @""
            }
                                           webView:webview
                                          callback:model.onCameraFrame];
        }
    };
    //录像结束回调。录像时间30内没有stopRecord会自动停止录像，并回调
    cameraView.videoTimeoutBlock = ^(BOOL success, NSError *error, NSURL *videoURL, NSString *thumbPath) {
        //若设置了超时回调，回运行回调
        @strongify(model)
        @strongify(webview)
        if (model.timeoutCallback) {
            if (success) {
                NSDictionary *result = nil;
                if (success) {
                    result = @{
                        @"tempThumbPath": thumbPath ?: @"",
                        @"tempVideoPath": videoURL.path ?: @""
                    };
                    [WKWebViewHelper successWithResultData:result
                                                   webView:webview
                                                  callback:model.timeoutCallback];
                }
            } else {
                [WKWebViewHelper failWithError:error webView:webview callback:model.timeoutCallback];
            }
        }
    };
    //捕获二维码回调
    if (kStringEqualToString(cameraView.mode, @"scanCode")) {
        cameraView.scanCodeBlock = ^(NSString *result, NSString *type) {
            @strongify(model)
            @strongify(webview)
            if (model.onScanCodeCallback) {
                NSDictionary *dic = nil;
                if (kStringEqualToString(type, @"QR_CODE")) {
                    NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                    NSString *resultBase64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
                    dic = @{
                        @"result": result,
                        @"type": type,
                        @"charSet": @"UTF-8",
                        @"rawData": resultBase64 ?: @""
                    };
                } else {
                    dic = @{
                        @"result": result,
                        @"type": type,
                    };
                }
                [WKWebViewHelper successWithResultData:dic
                                               webView:webview
                                              callback:model.onScanCodeCallback];
            }
        };
    }

    [cameraView startRunning];
    //自动适配camera DOM节点的大小
    container.boundsChangeBlock = ^(CGRect rect) {
        cameraView.frame = rect;
    };
    [container insertSubview:cameraView atIndex:0];
    
    model.webView = webview;
    model.cameraView = cameraView;
    model.onStopCallback = onStop;
    model.onInitDoneCallback = onInitDone;
    model.onErrorCallback = onError;
    model.onScanCodeCallback = onScanCode;
    _model = model;
}


- (void)setCameraZoom:(CGFloat)zoom
    completionHandler:(void (^)(BOOL, NSDictionary *, NSError *))completionHandler
{
    MACameraView *camera = [self findCameraDomain:@"setZoom"
                                            block:completionHandler];
    if (!camera) {
        return;
    }
    [camera setZoom:zoom withCompletion:^(BOOL success, NSError *error) {
        if (success && completionHandler) {
            completionHandler(YES, nil, nil);
        } else {
            completionHandler(NO , nil, error);
        }
    }];
}


- (void)setCameraFlash:(NSString *)flash
     completionHandler:(void (^)(BOOL, NSDictionary *, NSError *))completionHandler
{
    MACameraView *camera = [self findCameraDomain:@"setFlash"
                                            block:completionHandler];
    if (!camera) {
        return;
    }
    [camera setupFlash:flash];
    if (completionHandler) {
        completionHandler(YES, nil ,nil);
    }
}

- (void)setCameraDevicePosition:(NSString *)devicePosition
              completionHandler:(void (^)(BOOL, NSDictionary *, NSError *))completionHandler
{
    MACameraView *camera = [self findCameraDomain:@"setDevicePosition"
                                            block:completionHandler];
    if (!camera) {
        return;
    }
    [camera switchCamera:devicePosition];
}

- (void)takePhotoWithQuality:(NSString *)quality
           completionHandler:(void(^)(BOOL success,
                                       NSDictionary *result,
                                       NSError *error))completionHandler
{
    MACameraView *camera = [self findCameraDomain:@"takePhoto"
                                            block:completionHandler];
    if (!camera) {
        return;
    }
    camera.photoPath = [self createPhotoPath];
    camera.photoResultBlock = ^(BOOL success, NSError *error, NSString *photoPath) {
        if (success && completionHandler) {
            completionHandler(success, @{@"tempImagePath": photoPath}, nil);
        } else if (!success && completionHandler) {
            completionHandler(success, nil, error);
        }
    };
    [camera takePhotoWithQuality:quality];
}

- (void)startRecordWithTimeoutCallback:(NSString *)timeoutCallback
                     completionHandler:(void (^)(BOOL, NSDictionary *, NSError * ))completionHandler
{
    if (!_model.cameraView) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"startRecord" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find camera with camera"]
            }]);
        }
        return;
    }
    _model.timeoutCallback = timeoutCallback;
    NSString *videoPath = nil;
    NSString *thumbPath = nil;
    [self createVideoPath:&videoPath andThumbPath:&thumbPath];
    _model.cameraView.videoPath = videoPath;
    _model.cameraView.thumbPath = thumbPath;
    [_model.cameraView startRecord];
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

- (void)stopRecordWithCompressed:(BOOL)compressed
               completionHandler:(void (^)(BOOL, NSDictionary * , NSError * ))completionHandler
{
    MACameraView *camera = [self findCameraDomain:@"stopRecord" block:completionHandler];
    if (!camera) {
        return;
    }
    
    if (completionHandler) {
        camera.videoResultBlock = ^(BOOL success, NSError *error, NSURL *videoURL, NSString *thumbPath) {
            if (!success) {
                completionHandler(NO, nil, error);
                return;
            }
            //不用压缩
            WALOG(@"video file size %llu, filePath:%@",[FileUtils getFileSize:[videoURL path]], [videoURL path]);
            if (!compressed) {
                NSDictionary *result = @{
                    @"tempVideoPath": [videoURL path] ?: @"",
                    @"tempThumbPath": thumbPath ?: @""
                };
                completionHandler(success, result, nil);
                return;
            }
            //异步压缩
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                uint32_t random =  arc4random();
                NSString *outPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"video_%u.mp4",random]];
                [WAMediaUtils compressVideo:videoURL
                                     output:[NSURL fileURLWithPath:outPath]
                                withQuality:WAVideoQualityTypeMedium
                                    bitRate:0
                                        fps:0
                            resolutionScale:0
                                   complete:^(BOOL success, NSError * _Nonnull err) {
                    
                    if (success) {
                        //删除源文件
                        [FileUtils deleteFile:videoURL.path error:nil];
                        NSDictionary *result = @{
                            @"tempVideoPath": outPath,
                            @"tempThumbPath": thumbPath ?: @""
                        };
                        completionHandler(success, result, nil);
                    } else {
                        completionHandler(success, nil, error);
                    }
                }];
            });
        };
    }
    [camera stopRecord:nil];
}

- (void)startListeningCameraFrameWithCompletionHandler:(void (^)(BOOL, NSDictionary * , NSError *))completionHandler
{
    [self enableListeningCameraFrame:YES
                   completionHandler:completionHandler];
}

- (void)stopListeningCameraFrameWithCompletionHandler:(void (^)(BOOL, NSDictionary * , NSError * ))completionHandler
{
    [self enableListeningCameraFrame:NO
                   completionHandler:completionHandler];
}


- (void)enableListeningCameraFrame:(BOOL)enable
                 completionHandler:(void (^)(BOOL, NSDictionary * , NSError * ))completionHandler
{
    if (!_model) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:enable ? @"start" : @"stop" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find camera with camera"]
            }]);
        }
        return;
    }
    if (_model.onCameraFrame) {
        _model.enableListenning = enable;
        if (completionHandler) {
            completionHandler(YES, nil, nil);
        }
    } else {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find onCameraFrame callback, please set onCameraFrame first"
            }]);
        }
    }
}

- (void)onCameraFrame:(NSString *)callback
    completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    if (!_model) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"onCameraFrame" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find camera"]
            }]);
        }
        return;
    }
    _model.onCameraFrame = callback;
    if (completionHandler) {
        completionHandler(YES, nil, nil);
    }
}

- (MACameraView *)findCameraDomain:(NSString *)domain
                             block:(void (^)(BOOL, NSDictionary * , NSError *))block
{
    
    if (!_model.cameraView) {
        if (block) {
            block(NO, nil, [NSError errorWithDomain:domain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find camera"]
            }]);
        }
        return nil;
    }
    return _model.cameraView;
}


- (NSString *)createPhotoPath
{
    return [[PathUtils tempFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"photo_%u.png",arc4random()]];
}


- (void)createVideoPath:(NSString **)videoPath andThumbPath:(NSString **)thumbPath
{
    uint32_t random =  arc4random();
    *videoPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"video_%u.mp4",random]];
    *thumbPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"thumb_%u.png",random]];
}

@end
