//
//  PathUtils.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "PathUtils.h"
#import "FileUtils.h"

@implementation PathUtils

+ (BOOL)createPath:(NSString *)path error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (isDir && isExist) {
        return YES;
    }
    NSError *err = nil;
    if (error) {
        err = *error;
    }
    BOOL success = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
    return success;
}



+ (BOOL)deleteDir:(NSString *)dir error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exist = [fileManager fileExistsAtPath:dir isDirectory:&isDir];
    NSError *err = nil;
    if (error) {
        err = *error;
    }
    if(exist && isDir && err != nil){
        BOOL success = YES;
        NSError *error;
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:dir error:&error];
        for (NSString *content in contents) {
            NSString *path = [dir stringByAppendingPathComponent:content];
            exist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
            if(exist){
                if(isDir){
                    success = success && [PathUtils deleteDir:path error:&err];
                }else{
                    success = success && [FileUtils deleteFile:path error:&err];
                }
            }
        }
        return success;
    }else{
        return NO;
    }
}

+ (NSString *)storagePath
{
    NSString *iconPath = [[self documentPath] stringByAppendingPathComponent:@"storage"];
    if (![self _isPathExist:iconPath]) {
        return [self createPath:iconPath error:nil] ? iconPath : nil;
    }
    return iconPath;
}

+ (NSString *)imagePath
{
    NSString *iconPath = [[self documentPath] stringByAppendingPathComponent:@"image"];
    if (![self _isPathExist:iconPath]) {
        return [self createPath:iconPath error:nil] ? iconPath : nil;
    }
    return iconPath;
}

//+ (NSString *)tempImagePath
//{
//    NSString *imagePath = [[self tempPath] stringByAppendingPathComponent:@"image"];
//    if (![self _isPathExist:imagePath]) {
//        return [self createPath:imagePath error:nil] ? imagePath : nil;
//    }
//    return imagePath;
//}

+ (NSString *)filePath
{
    NSString *filePath = [[self documentPath] stringByAppendingPathComponent:@"file"];
    if (![self _isPathExist:filePath]) {
        return [self createPath:filePath error:nil] ? filePath : nil;
    }
    return filePath;
}

+ (NSString *)tempFilePath
{
    NSString *filePath = [[self tempPath] stringByAppendingPathComponent:@"file"];
    if (![self _isPathExist:filePath]) {
        return [self createPath:filePath error:nil] ? filePath : nil;
    }
    return filePath;
}


+ (NSString*)documentPath
{
    return  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)[0];
}

+ (NSString *)tempPath
{
    return NSTemporaryDirectory();
}

+ (NSString *)cachePath
{
    return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSArray <NSDictionary *>*)filePathInfoWithError:(NSError ** )err
{
    NSString *dir = [self filePath];
    NSError *error;
    if (err != NULL) {
        error = *err;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:dir error:&error];
    if (error) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *content in contents) {
       NSString *path = [dir stringByAppendingPathComponent:content];
        BOOL isDir;
        if ([fileManager fileExistsAtPath:path isDirectory:&isDir]) {
            if (isDir) continue;
            NSDictionary *dic = [fileManager attributesOfItemAtPath:path error:&error];
            if (error) {
                return nil;
            }
            if (dic) {
                NSDictionary *infoDic = @{
                    @"filePath": path,
                    @"size": [NSNumber numberWithUnsignedLongLong:dic.fileSize],
                    @"createTime": [NSNumber numberWithDouble:[dic.fileCreationDate timeIntervalSince1970]]
                };
                [array addObject:infoDic];
            }
        }
    }
    return array;
}


+ (NSString *)webFilePath
{
    NSString *filePath = [[self tempPath] stringByAppendingPathComponent:@"web"];
    if (![self _isPathExist:filePath]) {
        return [self createPath:filePath error:nil] ? filePath : nil;
    }
    return filePath;
}

+ (NSString *)h5BundlePathForRelativePath:(NSString *)path
{
    //考虑后期更新文件放到webFilePath，先去webFilePath找
    NSString *urlPath = kStringContainString(path, @"?") ? [[path componentsSeparatedByString:@"?"] firstObject] :path;
    NSString *filePath = [[PathUtils webFilePath] stringByAppendingPathComponent:urlPath];
    if ([FileUtils isValidFile:filePath]) {
        return [[PathUtils webFilePath] stringByAppendingPathComponent:path];
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"H5" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    filePath = [bundle.bundlePath stringByAppendingPathComponent:urlPath];
    //去掉query
    if ([FileUtils isValidFile:filePath]) {
        return filePath;
    }
    return nil;
}

#pragma mark private
+ (BOOL)_isPathExist:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    return (isDir && isExist);
}



@end
