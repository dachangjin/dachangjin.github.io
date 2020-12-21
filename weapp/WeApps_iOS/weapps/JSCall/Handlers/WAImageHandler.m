//
//  WAImageHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAImageHandler.h"
#import <Photos/Photos.h>
#import "AuthorizationCheck.h"
#import "FileUtils.h"
#import "NSData+Base64.h"
#import "AFNetworking.h"
#import "PathUtils.h"
#import "NSString+Base64.h"
#import "NetworkHelper.h"
#import "QMUIKit.h"
#import "FileUtils.h"
#import "LCActionSheet.h"


   
typedef NS_OPTIONS(NSUInteger, WAChooseImageSourceType) {
    WAChooseImageSourceTypeNotDefine        = 0,
    WAChooseImageSourceTypeCamera           = 1 << 0,
    WAChooseImageSourceTypeAlbum            = 1 << 1,
};

typedef NS_OPTIONS(NSUInteger, WAChooseImageSizeType) {
    WAChooseImageSizeTypeNotDefine          = 0,
    WAChooseImageSizeTypeCompressed         = 1 << 0,
    WAChooseImageSizeTypeOriginal           = 1 << 1,
};

kSELString(saveImageToPhotosAlbum)
kSELString(previewImage)
kSELString(getImageInfo)
kSELString(compressImage)
kSELString(chooseImage)
kSELString(getBase64Image)
kSELString(saveBase64Image)

static NSDictionary *orientationDicInfo = nil;


@implementation WAImageHandler

+ (NSDictionary *)orientationDicInfo
{
    if (!orientationDicInfo) {
        orientationDicInfo = @{
            @(1): @"up",
            @(2): @"up-mirrored",
            @(3): @"down",
            @(4): @"down-mirrored",
            @(5): @"left-mirrored",
            @(6): @"right",
            @(7): @"right-mirrored",
            @(8): @"left",
        };
    }
    return orientationDicInfo;
}

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            saveImageToPhotosAlbum,
            previewImage,
            getImageInfo,
            compressImage,
            chooseImage,
            getBase64Image,
            saveBase64Image
        ];
    }
    return methods;
}

JS_API(saveImageToPhotosAlbum){
    if (![AuthorizationCheck photoLibraryAuthorizationCheck]) {
        if (event.fail) {
            kFailWithError(saveImageToPhotosAlbum, -1, @"没有相册使用权限")
        }
        return @"";
    }
    
    kBeginCheck
    kCheck([NSString class], @"filePath", YES)
    kEndCheck([NSString class], @"url", YES)
    
    BOOL success = NO;
    NSString *filePath = event.args[@"filePath"];
    NSString *url = event.args[@"url"];
    if (!filePath && !url) {
        kFailWithErrorWithReturn(saveImageToPhotosAlbum, -1, @"parameter error: url and filePath should not be null at the same time")
    }

    NSString *base64 = event.args[@"base64"];
    UIImage *image = nil;
    if (filePath && kStringContainString([FileUtils getFileMimeType:filePath], @"image")) {
        success = YES;
        image = [UIImage imageWithContentsOfFile:filePath];
    } else if (url) {
        [self _downloadImageWithEvent:event
                            UrlString:url];
        return @"";
    } else {
        image = [UIImage imageWithData:[NSData dataWithBase64String:base64]];
        if (image) {
            success = YES;
        }
    }
    if (!success) {
        kFailWithError(saveImageToPhotosAlbum, -1, @"invalid filePath")
        return @"";
    }
    [self _saveImageToLibrary:image
                    withEvent:event
                   completion:^(BOOL success, NSError * _Nullable error) {
       if (success) {
           kSuccessWithDic(@{@"info": @"成功保存到相册"})
       } else {
           [self event:event failWithError:error];
       }
    }];
    return @"";
}

JS_API(previewImage){
    
    kBeginCheck
    kCheck([NSArray class], @"urls", NO)
    kEndCheck([NSString class], @"current", YES)
    
    NSArray *urls = event.args[@"urls"];
    if (!urls.count) {
        kFailWithError(previewImage, -1, @"urls: urls.count should not be 0")
        return @"";
    }
    NSString *currentUrl = event.args[@"current"];
    NSUInteger index = 0;
    if (currentUrl) {
        for (NSUInteger i = 0; i < urls.count; i++) {
            NSString *url = urls[i];
            if (kStringContainString(url, currentUrl)) {
                index = i;
                break;
            }
        }
    }
    [event.webView.webHost previewImages:urls withCurrentIndex:index];
    return @"";
}

