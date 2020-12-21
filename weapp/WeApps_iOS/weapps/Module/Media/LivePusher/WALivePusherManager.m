//
//  WALivePusherManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePusherManager.h"
#import "WALivePusher.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "WKWebViewHelper.h"
#import "WAContainerView.h"

@interface WALivePusherManager ()

@property (nonatomic, strong) WALivePusher *pusher;

@end

@implementation WALivePusherManager

- (WALivePusher *)pusher
{
    if (!_pusher) {
        _pusher = [[WALivePusher alloc] init];
    }
    return _pusher;
}

- (void)createLivePusherInWebView:(WKWebView *)webView
                     withPosition:(NSDictionary *)position
                            state:(NSDictionary *)state
                completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webView withParams:position];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createLivePusherContext" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find livePusher container in webView"
            }]);
        }
        NSString *binderror = state[@"binderror"];
        if (binderror) {
            [WKWebViewHelper successWithResultData:@{
                @"errCode"  : @(-1),
                @"errMsg"   : @"can not find livePusher container in webView"
            }
                                           webView:webView
                                          callback:binderror];
        }
        return;
    }
    WAContainerView *view = [[WAContainerView alloc] initWithFrame:container.bounds];
    //自动适配camera DOM节点的大小
    container.boundsChangeBlock = ^(CGRect rect) {
        view.frame = rect;
    };
    [container insertSubview:view atIndex:0];
    self.pusher.webView = webView;
    self.pusher.previewView = view;
    
    [self setLivePusherContextState:state];
}


//开启摄像头渲染
- (void)startPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    if (self.pusher.previewView) {
        [self.pusher startPreview:self.pusher.previewView
        withCompletionHandler:completionHandler];
    } else if (completionHandler){
        completionHandler(NO, nil, [NSError errorWithDomain:@"startPreview" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"can not find livePusher container view, please create livePusher first"
        }]);
    }
}

//关闭摄像头渲染
- (void)stopPreviewWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher stopPreviewWithCompletionHandler:completionHandler];
}

//开始推流
- (void)startPushwithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    if (self.pusher.previewView) {
        [self.pusher startPreview:self.pusher.previewView
            withCompletionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
            if (success) {
                [self.pusher startPushwithCompletionHandler:completionHandler];
            } else {
                completionHandler(success, result, error);
            }
        }];
    } else if (completionHandler){
        completionHandler(NO, nil, [NSError errorWithDomain:@"startPreview" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"can not find livePusher container view, please create livePusher first"
        }]);
    }
    
}

//加入背景音乐
- (void)playBGM:(NSString *)url withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher playBGM:url
   withCompletionHandler:completionHandler];
}

//停止推流
- (void)stopPushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher stopPushWithCompletionHandler:completionHandler];
}

//暂停推流
- (void)pausePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher pausePushWithCompletionHandler:completionHandler];
}

//暂停背景音乐
- (void)pauseBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher pauseBGMWithCompletionHandler:completionHandler];
}

//停止背景音
- (void)stopBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher stopBGMWithCompletionHandler:completionHandler];
}

//恢复推流
- (void)resumePushWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher resumePushWithCompletionHandler:completionHandler];
}

//恢复背景音乐
- (void)resumeBGMWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher resumeBGMWithCompletionHandler:completionHandler];
}

//设置背景音量
- (void)setBGMVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher setBGMVolume:volume withCompletionHandler:completionHandler];
}

//设置麦克风音量
- (void)setMicVolume:(CGFloat)volume withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher setMicVolume:volume
        withCompletionHandler:completionHandler];
}


//截图，quality：raw|compressed
- (void)snapshot:(NSString *)quality withCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher snapshot:quality
    withCompletionHandler:completionHandler];
}

//切换手电筒
- (void)toggleTorchWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher toggleTorchWithCompletionHandler:completionHandler];
}

//切换摄像头
- (void)switchCameraWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    [self.pusher switchCameraWithCompletionHandler:completionHandler];
}


