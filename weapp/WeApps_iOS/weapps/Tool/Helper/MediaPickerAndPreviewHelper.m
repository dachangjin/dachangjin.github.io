//
//  MediaPickerAndPreviewHelper.m
//  weapps
//
//  Created by tommywwang on 2020/8/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "MediaPickerAndPreviewHelper.h"
#import "TZImagePickerController.h"
#import "PathUtils.h"
#import "FileUtils.h"
#import <AVFoundation/AVAsset.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "QMUIKit.h"
#import "WAMediaUtils.h"
#import "NetworkHelper.h"

@interface MediaPickerAndPreviewHelper ()
<TZImagePickerControllerDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate,
QMUIImagePreviewViewDelegate,
UIDocumentInteractionControllerDelegate>
{
    UIDocumentInteractionController *_documentInteractionController; //文件管理
}
@property (nonatomic, strong) NSArray <NSString *> *imageUrls;
@property (nonatomic, strong) QMUIImagePreviewViewController *imagePreviewViewController;

@end


@interface MACameraPickerController : UIImagePickerController
@property (nonatomic, strong) void(^callBack)(NSDictionary *dic, NSError *error);
@property (nonatomic, assign) BOOL shouldCompress;
@property (nonatomic, assign) BOOL isFromChooseMedia;
@end
@implementation MACameraPickerController
@end

@interface WAImagePickerController : TZImagePickerController
@property (nonatomic, strong) void(^callBack)(NSDictionary *dic, NSError *error);
@property (nonatomic, assign) BOOL isFromChooseMedia;
@property (nonatomic, assign) BOOL shouldCompress;

@end
@implementation WAImagePickerController
@end

@implementation MediaPickerAndPreviewHelper


#pragma mark - chooseMedia
- (void)takeMediaFromCameraWithParams:(NSDictionary *)params
                    completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    MACameraPickerController *picker = [[MACameraPickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        [self _pickerFailWithDomain:@"chooseMedia"
                            message:@"No permission"
                  completionHandler:completionHandler];
        return;
    }
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    NSString *type = params[@"type"];
    BOOL shouldCompress = params[@"shouldCompress"] ? [params[@"shouldCompress"] boolValue] : YES;
    picker.isFromChooseMedia = params[@"isFromChooseMedia"] ? [params[@"isFromChooseMedia"] boolValue] : NO;
    if ([type isEqualToString:@"image"])
    {
        picker.mediaTypes =  @[(NSString *)kUTTypeImage];
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    }
    else if ([type isEqualToString:@"video"])
    {
        picker.mediaTypes =  @[(NSString *)kUTTypeMovie];
        picker.videoMaximumDuration = params[@"maxDuration"] ? [params[@"maxDuration"] integerValue] : 60;
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
        
        BOOL isFront = kStringEqualToString(@"front", params[@"camera"]);
        picker.cameraDevice = isFront ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
        picker.videoQuality = shouldCompress ? UIImagePickerControllerQualityType640x480: UIImagePickerControllerQualityTypeHigh;
        
    }
    else if ([type isEqualToString:@"mix"])
    {
        picker.mediaTypes =  @[(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie];
    }
    
    picker.shouldCompress = shouldCompress;
    picker.delegate = self;
    picker.callBack = completionHandler;
    [self.viewController presentViewController:picker animated:YES completion:nil];
}

- (void)openPickerControllerWithParams:(NSDictionary *)params
                     completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    NSInteger maxCount = [params[@"maxCount"] integerValue];
    
    WAImagePickerController *imagePickerVc = [[WAImagePickerController alloc] initWithMaxImagesCount:maxCount delegate:nil];
    imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePickerVc.allowTakePicture = NO;
    imagePickerVc.allowTakeVideo = NO;
    imagePickerVc.pickerDelegate = self;
    imagePickerVc.callBack = completionHandler;
    if ([params[@"isFromChooseMedia"] boolValue]) {
        imagePickerVc.isFromChooseMedia = YES;
    }
    
    BOOL shouldCompress = [params[@"shouldCompress"] boolValue];
    BOOL showOriginal = [params[@"showOriginal"] boolValue];
    
    imagePickerVc.shouldCompress = shouldCompress;
    NSString *type = params[@"type"];
    if ([type isEqualToString:@"image"])
    {
        imagePickerVc.allowPickingImage = YES;
        imagePickerVc.allowPickingVideo = NO;
    }
    else if ([type isEqualToString:@"video"])
    {
        imagePickerVc.allowPickingImage = NO;
        imagePickerVc.allowPickingVideo = YES;
    }
    else if ([type isEqualToString:@"mix"])
    {
        imagePickerVc.allowPickingImage = YES;
        imagePickerVc.allowPickingVideo = YES;
    }
    
    if (shouldCompress && showOriginal == NO) {
        imagePickerVc.allowPickingOriginalPhoto = NO;
    } else if (showOriginal && shouldCompress == NO) {
        imagePickerVc.allowPickingOriginalPhoto = YES;
    } else {
        imagePickerVc.allowPickingOriginalPhoto = YES;
    }
    
    
////     你可以通过block或者代理，来得到用户选择的照片.
//    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto){
//
//    }];
    [self.viewController presentViewController:imagePickerVc animated:YES completion:nil];
}