JS_API(getImageInfo){
    
    kBeginCheck
    kEndCheck([NSString class], @"src", NO)
    
    NSString *imageSrc = event.args[@"src"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imageContent;
        NSString *absPath;
        if ([imageSrc hasPrefix:@"http://"] || [imageSrc hasPrefix:@"https://"]) {
            imageContent = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageSrc]];
            NSString *downloadPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[imageSrc MD5String]];
            [imageContent writeToFile:downloadPath atomically:YES];
            absPath = downloadPath;
        } else {
            absPath = imageSrc;
        }
        if ([FileUtils isValidFile:absPath]) {
            kFailWithError(getImageInfo, -1, @"invalid scr")
            return;
        }
        imageContent = [NSData dataWithContentsOfFile:absPath];
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageContent, NULL);
        if (imageSource) {
            CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            NSNumber *width = (__bridge NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
            NSNumber *height = (__bridge NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
            NSNumber *orientation = (__bridge NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyOrientation);
            
            NSString *imageType = [[self class] _contentTypeForImageData:imageContent];
            NSDictionary *resultDic = @{
                                        @"width": width ? : @(0),
                                        @"height": height ? :@(0),
                                        @"path": absPath ? : @(0),
                                        @"orientation": [[self class] orientationDicInfo][orientation] ? : [[self class] orientationDicInfo][@(1)],
                                        @"type": imageType ? : @""
                                        };
            kSuccessWithDic(resultDic)
        } else {
            kFailWithError(getImageInfo, -1, @"file not a image or not exist")
        }
    });
    
    return @"";
}



- (void)_downloadImageWithEvent:(JSAsyncEvent *)event
                      UrlString:(NSString *)url
{
    
    [NetworkHelper loadImageWithURL:[NSURL URLWithString:url]
                           progress:nil
                          completed:^(UIImage * _Nullable image,
                                      NSData * _Nullable data,
                                      NSError * _Nullable error,
                                      BOOL finished,
                                      NSURL * _Nullable imageURL) {
        if (error) {
            [self event:event failWithError:error];
        } else {
            if (image && finished) {
                [self _saveImageToLibrary:image
                                withEvent:event
                               completion:^(BOOL success,
                                            NSError * _Nullable error) {
                    if (success) {
                        kSuccessWithDic(@{@"info": @"成功保存到相册"})
                    } else {
                        [self event:event failWithError:error];
                    }
                }];
            } else {
                kFailWithError(saveImageToPhotosAlbum, -1, @"download image error")
            }
        }
    }];
}


JS_API(compressImage){
    
    kBeginCheck
    kCheck([NSString class], @"src", NO)
    kEndCheck([NSNumber class], @"quality", YES)
    
    NSString *src = event.args[@"src"];
    NSInteger quality = 80;
    if (kWA_DictContainKey(event.args, @"quality")) {
        quality = [event.args[@"quality"] integerValue];
    }
    __block NSString *errorStr = @"";
    __block BOOL success = YES;
    if (!src || ![src isKindOfClass:[NSString class]]) {
       success = NO;
       errorStr = @"src is null";
    }
    if ([FileUtils isValidFile:src]) {
       errorStr = @"invalid src";
    }
    if (quality < 0 || quality > 100) {
       success = NO;
       errorStr = @"invalid quality";
    }
    if (!success && event.fail) {
       event.fail([NSError errorWithDomain:@"compressImage" code:-1
                                  userInfo:@{NSLocalizedDescriptionKey: errorStr}]);
       return @"";
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       WALOG(@"压缩前大小:%lu----压缩比：%f",(unsigned long)[FileUtils getFileSize:src],quality * 1.0 / 100);

       UIImage *image = [UIImage imageWithContentsOfFile:src];
       if (!image) {
           success = NO;
           errorStr = @"image do not exist";
       }
       NSData *imageData = UIImageJPEGRepresentation(image, quality * 1.0 / 100);
       WALOG(@"压缩后大小:%lul",(unsigned long)imageData.length);
       if (!imageData) {
           success = NO;
           errorStr = @"fial to compress image";
       }
       NSString *tempPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
       if ([imageData writeToFile:tempPath atomically:YES]) {
           dispatch_sync(dispatch_get_main_queue(), ^{
               kSuccessWithDic(@{@"tempFilePath": tempPath})
           });
       } else {
           success = NO;
           errorStr = @"fail to write compressed image";
           kFailWithError(compressImage, -1, errorString)
       }
    });
    return @"";
}

