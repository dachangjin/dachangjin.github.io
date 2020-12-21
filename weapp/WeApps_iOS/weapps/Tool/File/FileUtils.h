//
//  FileUtils.h
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileUtils : NSObject


/// 计算文件MD5
/// @param filePath 文件路径
+ (NSData*)calculateFileMD5Digest:(NSString*)filePath;

/// 计算文件SHA1
/// @param filePath 文件路径
+ (NSData*)calculateFileSHA1Digest:(NSString*)filePath;

/// 获取文件mimetype
/// @param filePath 文件路径
+ (NSString*)getFileMimeType:(NSString*) filePath;

/// 获取文件创建时间戳
/// @param filePath 文件路径
+ (NSTimeInterval)getFileCreateTime:(NSString*) filePath error:(NSError **)error;
/// 获取文件名
/// @param filePath 文件路径
+ (NSString*)getFileName:(NSString*) filePath;


/// 获取文件大小，若路径为文件夹，则会获取文件夹大小
/// @param filePath 文件路径
+ (UInt64)getFileSize:(NSString*) filePath;


/// 文件是否可用，是否存在并可读
/// @param filePath 文件路径
+ (BOOL)isValidFile:(NSString*) filePath;


/// 文件是否存在
/// @param path 路径
/// @param isDir 是否为文件夹
+ (BOOL)isFileExsit:(NSString *)path isDirectory:(BOOL *)isDir;

/// 路径是否为文件或文件夹
/// @param path 路径
+ (BOOL)isFileOrDirExist:(NSString *)path;

/// 是否可写
/// @param path 路径
+ (BOOL)isWritableFileAtPath:(NSString *)path;

/// 是否可读
/// @param path 路径
+ (BOOL)isReadableFileAtPath:(NSString *)path;

/// 删除文件
/// @param filePath 文件路径
/// @param error 错误指针
+ (BOOL)deleteFile:(NSString *)filePath error:(NSError **)error;



/// 添加文件到指定路径
/// @param data 文件内容
/// @param filePath 路径
/// @param error 错误
+ (BOOL)appendFile:(NSData *)data atPath:(NSString *)filePath withError:(NSError **)error;


/// 写文件到指定路径
/// @param data 文件内容
/// @param filePath 路径
/// @param error 错误
+ (BOOL)writeFile:(NSData *)data atPath:(NSString *)filePath withError:(NSError **)error;



/// 拷贝文件
/// @param filePath 文件初始路径
/// @param destination 文件目的路径
/// @param error 错误指针
+ (BOOL)copyFile:(NSString *)filePath to:(NSString *)destination error:(NSError **)error;

/// 移动文件
/// @param filePath 文件初始路径
/// @param destination 文件目的路径
/// @param error 错误指针
+ (BOOL)moveFile:(NSString *)filePath to:(NSString *)destination error:(NSError **)error;

/// 获取文件全部内容（大文件慎用）
/// @param path 路径
+ (NSData *)getFileContentAtPath:(NSString *)path;

+ (NSArray<NSString *> *)readDirAtPath:(NSString *)path error:(NSError **)error;

/// 创建文件
/// @param path 文件路径
/// @param data 文件数据
/// @param attrs 文件属性
+ (BOOL)createFileAtPath:(NSString *)path contents:(nullable NSData *)data attributes:(nullable NSDictionary<NSFileAttributeKey,id> *)attrs;

+ (NSData *)readFileAtPath:(NSString *)path position:(UInt64)position length:(NSUInteger)length error:(NSError **)error;

+ (NSDictionary *)folderStatAtPath:(NSString *)path recursive:(BOOL)recursive withError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