#pragma mark - TZImagePickerControllerDelegate

- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker
{
    WAImagePickerController *viewController = (WAImagePickerController *)picker;
    if (viewController.callBack) {
        viewController.callBack(nil, [NSError errorWithDomain:@"chooseMedia" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: @"cancel"
        }]);
    }
}


//多个image或video
- (void)imagePickerController:(TZImagePickerController *)picker
       didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets
        isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
{
    WAImagePickerController *viewController = (WAImagePickerController *)picker;
    if (!viewController.isFromChooseMedia) {
        //chooseImage
        NSMutableArray * result = [NSMutableArray arrayWithCapacity:[photos count]];
        NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[photos count]];
        for ( UIImage * photo in photos )
        {
            NSString *tmpPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"%@.jpg",[[[NSUUID UUID] UUIDString] lowercaseString]]];
            NSData *imageData = nil;
            if (photo)
            {
                imageData = UIImageJPEGRepresentation(photo, 0.5);
            }
            if (imageData && tmpPath.length > 0 && [imageData writeToFile:tmpPath atomically:YES])
            {
                [result addObject:@{
                    @"path" : tmpPath,
                    @"size" : @([imageData length]),
                }];
                [paths addObject:tmpPath];
            }
        }
        if (viewController.callBack)
        {
            viewController.callBack(@{
                @"tempFiles" : result,
                @"tempFilePaths" : paths
                              }, nil);
        }
        return;
    }
    
    //chooseMeida
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSMutableArray *array = [NSMutableArray array];
    NSString *type = @"image";
    for ( UIImage * photo in photos )
    {
        NSString *tmpPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"%@.jpg",[[[NSUUID UUID] UUIDString] lowercaseString]]];
        NSData *imageData = nil;
        if (photo)
        {
            imageData = UIImageJPEGRepresentation(photo, 0.5);
        }
        if (imageData && tmpPath.length > 0 && [imageData writeToFile:tmpPath atomically:YES])
        {
            ;
            [array addObject:@{
                @"tempFilePath" : tmpPath,
                @"size" : @([imageData length]),
            }];
        }
    }
    
    result[@"type"] = type;
    result[@"tempFiles"] = array;
    if (viewController.callBack) {
        viewController.callBack(result, nil);
    }
}



- (void)imagePickerController:(TZImagePickerController *)picker
        didFinishPickingVideo:(UIImage *)coverImage
                 sourceAssets:(PHAsset *)asset
{
    WAImagePickerController *viewController = (WAImagePickerController *)picker;
    BOOL isHighQuality = !viewController.shouldCompress;
    //chooseVideo
    if (!viewController.isFromChooseMedia) {
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            [QMUITips showLoading:@"视频处理中..." inView:self.viewController.view];
            [[TZImageManager manager] getVideoOutputPathWithAsset:asset
                                                       presetName:isHighQuality ? AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality
                                                          success:^(NSString *outputPath) {
                [QMUITips hideAllTips];
                AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:outputPath] options:nil];
                AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                CGSize videoSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
                CMTime time = [avAsset duration];
                NSInteger second = ceil(time.value / time.timescale);
                NSDictionary *dic = @{
                    @"tempFilePath"    : outputPath ? : @"",
                    @"duration"        : @(ceil(second)),
                    @"size"            : @([FileUtils getFileSize:outputPath]),
                    @"height"          : @(fabs(videoSize.height)),
                    @"width"           : @(fabs(videoSize.width)),
                };
                if (viewController.callBack) {
                    viewController.callBack(dic, nil);
                }
            } failure:^(NSString *errorMessage, NSError *error) {
                if (viewController.callBack) {
                    viewController.callBack(nil, error);
                }
            }];
        }
        return;
    } else {
        //chooseMeida
        NSMutableDictionary *result = [NSMutableDictionary dictionary];
        NSMutableArray *array = [NSMutableArray array];
        NSString *type = @"video";
        [QMUITips showLoading:@"视频处理中..." inView:self.viewController.view];
        [[TZImageManager manager] getVideoOutputPathWithAsset:asset
                                                   presetName:isHighQuality ? AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality
                                                      success:^(NSString *outputPath) {
            NSString *thumbTempFilePath = [[outputPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
            NSData *imageDate = UIImageJPEGRepresentation(coverImage, 0.8);
            [imageDate writeToFile:thumbTempFilePath atomically:YES];
            [QMUITips hideAllTips];
            AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:outputPath] options:nil];
            AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
            CGSize videoSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
            CMTime time = [avAsset duration];
            NSInteger second = ceil(time.value / time.timescale);
            NSDictionary *dic = @{
                @"tempFilePath"     : outputPath ? : @"",
                @"duration"         : @(ceil(second)),
                @"size"             : @([FileUtils getFileSize:outputPath]),
                @"height"           : @(fabs(videoSize.height)),
                @"width"            : @(fabs(videoSize.width)),
                @"thumbTempFilePath": thumbTempFilePath
            };
            [array addObject:dic];
            result[@"type"] = type;
            result[@"tempFiles"] = array;
            if (viewController.callBack) {
                viewController.callBack(result, nil);
            }
        } failure:^(NSString *errorMessage, NSError *error) {
            if (viewController.callBack) {
                viewController.callBack(nil, error);
            }
        }];
        
    }
}