JS_API(chooseImage){
    
    kBeginCheck
    kCheck([NSNumber class], @"count", YES)
    kCheck([NSArray class], @"sizeType", YES)
    kEndCheck([NSArray class], @"sourceType", YES)
    
    NSDictionary *params = event.args;
    
    NSArray *sourceTypeArray = params[@"sourceType"];
    WAChooseImageSourceType chooseImageSourcetype = WAChooseImageSourceTypeNotDefine;
    if ([sourceTypeArray containsObject:@"album"]) {
        chooseImageSourcetype |= WAChooseImageSourceTypeAlbum;
    }
    if ([sourceTypeArray containsObject:@"camera"]) {
        chooseImageSourcetype |= WAChooseImageSourceTypeCamera;
    }
    if (sourceTypeArray.count == 0) {
        chooseImageSourcetype |= WAChooseImageSourceTypeCamera;
        chooseImageSourcetype |= WAChooseImageSourceTypeAlbum;
    }
    if (chooseImageSourcetype == WAChooseImageSourceTypeNotDefine) {
        kFailWithError(chooseImage, -1, @"Parameter error")
        return @"";
    }

    NSArray *sizeTypeArray = params[@"sizeType"];
    WAChooseImageSizeType chooseImageSizeType = WAChooseImageSizeTypeNotDefine;
    if (sizeTypeArray.count == 0) {
        chooseImageSizeType |= WAChooseImageSizeTypeOriginal;
        chooseImageSizeType |= WAChooseImageSizeTypeCompressed;
    }
    if ([sizeTypeArray containsObject:@"original"]) {
        chooseImageSizeType |= WAChooseImageSizeTypeOriginal;
    }
    if ([sizeTypeArray containsObject:@"compressed"]) {
        chooseImageSizeType |= WAChooseImageSizeTypeCompressed;
    }
    if (chooseImageSizeType == WAChooseImageSizeTypeNotDefine) {
        kFailWithError(chooseImage, -1, @"Parameter error")
        return @"";
    }

    NSInteger maxSelectCount = 9;
    if (kWA_DictContainKey(params, @"count")) {
        maxSelectCount = [params[@"count"] integerValue];
    }
    // 最多选择9张
    maxSelectCount = MIN(9, maxSelectCount);
    
    [self _chooseImageWithEvent:event
                     sourceType:chooseImageSourcetype
                       sizeType:chooseImageSizeType
                       maxCount:maxSelectCount];
    return @"";
}

JS_API(getBase64Image){
    NSString *path = event.args[@"src"];
    if (![FileUtils isValidFile:path]) {
        kFailWithError(getBase64Image, -1, @"file do not exist")
        return @"";
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [FileUtils getFileContentAtPath:path];
        NSString *base64 = [data base64String];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                kSuccessWithDic((@{@"base64": [NSString stringWithFormat:@"data:image/png;base64,%@",base64]}))
            } else  {
                kFailWithError(getBase64Image, -1, @"fail to read file")
            }
        });
    });
    return @"";
}

JS_API(saveBase64Image){
    NSString *base64 = event.args[@"base64"];
    if (!base64 || ![base64 isKindOfClass:[NSString class]]) {
        kFailWithError(saveBase64Image, -1, @"base64: params invalid")
        return @"";
    }
    NSString *fileName = event.args[@"fileName"];
    NSData *data = [NSData dataWithBase64String:base64];
    if (data) {
        if (!fileName) {
            fileName = [[NSUUID UUID] UUIDString];
        }
        NSString *path = [[PathUtils imagePath] stringByAppendingPathComponent:fileName];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL suc = [data writeToFile:path atomically:YES];
            if (suc) {
                kSuccessWithDic(@{@"path": path})
            } else  {
                kFailWithError(saveBase64Image, -1, @"fail to write file")
            }
        });
    } else  {
        kFailWithError(saveBase64Image, -1, @"fail to exchange base64 to data")
    }
    return @"";
}

