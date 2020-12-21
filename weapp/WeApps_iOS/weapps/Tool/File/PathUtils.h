//
//  PathUtils.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PathUtils : NSObject


/// 删除文件夹
/// @param dir 文件夹
/// @param error 错误
+ (BOOL)deleteDir:(NSString *)dir error:(NSError **)error;


/// 创建文件夹
/// @param path 文件夹路径
/// @param error 错误
+ (BOOL)createPath:(NSString *)path error:(NSError **)error;


/// 沙盒下document路径
+ (NSString *)documentPath;


/// 沙盒下temp路径
+ (NSString *)tempPath;


/// 沙盒下cache路径
+ (NSString *)cachePath;


/////file文件夹下所有文件信息
+ (NSArray <NSDictionary *>*)filePathInfoWithError:(NSError ** )err;


+ (NSString *)storagePath;
/// 图片路径
+ (NSString *)imagePath;


/// 文件路径
+ (NSString *)filePath;

/// 文件临时路径
+ (NSString *)tempFilePath;

/// H5文件夹
+ (NSString *)webFilePath;

//根据相对H5.bundle/preview路径找到绝对路径
+ (NSString *)h5BundlePathForRelativePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
