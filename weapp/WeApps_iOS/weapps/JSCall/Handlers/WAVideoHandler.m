//
//  WAVideoHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/29.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVideoHandler.h"
#import "AuthorizationCheck.h"
#import "FileUtils.h"
#import "QMUIKit.h"
#import "LCActionSheet.h"
#import "WAMediaUtils.h"
#import "PathUtils.h"
#import "WAVideoPlayerManager.h"
#import "Weapps.h"


kSELString(saveVideoToPhotosAlbum)
kSELString(compressVideo)
kSELString(chooseVideo)
kSELString(chooseMedia)
kSELString(getVideoInfo)
kSELString(createNativeVideoComponent)
kSELString(createVideoContext)
kSELString(operateVideoContext)
kSELString(setVideoContextState)

typedef NS_OPTIONS(NSUInteger, WAChooseMediaSourceType) {
    WAChooseVideoSourceNotDefine            = 0,
    WAChooseVideoSourceCamera               = 1 << 0,
    WAChooseVideoSourceAlbum                = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, WAChooseMediaSizeType) {
    WAChooseMediaSizeTypeNotDefine          = 0,
    WAChooseMediaSizeTypeCompressed         = 1 << 0,
    WAChooseMediaSizeTypeOriginal           = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, WAChooseMediaType) {
    WAChooseMediaTypeNotDefine          = 0,
    WAChooseMediaTypeImage         = 1 << 0,
    WAChooseMediaTypeVideo           = 1 << 1,
};


@implementation WAVideoHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            saveVideoToPhotosAlbum,
            compressVideo,
            chooseVideo,
            chooseMedia,
            getVideoInfo,
            createNativeVideoComponent,
            createVideoContext,
            operateVideoContext,
            setVideoContextState
        ];
    }
    return methods;
}

JS_API(saveVideoToPhotosAlbum){
    if (![AuthorizationCheck photoLibraryAuthorizationCheck]) {
        kFailWithError(saveVideoToPhotosAlbum, -1, @"没有相册使用权限")
        return @"";
    }
    kBeginCheck
    kEndCheck([NSString class], @"filePath", NO)
    
    NSString *filePath = event.args[@"filePath"];
    if (filePath && kStringContainString([FileUtils getFileMimeType:filePath], @"video")) {
        [self _saveViedoToLibrary:filePath
                        withEvent:event
                       completion:^(BOOL success, NSError * _Nullable error) {
            if (success) {
                kSuccessWithDic(nil)
            } else {
                [self event:event failWithError:error];
            }
        }];
    } else {
        kFailWithError(saveVideoToPhotosAlbum, -1, @"视频文件找不到或不可用")
    }
    return @"";
}

JS_API(compressVideo){
    
    kBeginCheck
    kCheck([NSString class], @"src", NO)
    kCheck([NSString class], @"quality", YES)
    kCheck([NSNumber class], @"bitrate", YES)
    kCheck([NSNumber class], @"fps", YES)
    kEndCheck([NSNumber class], @"resolution", YES)
    
    NSString *src = event.args[@"src"];
    NSString *quality = event.args[@"quality"];
    NSNumber *bitrateNumber = event.args[@"bitrate"];
    NSNumber *fpsNumber = event.args[@"fps"];
    NSNumber *resolutionNumber = event.args[@"resolution"];
    
    NSInteger bitrate = [bitrateNumber integerValue] * 1024;
    NSInteger fps = [fpsNumber integerValue];
    CGFloat resolution = [resolutionNumber floatValue];
    WAVideoQualityType qualityType = WAVideoQualityTypeNone;
    if (kStringEqualToString(quality, @"medium")) {
        qualityType = WAVideoQualityTypeMedium;
    } else if (kStringEqualToString(quality, @"high")) {
        qualityType = WAVideoQualityTypeHigh;
    } else if (kStringEqualToString(quality, @"low")) {
        qualityType = WAVideoQualityTypeLow;
    }
    NSString *outPath = [[PathUtils tempFilePath] stringByAppendingPathExtension:[NSString stringWithFormat:@"%@.mp4",[[NSUUID UUID] UUIDString]]];
    [WAMediaUtils compressVideo:[NSURL fileURLWithPath:src]
                         output:[NSURL fileURLWithPath:outPath]
                    withQuality:qualityType
                        bitRate:bitrate
                            fps:fps
                resolutionScale:resolution
                       complete:^(BOOL success, NSError * _Nonnull err) {
        
        if (success) {
            kSuccessWithDic((@{
                @"tempFilePath": outPath,
                @"size": [NSString stringWithFormat:@"%llu",[FileUtils getFileSize:outPath] / 1000]
                          }));
        } else {
            [self event:event failWithError:err];
        }
    }];
    return @"";
}