//**************************************************************

#pragma mark private
- (void)_saveImageToLibrary:(UIImage *)image
                  withEvent:(JSAsyncEvent *)event
                 completion:(void (^)(BOOL success, NSError * _Nullable error))handler
{
    NSMutableArray *groups = [NSMutableArray array];
    [[QMUIAssetsManager sharedInstance] enumerateAllAlbumsWithAlbumContentType:QMUIAlbumContentTypeOnlyPhoto
                                                                showEmptyAlbum:NO
                                                     showSmartAlbumIfSupported:NO
                                                                    usingBlock:^(QMUIAssetsGroup *resultAssetsGroup) {
        if (resultAssetsGroup) {
            
            [groups addObject:resultAssetsGroup];
        }
    }];
    
    if (groups.count) {
        QMUIImageWriteToSavedPhotosAlbumWithAlbumAssetsGroup(image, [groups firstObject], ^(QMUIAsset *asset, NSError *error) {
            if (asset && !error) {
                if (handler) {
                    handler(YES, nil);
                }
            } else {
                if (handler) {
                    handler(NO, error);
                }
            }
        });
    } else {
        if (handler) {
            handler(NO, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"assetGroup not exist"
            }]);
        }
    }
}


+ (NSString *)_contentTypeForImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return nil;
} // contentTypeForImageData




- (void)_chooseImageWithEvent:(JSAsyncEvent *)event
                   sourceType:(WAChooseImageSourceType)sourceType
                     sizeType:(WAChooseImageSizeType)sizeType
                     maxCount:(NSInteger)maxCount {
    BOOL shouldCompressed = sizeType & WAChooseImageSizeTypeCompressed;
    BOOL showOriginal = sizeType & WAChooseImageSizeTypeOriginal;
    NSMutableArray<NSDictionary *> *titleActionArray = [[NSMutableArray alloc] initWithCapacity:2];
    if (sourceType & WAChooseImageSourceTypeCamera) {
        [titleActionArray addObject:@{
                                      @"title" : @"拍摄",
                                      @"action" : ^{
            [self _openCamera:event
             shouldCompressed:shouldCompressed
                     maxCount:maxCount];
        }
                                      }];
    }
    if (sourceType & WAChooseImageSourceTypeAlbum) {
        [titleActionArray addObject:@{
                                      @"title" : @"从手机相册选择",
                                      @"action" : ^{
            [self _openPickerVC:event
               shouldCompressed:shouldCompressed
                   showOriginal:showOriginal
                       maxCount:maxCount];
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
    
    LCActionSheet *actionSheet = [LCActionSheet sheetWithTitle:nil cancelButtonTitle:@"取消"
                                                       clicked:^(LCActionSheet *actionSheet,
                                                                 NSInteger buttonIndex) {
        if (actionSheet.cancelButtonIndex == buttonIndex) {
            kFailWithError(chooseImage, -1, @" cancel");
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


- (void)_openCamera:(JSAsyncEvent *)event
  shouldCompressed:(BOOL)shouldCompresse
          maxCount:(NSInteger)maxCount
{
    NSDictionary *params = @{
                            @"type"            :       @"image",
                            @"shouldCompress"  :       @(shouldCompresse),
    };
    [event.webView.webHost takeMediaFromCameraWithParams:params completionHandler:^(NSDictionary * _Nullable result, NSError * _Nullable error) {
        if (error) {
            if (event.fail) {
                event.fail(error);
            }
        } else {
            kSuccessWithDic(result);
        }
    }];
}


   
- (void)_openPickerVC:(JSAsyncEvent *)event
     shouldCompressed:(BOOL)shouldCompresse
         showOriginal:(BOOL)showOriginal
             maxCount:(NSInteger)maxCount
{
    NSDictionary *params = @{
                           @"type"            :       @"image",
                           @"showOriginal"    :       @(showOriginal),
                           @"shouldCompress"  :       @(shouldCompresse),
                           @"maxCount"        :       @(maxCount),
                           };
    [event.webView.webHost openPickerControllerWithParams:params completionHandler:^(NSDictionary * _Nullable result, NSError * _Nullable error) {
       if (error) {
            if (event.fail) {
                event.fail(error);
            }
        } else {
            kSuccessWithDic(result);
        }
    }];
}

@end