- (void)_pickerFailWithDomain:(NSString *)domain
                      message:(NSString *)errorMsg
            completionHandler:(void (^)(NSDictionary * _Nullable, NSError * _Nullable))completionHandler
{
    NSDictionary *resultDict = @{@"errMsg" : errorMsg};
    NSError *error = [NSError errorWithDomain:domain code:-1 userInfo:@{NSLocalizedDescriptionKey : errorMsg}];
    if (completionHandler) {
        completionHandler(resultDict, error);
    }
}


#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    // 系统11以上，选图器预览页左边缘无法点击，引用网络解决办法
    if ([UIDevice currentDevice].systemVersion.floatValue < 11.0) {
        return;
    }
    if ([viewController isKindOfClass:NSClassFromString(@"PUPhotoPickerHostViewController")]) {
        [viewController.view.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.frame.size.width < 42) {
                [viewController.view sendSubviewToBack:obj];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    if ( ![picker isKindOfClass:[MACameraPickerController class]] )
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    MACameraPickerController *cameraPicker = (MACameraPickerController *)picker;
    if (picker.cameraCaptureMode == UIImagePickerControllerCameraCaptureModePhoto)
    {
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        if (originalImage == nil)
        {
            NSString *domain = cameraPicker.isFromChooseMedia ? @"chooseMedia" : @"chooseImage";
                          
            [self _pickerFailWithDomain:domain
                                message:@"fail to take photo"
                      completionHandler:cameraPicker.callBack];
            [cameraPicker dismissViewControllerAnimated:YES completion:nil];
            return;
        }
        NSData *imageData = nil;
        CGFloat compressionQuality = cameraPicker.shouldCompress ? 0.2 : 0.5;
        imageData = UIImageJPEGRepresentation(originalImage, compressionQuality);
        NSString *tmpPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"%@.jpg",[[[NSUUID UUID] UUIDString] lowercaseString]]];
        if (imageData && tmpPath.length > 0)
        {
            if ([imageData writeToFile:tmpPath atomically:YES]) {
                //chooseImage 返回格式
                NSDictionary *photoDict = @{
                    @"path" : tmpPath,
                    @"size" : @([imageData length]),
                };
                NSDictionary *resultDic = @{
                    @"tempFiles" : @[photoDict],
                    @"tempFilePaths": @[tmpPath]
                };
                //chooseMedia 返回格式
                if (cameraPicker.isFromChooseMedia) {
                    photoDict = @{
                        @"tempFilePath" : tmpPath,
                        @"size" : @([imageData length]),
                    };
                    resultDic = @{
                        @"type": @"image",
                        @"tempFiles": @[photoDict]
                    };
                }
                if (cameraPicker.callBack)
                {
                    cameraPicker.callBack(resultDic,nil);
                }
            } else {
                NSString *domain = cameraPicker.isFromChooseMedia ? @"chooseMedia" : @"chooseImage";
                [self _pickerFailWithDomain:domain
                 message:@"fail to write photo to disk" completionHandler:cameraPicker.callBack];
            }
            
        } else {
            NSString *domain = cameraPicker.isFromChooseMedia ? @"chooseMedia" : @"chooseImage";
            [self _pickerFailWithDomain:domain
                                message:@"fail to take photo"
                      completionHandler:cameraPicker.callBack];
        }
    } else {
        NSURL *mediaUrl = info[@"UIImagePickerControllerMediaURL"];
        if (mediaUrl == nil) {
            NSString *domain = cameraPicker.isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
            [self _pickerFailWithDomain:domain
                                message:@"can not take this media"
                      completionHandler:cameraPicker.callBack];
            return;
        }
        
        /** isHighQuality决定转换视频格式时是否要压缩
         *  1、如果是拍摄，拍摄时参数已经设置过是否压缩
         *  2、如果是相册，根据保存的参数shouldCompress决定是否要进一步压缩
         */
        BOOL isHighQuality = picker.sourceType == UIImagePickerControllerSourceTypeCamera ||
        cameraPicker.shouldCompress == NO;
        [self beginConvertVideo:mediaUrl
              isFromChooseMedia:cameraPicker.isFromChooseMedia
                  isHighQuality:isHighQuality
                   withCallback:cameraPicker.callBack];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if ( ![picker isKindOfClass:[MACameraPickerController class]] )
    {
        [picker dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    MACameraPickerController *cameraPicker = (MACameraPickerController *)picker;
    NSString *domain = cameraPicker.isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
    [self _pickerFailWithDomain:domain
                        message:@"cancel"
              completionHandler:cameraPicker.callBack];
    [picker dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - 压缩视频
- (void)beginConvertVideo:(NSURL *)videoUrl
        isFromChooseMedia:(BOOL)isFromChooseMedia
            isHighQuality:(BOOL)isHighQuality
             withCallback:(void(^)(NSDictionary *_Nullable result, NSError *_Nullable error))completionHandler
{
    [QMUITips showLoading:@"视频处理中..." inView:self.viewController.view];
    NSString *compressPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                              [[videoUrl.lastPathComponent stringByDeletingPathExtension]
                               stringByAppendingPathExtension:@"mp4"]];
    if (compressPath.length == 0) {
        if (completionHandler) {
            NSString *domain = isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
            completionHandler(nil,[NSError errorWithDomain:domain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"compress video fail"
                
            }]);
        }
        return;
    }
    NSURL *compressUrl = [NSURL fileURLWithPath:compressPath];
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset
                                                                           presetName:isHighQuality ?
                                                   AVAssetExportPresetHighestQuality : AVAssetExportPresetMediumQuality];
    exportSession.outputURL = compressUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        [QMUITips hideAllTips];
        switch (exportSession.status) {
            case AVAssetExportSessionStatusCompleted:
            {
                AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoUrl options:nil];
                AVAssetTrack *videoTrack = [avAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
                CGSize videoSize = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
                CMTime time = [avAsset duration];
                NSInteger second = ceil(time.value / time.timescale);
                NSFileManager *fileManager = [NSFileManager defaultManager];
                CGFloat size = 0.0;
                if ([fileManager fileExistsAtPath:videoUrl.path]) {
                    NSDictionary *fileDic = [fileManager attributesOfItemAtPath:videoUrl.path error:nil];// 获取文件的属性
                    size = [[fileDic objectForKey:NSFileSize] doubleValue];
                }
                //chooseVideo 返回格式
                NSDictionary *resultDict = @{
                                             @"tempFilePath"    : compressPath ? : @"",
                                             @"duration"        : @(second),
                                             @"size"            : @(size),
                                             @"height"          : @(fabs(videoSize.height)),
                                             @"width"           : @(fabs(videoSize.width)),
                                             };
                //chooseMedia 返回格式
                if (isFromChooseMedia) {
                    NSError *error = nil;
                    UIImage *thumbImage = [WAMediaUtils queryVideoImageOfFile:[videoUrl path]
                                               withTime:CMTimeMake(1, time.timescale)
                                                  error:&error];
                    if (thumbImage && !error) {
                        NSString *thumbImagePath = [[[videoUrl path] stringByDeletingLastPathComponent]
                                                    stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
                        NSData *thumbData = UIImageJPEGRepresentation(thumbImage, 0.8);
                        [thumbData writeToFile:thumbImagePath atomically:YES];
                        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:resultDict];
                        dic[@"thumbTempFilePath"] = thumbImagePath;
                        resultDict = @{
                            @"type": @"video",
                            @"tempFiles": @[dic]
                        };
                    } else {
                        if (completionHandler) {
                            NSString *domain = isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
                            completionHandler(nil,[NSError errorWithDomain:domain code:-1 userInfo:@{
                                NSLocalizedDescriptionKey: @"fail to get thumb image"
                                
                            }]);
                        }
                        return;
                    }
                }
                if (completionHandler) {
                    completionHandler(resultDict,nil);
                }

            }
                break;
            default:
                if (completionHandler) {
                    NSString *domain = isFromChooseMedia ? @"chooseMedia" : @"chooseVideo";
                    completionHandler(nil,[NSError errorWithDomain:domain code:-1 userInfo:@{
                        NSLocalizedDescriptionKey: @"compress video fail"
                        
                    }]);
                }
                break;
        }
    }];
}


