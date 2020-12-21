//
//  NetworkHelper.m
//  weapps
//
//  Created by tommywwang on 2020/6/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "NetworkHelper.h"
#import <SDWebImage/SDWebImage.h>
#import "AFNetworking.h"

@implementation NetworkHelper

+ (void)loadImageWithURL:(NSURL *)URL
                progress:(void(^)(NSInteger receivedSize,
                                  NSInteger expectedSize,
                                  NSURL * _Nullable targetURL))progressBlock
               completed:(void(^)(UIImage * _Nullable image,
                                  NSData * _Nullable data,
                                  NSError * _Nullable error,
                                  BOOL finished,
                                  NSURL * _Nullable imageURL))completeBlock
{
    [[SDWebImageManager sharedManager] loadImageWithURL:URL
                                                options:SDWebImageLowPriority | SDWebImageContinueInBackground | SDWebImageScaleDownLargeImages
                                               progress:progressBlock
                                              completed:^(UIImage * _Nullable image,
                                                          NSData * _Nullable data,
                                                          NSError * _Nullable error,
                                                          SDImageCacheType cacheType,
                                                          BOOL finished,
                                                          NSURL * _Nullable imageURL) {
        if (completeBlock) {
            completeBlock(image,data,error,finished,imageURL);
        }
    }];
}


+ (void)downloadFileWithRequest:(NSURLRequest *)request
                       progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                    destination:(NSURL * (^)(NSURL *targetPath,
                                             NSURLResponse *response))destination
              completionHandler:(void (^)(NSURLResponse *response,
                                          NSURL *filePath,
                                          NSError *error))completionHandler
{
    AFHTTPSessionManager*session = [AFHTTPSessionManager manager];
    session.requestSerializer= [AFHTTPRequestSerializer serializer];
    session.responseSerializer= [AFHTTPResponseSerializer serializer];
    [[session downloadTaskWithRequest:request
                             progress:downloadProgressBlock
                          destination:destination
                    completionHandler:completionHandler] resume];
}


+ (void)uploadFileWithRequest:(NSURLRequest *)request
                     fromFile:(NSURL *)URL
                     progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
            completionHandler:(void (^)(NSURLResponse * _Nonnull response,
                                        id  _Nullable responseObject,
                                        NSError * _Nullable error))completionHandler
{
    AFHTTPSessionManager*session = [AFHTTPSessionManager manager];
    session.requestSerializer= [AFHTTPRequestSerializer serializer];
    session.responseSerializer= [AFHTTPResponseSerializer serializer];
    [[session uploadTaskWithRequest:request
                           fromFile:URL
                           progress:uploadProgressBlock
                  completionHandler:completionHandler] resume];
}

+ (void)abortDownloadTaskWithURL:(NSURL *)URL
{
    AFHTTPSessionManager*session = [AFHTTPSessionManager manager];
    for (NSURLSessionDownloadTask *task in session.downloadTasks) {
        if (kStringEqualToString(task.originalRequest.URL.absoluteString, URL.absoluteString)) {
            [task cancel];
        }
    }
}

+ (void)abortUploadTaskWithURL:(NSURL *)URL
{
    AFHTTPSessionManager*session = [AFHTTPSessionManager manager];
    for (NSURLSessionDownloadTask *task in session.uploadTasks) {
       if (kStringEqualToString(task.originalRequest.URL.absoluteString, URL.absoluteString)) {
           [task cancel];
       }
    }
}


+ (void)checkH5BundleVersion
{
    
}

@end