JS_API(getVideoInfo){
    
    kBeginCheck
    kEndCheck([NSString class], @"src", NO)
    NSString *src = event.args[@"src"];
    if (![FileUtils isValidFile:src]) {
        kFailWithErrorWithReturn(getVideoInfo, -1, ([NSString stringWithFormat:@"can not find video file(%@)",src]))
    }
    NSString *mimeType = [FileUtils getFileMimeType:src];
    if (![[mimeType lowercaseString] containsString:@"video"]) {
        kFailWithErrorWithReturn(getVideoInfo, -1, ([NSString stringWithFormat:@"file is not a vidoe file(%@)",src]))
    }
    NSString *type = [[mimeType componentsSeparatedByString:@"/"] lastObject];
    UInt64 size = [FileUtils getFileSize:src];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:src] options:nil];
    NSString *orientation = [WAMediaUtils orientationOfAsset:asset];
    NSTimeInterval duration = [WAMediaUtils getDurationWithVideo:src];
    CGSize resolution = [WAMediaUtils queryVideoResolutionWithAsset:asset];
    float fps = [WAMediaUtils getFpsWithVideo:asset];
    float bitRate = [WAMediaUtils getBitRateWithVideo:asset];
    kSuccessWithDic((@{
        @"orientation"  : orientation,
        @"type"         : type?:@"unknown" ,
        @"duration"     : @(ceilf(duration)) ,
        @"size"         : @(size) ,
        @"height"       : @(resolution.height),
        @"width"        : @(resolution.width),
        @"fps"          : @(fps),
        @"bitrate"      : @(ceilf(bitRate / 1024))
                    }))
    return @"";
}

JS_API(chooseVideo){
    
    kBeginCheck
    kCheck([NSArray class], @"sourceType", YES)
    kCheckIsBoolean([NSNumber class], @"compressed", YES, YES)
    kCheck([NSNumber class], @"maxDuration", YES)
    kEndCheck([NSString class], @"camera", YES)
    
    
    NSDictionary *params = event.args;
    
    NSString *cameraStr = @"back";
    if (kWA_DictContainKey(params, @"camera")) {
        cameraStr = params[@"camera"];
    }
            
    BOOL isFront = [cameraStr isEqualToString:@"front"];
    BOOL shouldCompressed = params[@"compressed"] ? [params[@"compressed"] boolValue] : YES;
    CGFloat maxDuration = params[@"maxDuration"] ? [params[@"maxDuration"] doubleValue] : 60.0;
    if (maxDuration <= 0 || maxDuration > 60) {
        kFailWithError(chooseVideo, -1, @"maxDuration can not over 60")
        return @"";
    }

    NSArray *sourceTypeArray = params[@"sourceType"];
    WAChooseMediaSourceType chooseVideoSourceType = WAChooseVideoSourceNotDefine;
    if ([sourceTypeArray containsObject:@"album"]) {
        chooseVideoSourceType |= WAChooseVideoSourceAlbum;
    }
    if ([sourceTypeArray containsObject:@"camera"]) {
        chooseVideoSourceType |= WAChooseVideoSourceCamera;
    }
    if (sourceTypeArray.count == 0) {
        chooseVideoSourceType |= WAChooseVideoSourceAlbum;
        chooseVideoSourceType |= WAChooseVideoSourceCamera;
    }
    if (chooseVideoSourceType == WAChooseVideoSourceNotDefine) {
        kFailWithError(chooseVideo, -1, @"error sourceType")
        return @"";
    }
    [self _handleJump:event
            mediaType:WAChooseMediaTypeVideo
           sourceType:chooseVideoSourceType
          maxduration:maxDuration
             maxCount:1
     shouldCompressed:shouldCompressed
              isFront:isFront
    isFromChooseMedia:NO];
    
    return @"";
}