#pragma mark - previewImages
- (void)previewImages:(NSArray<NSString *> *)urls withCurrentIndex:(NSUInteger)index
{
    self.imageUrls = urls;
    if (!self.imagePreviewViewController) {
        self.imagePreviewViewController = [[QMUIImagePreviewViewController alloc] init];
        self.imagePreviewViewController.presentingStyle = QMUIImagePreviewViewControllerTransitioningStyleZoom;
        // 将 present 动画改为 zoom，也即从某个位置放大到屏幕中央。默认样式为 fade。
        self.imagePreviewViewController.imagePreviewView.delegate = self;
        // 将内部的图片查看器 delegate 指向当前 viewController，以获取要查看的图片数
    }
    
    self.imagePreviewViewController.imagePreviewView.currentImageIndex = index;// 默认展示的图片 index
    
    [self.viewController presentViewController:self.imagePreviewViewController animated:YES completion:nil];
}


#pragma mark - <QMUIImagePreviewViewDelegate>

- (NSUInteger)numberOfImagesInImagePreviewView:(QMUIImagePreviewView *)imagePreviewView {
    return self.imageUrls.count;
}

- (void)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView
     renderZoomImageView:(QMUIZoomImageView *)zoomImageView atIndex:(NSUInteger)index {
    zoomImageView.maximumZoomScale = 3.0;
    zoomImageView.reusedIdentifier = @(index);
    [zoomImageView showLoading];
    NSURL *imageUrl = [NSURL URLWithString:self.imageUrls[index]];
    if (![self.imageUrls[index] containsString:@"http"]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __block UIImage *image = [UIImage imageWithContentsOfFile:self.imageUrls[index]];
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (!image) {
                    image = [UIImage imageNamed:@"download_failed"];
                }
                if ([zoomImageView.reusedIdentifier isEqual:@(index)]) {
                    [zoomImageView hideEmptyView];
                    zoomImageView.image = image;
                }
            });
        });
    } else {
        [NetworkHelper loadImageWithURL:imageUrl
                               progress:nil
                              completed:^(UIImage * _Nullable image,
                                          NSData * _Nullable data,
                                          NSError * _Nullable error,
                                          BOOL finished,
                                          NSURL * _Nullable imageURL) {
            if ([zoomImageView.reusedIdentifier isEqual:@(index)]) {
                [zoomImageView hideEmptyView];
                zoomImageView.image = image;
                //可根据图片大小动态调整maximumZoomScale
            }
        }];
    }
}