- (void)setLivePusherContextState:(NSDictionary *)state
{
    NSString *url = state[@"url"];
    if (url && [url isKindOfClass:[NSString class]]) {
        self.pusher.rtmpURL = url;
    }
    NSString *mode = state[@"mode"];
    if (mode && [mode isKindOfClass:[NSString class]]) {
        WALivePusherMode pMode = WALivePusherModeRTC;
        if (kStringEqualToString(@"SD", mode)) {
            pMode = WALivePusherModeSD;
        } else if (kStringEqualToString(@"HD", mode)) {
            pMode = WALivePusherModeHD;
        } else if (kStringEqualToString(@"FHD", mode)) {
            pMode = WALivePusherModeFHD;
        }
        self.pusher.mode = pMode;
    }
    NSNumber *autoPush = state[@"autopush"];
    if (autoPush && [autoPush isKindOfClass:[NSNumber class]]) {
        self.pusher.autopush = [autoPush boolValue];
    }
    NSNumber *muted = state[@"muted"];
    if (muted && [muted isKindOfClass:[NSNumber class]]) {
        self.pusher.muted = [muted boolValue];
    }
    NSNumber *enableCamera = state[@"enableCamera"];
    if (enableCamera && [enableCamera isKindOfClass:[NSNumber class]]) {
        self.pusher.enableCamara = [enableCamera boolValue];
    }
    NSNumber *autoFocus = state[@"autoFocus"];
    if (autoFocus && [autoFocus isKindOfClass:[NSNumber class]]) {
        self.pusher.autoFocus = [autoFocus boolValue];
    }
    NSString *orientation = state[@"orientation"];
    if (orientation && [orientation isKindOfClass:[NSString class]]) {
        WALivePusherOrientation pOrientation = WALivePusherOrientationVertical;
        if (kStringEqualToString(@"horizontal", orientation)) {
            pOrientation = WALivePusherOrientationHorizontal;
        }
        self.pusher.orientation = pOrientation;
    }
    NSNumber *beauty = state[@"beauty"];
    if (beauty && [beauty isKindOfClass:[NSNumber class]]) {
        self.pusher.beauty = [beauty floatValue];
    }
    NSNumber *whiteness = state[@"whiteness"];
    if (whiteness && [whiteness isKindOfClass:[NSNumber class]]) {
        self.pusher.whiteness = [whiteness floatValue];
    }
    NSString *aspect = state[@"aspect"];
    if (aspect && [aspect isKindOfClass:[NSString class]]) {
        WALivePusherAspect pAspect = WALivePusherAspect9To16;
        if (kStringEqualToString(@"3:4", aspect)) {
            pAspect = WALivePusherAspect3To4;
        }
        self.pusher.aspect = pAspect;
    }
    NSNumber *minBitrate = state[@"minBitrate"];
    if (minBitrate && [minBitrate isKindOfClass:[NSNumber class]]) {
        self.pusher.minBitrate = [minBitrate unsignedIntValue];
    }
    NSNumber *maxBitrate = state[@"maxBitrate"];
    if (maxBitrate && [maxBitrate isKindOfClass:[NSNumber class]]) {
        self.pusher.maxBitrate = [maxBitrate unsignedIntValue];
    }
    NSString *audioQuality = state[@"audioQuality"];
    if (audioQuality && [audioQuality isKindOfClass:[NSString class]]) {
        WALivePusherAudioQuality quality = WALivePusherAudioQualityHigh;
        if (kStringEqualToString(@"low", audioQuality)) {
            quality = WALivePusherAudioQualityLow;
        }
        self.pusher.audioQuality = quality;
    }
    NSString *waitingImage = state[@"waitingImage"];
    if (waitingImage && [waitingImage isKindOfClass:[NSString class]]) {
        self.pusher.waitingImage = waitingImage;
    }
    NSString *waitingImageHash = state[@"waitingImageHash"];
    if (waitingImageHash && [waitingImageHash isKindOfClass:[NSString class]]) {
        self.pusher.waitingImageHash = waitingImageHash;
    }
    NSNumber *zoom = state[@"zoom"];
    if (zoom && [zoom isKindOfClass:[NSNumber class]]) {
        self.pusher.zoom = [zoom boolValue];
    }
    NSString *devicePosition = state[@"devicePosition"];
    if (devicePosition && [devicePosition isKindOfClass:[NSString class]]) {
        WALivePusherDevicePosition position = WALivePusherDevicePositionFront;
        if (kStringEqualToString(@"back", devicePosition)) {
            position = WALivePusherDevicePositionBack;
        }
        self.pusher.devicePosition = position;
    }
    NSNumber *mirror = state[@"mirror"];
    if (mirror && [mirror isKindOfClass:[NSNumber class]]) {
        self.pusher.mirror = [mirror boolValue];
    }
    NSNumber *remoteMirror = state[@"remoteMirror"];
    if (remoteMirror && [remoteMirror isKindOfClass:[NSNumber class]]) {
        self.pusher.remoteMirror = [remoteMirror boolValue];
    }
    NSString *localMirror = state[@"localMirror"];
    if (localMirror && [localMirror isKindOfClass:[NSString class]]) {
        WALivePusherLocalMirror mirror = WALivePusherLocalMirrorAuto;
        if (kStringEqualToString(@"enable", localMirror)) {
            mirror = WALivePusherLocalMirrorEnable;
        } else if (kStringEqualToString(@"disable", localMirror)) {
            mirror = WALivePusherLocalMirrorDisable;
        }
        self.pusher.localMirror = mirror;
    }
    NSNumber *audioReverbType = state[@"audioReverbType"];
    if (audioReverbType && [audioReverbType isKindOfClass:[NSNumber class]]) {
        WALivePusherAudioReverbType type = (WALivePusherAudioReverbType)[audioReverbType unsignedIntegerValue];
        self.pusher.audioReverbType = type;
    }
    NSNumber *enableMic = state[@"enableMic"];
    if (enableMic && [enableMic isKindOfClass:[NSNumber class]]) {
        self.pusher.enableMic = [enableMic boolValue];
    }
    NSNumber *enableAgc = state[@"enableAgc"];
    if (enableAgc && [enableAgc isKindOfClass:[NSNumber class]]) {
        self.pusher.enableAgc = [enableAgc boolValue];
    }
    NSNumber *enableAns = state[@"enableAns"];
    if (enableAns && [enableAns isKindOfClass:[NSNumber class]]) {
        self.pusher.enableAns = [state[@"enableAns"] boolValue];
    }
    NSString *audioVolumeType = state[@"audioVolumeType"];
    if (audioVolumeType && [audioVolumeType isKindOfClass:[NSString class]]) {
        WALivePusherAudioVolumeType type = WALivePusherAudioVolumeTypeAuto;
        if (kStringEqualToString(@"media", audioVolumeType)) {
            type  = WALivePusherAudioVolumeTypeMedia;
        } else if (kStringEqualToString(@"voicecall", audioVolumeType)) {
            type = WALivePusherAudioVolumeTypeVoIP;
        }
        self.pusher.audioVolumType = type;
    }
    NSNumber *videoWidth = state[@"videoWidth"];
    if (videoWidth && [videoWidth isKindOfClass:[NSNumber class]]) {
        self.pusher.videoWidth = [videoWidth unsignedIntValue];
    }
    NSNumber *videoHeight = state[@"videoHeight"];
    if (videoHeight && [videoHeight isKindOfClass:[NSNumber class]]) {
        self.pusher.videoHeight = [videoHeight unsignedIntValue];
    }
    NSString *beautyStyle = state[@"beautyStyle"];
    if (beautyStyle && [beautyStyle isKindOfClass:[NSString class]]) {
        WALivePusherBeautyStyle style = WALivePusherBeautyStyleSmooth;
        if (kStringEqualToString(@"nature", beautyStyle)) {
            style = WALivePusherBeautyStyleNatura;
            self.pusher.beautyStyle = style;
        }
    }
    NSString *filter = state[@"filter"];
    if (filter && [filter isKindOfClass:[NSString class]]) {
        WALivePusherFilter pFilter = WALivePusherFilterStandard;
        if (kStringEqualToString(@"pink", filter)) {
            pFilter = WALivePusherFilterPink;
        } else if (kStringEqualToString(@"nostalgia", filter)) {
            pFilter = WALivePusherFilterNostalgia;
        } else if (kStringEqualToString(@"blues", filter)) {
            pFilter = WALivePusherFilterBlues;
        } else if (kStringEqualToString(@"romantic", filter)) {
            pFilter = WALivePusherFilterRomantic;
        } else if (kStringEqualToString(@"cool", filter)) {
            pFilter = WALivePusherFilterCool;
        } else if (kStringEqualToString(@"fresher", filter)) {
            pFilter = WALivePusherFilterFresher;
        } else if (kStringEqualToString(@"solor", filter)) {
            pFilter = WALivePusherFilterSolor;
        } else if (kStringEqualToString(@"aestheticism", filter)) {
            pFilter = WALivePusherFilterAestheticism;
        } else if (kStringEqualToString(@"whitening", filter)) {
            pFilter = WALivePusherFilterWhitening;
        } else if (kStringEqualToString(@"cerisered", filter)) {
            pFilter = WALivePusherFilterCerisered;
        }
#warning 设置滤镜
    }
}
@end