JS_API(chooseMedia){
    
    kBeginCheck
    kCheck([NSNumber class], @"count", YES)
    kCheck([NSArray class], @"mediaType", YES)
    kCheck([NSArray class], @"sourceType", YES)
    kCheck([NSNumber class], @"maxDuration", YES)
    kCheck([NSArray class], @"sizeType", YES)
    kEndCheck([NSString class], @"camera", YES)
    
    NSDictionary *params = event.args;
    
    NSString *cameraStr = params[@"camera"];
    if (!cameraStr) {
        cameraStr = @"back";
    }
    if ([cameraStr isEqualToString:@"front"] == NO && [cameraStr isEqualToString:@"back"] == NO) {
        kFailWithError(chooseMedia, -1, @"camera: error cameraType")
        return @"";
    }
    BOOL isFront = [cameraStr isEqualToString:@"front"];
    
    CGFloat maxDuration = params[@"maxDuration"] ? [params[@"maxDuration"] doubleValue] : 60.0;
    if (maxDuration < 3 || maxDuration > 30) {
        kFailWithError(chooseMedia, -1, @"maxDuration can not over 30 or below 3")
        return @"";
    }
    
    NSArray *sizeTypeArray = params[@"sizeType"];
    WAChooseMediaSizeType chooseMediaSizeType = WAChooseMediaSizeTypeNotDefine;
    if (sizeTypeArray.count == 0) {
        chooseMediaSizeType |= WAChooseMediaSizeTypeOriginal;
        chooseMediaSizeType |= WAChooseMediaSizeTypeCompressed;
    }
    if ([sizeTypeArray containsObject:@"original"]) {
        chooseMediaSizeType |= WAChooseMediaSizeTypeOriginal;
    }
    if ([sizeTypeArray containsObject:@"compressed"]) {
        chooseMediaSizeType |= WAChooseMediaSizeTypeCompressed;
    }
    if (chooseMediaSizeType == WAChooseMediaSizeTypeNotDefine) {
        kFailWithError(chooseMedia, -1, @"error sizeType")
        return @"";
    }
    NSArray *sourceTypeArray = params[@"sourceType"];
    WAChooseMediaSourceType chooseVideoSourceType = WAChooseVideoSourceNotDefine;
    if ([sourceTypeArray containsObject:@"album"]) {
        chooseVideoSourceType |= WAChooseVideoSourceAlbum;
    }
    if ([sourceTypeArray containsObject:@"camera"]) {
        chooseVideoSourceType |= WAChooseVideoSourceCamera;
    }
    if (sourceTypeArray.count == 0) {
        chooseVideoSourceType |= WAChooseVideoSourceAlbum;
        chooseVideoSourceType |= WAChooseVideoSourceCamera;
    }
    if (chooseVideoSourceType == WAChooseVideoSourceNotDefine) {
        kFailWithError(chooseMedia, -1, @"error sourceType")
        return @"";
    }
    
    
    NSArray *mediaTypeArray = params[@"mediaType"];
    WAChooseMediaType chooseMediaType = WAChooseMediaTypeNotDefine;
    if ([mediaTypeArray containsObject:@"image"]) {
        chooseMediaType |= WAChooseMediaTypeImage;
    }
    if ([mediaTypeArray containsObject:@"video"]) {
        chooseMediaType |= WAChooseMediaTypeVideo;
    }
    if (mediaTypeArray.count == 0) {
        chooseVideoSourceType |= WAChooseVideoSourceAlbum;
        chooseVideoSourceType |= WAChooseVideoSourceCamera;
    }
    if (chooseVideoSourceType == WAChooseVideoSourceNotDefine) {
        kFailWithError(chooseMedia, -1, @"error mediaType")
        return @"";
    }
    NSUInteger maxCount = 9;
    if (kWA_DictContainKey(params, @"count")) {
        maxCount = [params[@"count"] integerValue];
    }
    [self _handleJump:event
            mediaType:chooseMediaType
           sourceType:chooseVideoSourceType
          maxduration:maxDuration
             maxCount:maxCount
     shouldCompressed:chooseMediaSizeType == WAChooseMediaSizeTypeOriginal ? NO : YES
              isFront:isFront
    isFromChooseMedia:YES];
    
    return @"";
}