- (QMUIImagePreviewMediaType)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView
                             assetTypeAtIndex:(NSUInteger)index {
    return QMUIImagePreviewMediaTypeImage;
}

- (void)imagePreviewView:(QMUIImagePreviewView *)imagePreviewView didScrollToIndex:(NSUInteger)index {
    
}



#pragma mark - <QMUIZoomImageViewDelegate>

- (void)singleTouchInZoomingImageView:(QMUIZoomImageView *)zoomImageView location:(CGPoint)location {
    // 退出图片预览
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}





- (void)openDocument:(NSString *)path
            showMenu:(BOOL)showMenu
            fileType:(NSString *)fileType
             success:(void(^)(NSDictionary *_Nullable))successBlock
                fail:(void(^)(NSError *_Nullable))failBlock
{
    NSURL *URL = [NSURL fileURLWithPath:path];
    if (URL) {
       _documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:URL];
       // Configure Document Interaction Controller
       [_documentInteractionController setDelegate:self];
       _documentInteractionController.name = [path lastPathComponent];
        _documentInteractionController.UTI = fileType;
       // Preview PDF
       //若不能直接打开，则选择其他引用打开
       if (![_documentInteractionController presentPreviewAnimated:YES]) {
           [_documentInteractionController presentOpenInMenuFromRect:self.viewController.view.frame
                                                              inView:self.viewController.view animated:YES];
       }
    }
}



#pragma mark - Document Interaction Controller Delegate Methods
- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller {
    return self.viewController;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller
{
    _documentInteractionController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    _documentInteractionController = nil;
}


@end
