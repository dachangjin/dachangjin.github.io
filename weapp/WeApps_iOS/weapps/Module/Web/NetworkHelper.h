//
//  NetworkHelper.h
//  weapps
//
//  Created by tommywwang on 2020/6/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkHelper : NSObject

+ (void)loadImageWithURL:(NSURL *)URL
                progress:(nullable void(^)(NSInteger receivedSize,
                                           NSInteger expectedSize,
                                           NSURL * _Nullable targetURL))progressBlock
               completed:(void(^)(UIImage * _Nullable image,
                                  NSData * _Nullable data,
                                  NSError * _Nullable error,
                                  BOOL finished,
                                  NSURL * _Nullable imageURL))completeBlock;


+ (void)downloadFileWithRequest:(NSURLRequest *)request
                       progress:(void (^)(NSProgress *downloadProgress)) downloadProgressBlock
                    destination:(NSURL * (^)(NSURL *targetPath,
                                             NSURLResponse *response))destination
              completionHandler:(void (^)(NSURLResponse *response,
                                          NSURL *filePath,
                                          NSError *error))completionHandler;


+ (void)uploadFileWithRequest:(NSURLRequest *)request
                     fromFile:(NSURL *)URL
                     progress:(nullable void (^)(NSProgress *uploadProgress))uploadProgressBlock
            completionHandler:(void (^)(NSURLResponse * _Nonnull response,
                                        id  _Nullable responseObject,
                                        NSError * _Nullable error))completionHandler;

+ (void)abortDownloadTaskWithURL:(NSURL *)URL;

+ (void)abortUploadTaskWithURL:(NSURL *)URL;

+ (void)checkH5BundleVersion;


@end

NS_ASSUME_NONNULL_END