//*********************************************************************************

#pragma mark private
- (void)_saveViedoToLibrary:(NSString *)videoPath
                  withEvent:(JSAsyncEvent *)event
                 completion:(void (^)(BOOL success, NSError * _Nullable error))handler
{
    
    QMUIAlertController *alertController = [QMUIAlertController alertControllerWithTitle:@"保存到指定相册" message:nil
                                                                          preferredStyle:QMUIAlertControllerStyleActionSheet];
    // 显示空相册，不显示智能相册
    [[QMUIAssetsManager sharedInstance] enumerateAllAlbumsWithAlbumContentType:QMUIAlbumContentTypeAll
                                                                showEmptyAlbum:YES
                                                     showSmartAlbumIfSupported:NO
                                                                    usingBlock:^(QMUIAssetsGroup *resultAssetsGroup) {
        if (resultAssetsGroup) {
            QMUIAlertAction *action = [QMUIAlertAction actionWithTitle:[resultAssetsGroup name]
                                                                 style:QMUIAlertActionStyleDefault
                                                               handler:^(QMUIAlertController *aAlertController,
                                                                         QMUIAlertAction *action) {
                if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoPath)) {
                    QMUISaveVideoAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(videoPath,
                                                                              resultAssetsGroup,
                                                                              ^(QMUIAsset *asset,
                                                                                NSError *error) {
                        if (asset && !error) {
                            if (handler) {
                                handler(YES, nil);
                            }
//                            [QMUITips showSucceed:[NSString stringWithFormat:@"已保存到相册-%@", [resultAssetsGroup name]] inView:[event.webView.webHost currentViewController].view hideAfterDelay:2];
                        } else {
                            if (handler) {
                                handler(NO, error);
                            }
                            [QMUITips showError:@"保存失败" detailText:error.description inView:[event.webView.webHost currentViewController].view hideAfterDelay:2];
                        }
                        
                    });
                } else {
//                    [QMUITips showError:@"保存失败，视频格式不符合当前设备要求" inView:[event.webView.webHost currentViewController].view hideAfterDelay:2];
                }
            }];
            [alertController addAction:action];
        } else {
            // group 为 nil，即遍历相册完毕
            QMUIAlertAction *cancelAction = [QMUIAlertAction actionWithTitle:@"取消" style:QMUIAlertActionStyleCancel handler:nil];
            [alertController addAction:cancelAction];
        }
    }];
    [alertController showWithAnimated:YES];
    
}

- (void)_handleJump:(JSAsyncEvent *)event
          mediaType:(WAChooseMediaType)mediaType
         sourceType:(WAChooseMediaSourceType)chooseVideoSourceType
        maxduration:(CGFloat)maxDuration
           maxCount:(NSInteger)maxCount
   shouldCompressed:(BOOL)shouldCompressed
            isFront:(BOOL)isFront
  isFromChooseMedia:(BOOL)isFromChooseMedia
{
    NSMutableArray<NSDictionary *> *titleActionArray = [[NSMutableArray alloc] initWithCapacity:2];
    if (chooseVideoSourceType & WAChooseVideoSourceCamera) {
        [titleActionArray addObject:@{
                                      @"title" : @"拍摄",
                                      @"action" : ^{
            [self _openPickerVC:event
               shouldCompressed:shouldCompressed
                    maxDuration:maxDuration
                      mediaType:mediaType
                       maxCount:maxCount
                        isFront:isFront
                       isCamera:YES
              isFromChooseMedia:isFromChooseMedia];
        }
                                      }];
    }
    if (chooseVideoSourceType & WAChooseVideoSourceAlbum) {
        [titleActionArray addObject:@{
                                      @"title" : @"从手机相册选择",
                                      @"action" : ^{
            [self _openPickerVC:event
               shouldCompressed:shouldCompressed
                    maxDuration:maxDuration
                      mediaType:mediaType
                       maxCount:maxCount
                        isFront:isFront
                       isCamera:NO
              isFromChooseMedia:isFromChooseMedia];

        }
                                      }];
    }
    if (titleActionArray.count == 1) {
        NSDictionary *dict = titleActionArray.firstObject;
        void(^block)(void) = dict[@"action"];
        if (block) {
            block();
        }
        return;
    }
    
    LCActionSheet *actionSheet = [LCActionSheet sheetWithTitle:nil
                                             cancelButtonTitle:@"取消"
                                                       clicked:^(LCActionSheet *actionSheet,
                                                                 NSInteger buttonIndex) {
        if (actionSheet.cancelButtonIndex == buttonIndex) {
            NSString *domain = isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
            kFailWithError(domain, -1, @"cancel");
        } else {
            NSDictionary *dict = titleActionArray.lastObject;
            if (buttonIndex == 1) {
                dict = titleActionArray.firstObject;
            }
            void(^block)(void) = dict[@"action"];
            if (block) {
                block();
            }
        }
    } otherButtonTitleArray:@[@"拍摄", @"从手机相册选择"]];
    [actionSheet show];
}

- (void)_openPickerVC:(JSAsyncEvent *)event
     shouldCompressed:(BOOL)shouldCompresse
          maxDuration:(CGFloat)maxDuration
            mediaType:(WAChooseMediaType)mediaType
             maxCount:(NSUInteger)maxCount
              isFront:(BOOL)isFront
             isCamera:(BOOL)isCamera
    isFromChooseMedia:(BOOL)isFromChooseMedia
{
    NSString *type = @"mix";
    if (mediaType & WAChooseMediaTypeVideo) {
        type = @"video";
    }
    if (mediaType & WAChooseMediaTypeImage) {
        type = @"image";
    }
    if (mediaType & WAChooseMediaTypeVideo && mediaType & WAChooseMediaTypeImage) {
        type = @"mix";
    }
    NSDictionary *params = @{
                           @"type"              :       type,
                           @"shouldCompress"    :       @(shouldCompresse),
                           @"maxDuration"       :       @(maxDuration),
                           @"camera"            :       isFront ? @"front" : @"back",
                           @"isFromChooseMedia" :       @(isFromChooseMedia)
                           };
    if (isCamera) {
        [event.webView.webHost takeMediaFromCameraWithParams:params
                                           completionHandler:^(NSDictionary * _Nullable result,
                                                               NSError * _Nullable error) {
           if (error) {
                if (event.fail) {
                    event.fail(error);
                }
            } else {
                kSuccessWithDic(result);
            }
        }];
    } else {
        [event.webView.webHost openPickerControllerWithParams:params
                                            completionHandler:^(NSDictionary * _Nullable result,
                                                                     NSError * _Nullable error) {
            if (error) {
                if (event.fail) {
                    event.fail(error);
                }
            } else {
                kSuccessWithDic(result);
            }
        }];
    }
}

#pragma mark - VideoContext

JS_API(createNativeVideoComponent){
    kBeginCheck
    kCheck([NSString class], @"videoId", NO)
    kCheck([NSDictionary class], @"position", NO)
    kEndCheck([NSDictionary class], @"state", NO)
    NSString *videoId = event.args[@"videoId"];
    
    [[Weapps sharedApps].videoPlayerManager createVideoPlayer:videoId
                                                    inWebView:event.webView
                                                 withPosition:event.args[@"position"]
                                             childrenPosition:event.args[@"childrenPosition"]
                                                        state:event.args[@"state"]
                                            completionHandler:^(BOOL success,
                                                                NSDictionary * _Nonnull result,
                                                                NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(createVideoContext){
//    kBeginCheck
//    kCheck([NSString class], @"videoId", NO)
//    kCheck([NSDictionary class], @"position", NO)
//    kEndCheck([NSDictionary class], @"state", NO)
//    NSString *videoId = event.args[@"videoId"];
//
//    [[Weapps sharedApps].videoPlayerManager createVideoPlayer:videoId
//                                                    inWebView:event.webView
//                                                 withPosition:event.args[@"position"]
//                                             childrenPosition:event.args[@"childrenPosition"]
//                                                        state:event.args[@"state"]
//                                            completionHandler:^(BOOL success, NSDictionary * _Nonnull result, NSError * _Nonnull error) {
//        if (success) {
//            kSuccessWithDic(result)
//        } else {
//            kFailWithErr(error)
//        }
//    }];
    return @"";
}

JS_API(operateVideoContext){
    kBeginCheck
    kCheck([NSString class], @"operationType", NO)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *operationType = event.args[@"operationType"];
    if (kStringEqualToString(operationType, @"exitFullScreen")) {
        return [self _exitFullScreen:event];
    } else if (kStringEqualToString(operationType, @"exitPictureInPicture")) {
        return [self _exitPictureInPicture:event];
    } else if (kStringEqualToString(operationType, @"hideStatusBar")) {
        return [self _hideStatusBar:event];
    } else if (kStringEqualToString(operationType, @"pause")) {
        return [self _pause:event];
    } else if (kStringEqualToString(operationType, @"play")) {
        return [self _play:event];
    } else if (kStringEqualToString(operationType, @"playbackRate")) {
        return [self _playbackRate:event];
    } else if (kStringEqualToString(operationType, @"requestFullScreen")) {
        return [self _requestFullScreen:event];
    } else if (kStringEqualToString(operationType, @"seek")) {
        return [self _seek:event];
    } else if (kStringEqualToString(operationType, @"sendDanmu")) {
        return [self _sendDanmu:event];
    } else if (kStringEqualToString(operationType, @"showStatusBar")) {
        return [self _showStatusBar:event];
    } else if (kStringEqualToString(operationType, @"stop")) {
        return [self _stop:event];
    }
    return @"";
}

JS_API(setVideoContextState){
    kBeginCheck
    kCheck([NSDictionary class], @"state", NO)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                                               setState:event.args[@"state"]];
    return @"";
}

PRIVATE_API(exitFullScreen){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                    exitFullScreenWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(exitPictureInPicture){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
              exitPictureInPictureWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(hideStatusBar){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                     hideStatusBarWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(pause){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                             pauseWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(play){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                              playWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(playbackRate){
    kBeginCheck
    kCheck([NSNumber class], @"rate", NO)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    CGFloat rate = [event.args[@"rate"] floatValue];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                              setPlaybackRate:rate
                              playWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(requestFullScreen){
    kBeginCheck
    kCheck([NSNumber class], @"direction", YES)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    NSNumber *direction = @(1);
    if (event.args[@"direction"]) {
        direction = event.args[@"direction"];
        NSArray *directions = @[@(0), @(90), @(-90)];
        if (![directions containsObject:direction]) {
            kFailWithErrorWithReturn(@"requestFullScreen", -1, @"direction is not valid");
        }
    }
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                         requestFullScreenWithDirection:direction
                                      completionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(seek){
    kBeginCheck
    kCheck([NSNumber class], @"position", NO)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    CGFloat position = [event.args[@"position"] floatValue];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                                                   seek:position
                                      completionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(sendDanmu){
    kBeginCheck
    kCheck([NSString class], @"text", NO)
    kCheck([NSString class], @"color", NO)
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    WADanmu *danmu = [[WADanmu alloc] initWithDict:event.args];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                                              sendDanmu:danmu
                                      completionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(showStatusBar){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                     showStatusBarWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

PRIVATE_API(stop){
    kBeginCheck
    kEndCheck([NSString class], @"videoId", NO)
    NSString *videoId = event.args[@"videoId"];
    [[Weapps sharedApps].videoPlayerManager videoPlayer:videoId
                              stopWithCompletionHandler:^(BOOL success,
                                                          NSDictionary * _Nonnull result,
                                                          NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(result)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}
@end
