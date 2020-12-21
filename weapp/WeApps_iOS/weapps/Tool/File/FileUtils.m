//
//  FileUtils.m
//  weapps
//
//  Created by tommywwang on 2020/6/4.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "FileUtils.h"


#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <CoreFoundation/CoreFoundation.h>
#include <sys/stat.h>

@implementation FileUtils


+ (NSString *)documentPath
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)[0];
    return docPath;
}

+(NSData*)calculateFileMD5Digest:(NSString *)filePath {
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if( handle== nil) return nil;
    // file didnt exist
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    BOOL done = NO;
    while(!done) {
        NSData* fileData = [handle readDataOfLength: 102400];
        CC_MD5_Update(&md5, [fileData bytes], (UInt32) [fileData length]);
        if( [fileData length] == 0 ) done = YES;
    }
    [handle closeFile];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSData* data = [[NSData alloc] initWithBytes:digest length:CC_MD5_DIGEST_LENGTH];
    return data;
}

+ (NSData*)calculateFileSHA1Digest:(NSString*)filePath
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if( handle== nil) return nil;
    // file didnt exist
    CC_SHA1_CTX sha1;
    CC_SHA1_Init(&sha1);
    BOOL done = NO;
    while(!done) {
        NSData* fileData = [handle readDataOfLength: 102400];
        CC_SHA1_Update(&sha1, [fileData bytes], (UInt32) [fileData length]);
        if( [fileData length] == 0 ) done = YES;
    }
    [handle closeFile];
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1_Final(digest, &sha1);
    NSData* data = [[NSData alloc] initWithBytes:digest length:CC_SHA1_DIGEST_LENGTH];
    return data;
}


+ (NSString*)getFileMimeType:(NSString*) filePath {
    NSString* ext = [filePath pathExtension];
   
    CFStringRef uit = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)ext, NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (uit, kUTTagClassMIMEType);
    CFRelease(uit);
    return (__bridge NSString *)mimeType;
}

+ (NSTimeInterval)getFileCreateTime:(NSString*) filePath error:(NSError **)error
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isPath = NO;
    if([fm fileExistsAtPath:filePath isDirectory:&isPath]){
        NSError *err = nil;
        if (error != NULL) {
            err = *error;
        }
        NSDictionary *dic = [fm attributesOfItemAtPath:filePath error:&err];
        if (dic) {
            return [dic.fileCreationDate timeIntervalSince1970];
        }
    }
    return 0.0;
}

+ (BOOL)copyFile:(NSString *)filePath to:(NSString *)destination error:(NSError **)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = NO;
    if ([fileManager fileExistsAtPath:filePath]) {
        success = [fileManager copyItemAtPath:filePath
                             toPath:destination
                              error:&err];
    }
    if (error) {
        WALOG(@"拷贝文件时出现问题:%@",[err localizedDescription]);
        return NO;
    }
    return success;
}

+ (BOOL)moveFile:(NSString *)filePath to:(NSString *)destination error:(NSError **)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = NO;
    if ([fileManager fileExistsAtPath:filePath]) {
        success = [fileManager moveItemAtPath:filePath
                             toPath:destination
                              error:&err];
    }
    if (error) {
        WALOG(@"移动文件时出现问题:%@",[err localizedDescription]);
        return NO;
    }
    return success;
}


+ (NSString*)getFileName:(NSString *)filePath {
    return [filePath lastPathComponent];
}


+ (BOOL)deleteFile:(NSString *)filePath error:(NSError **)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = NO;
    if ([fileManager fileExistsAtPath:filePath]) {
        success = [fileManager removeItemAtPath:filePath error:&err];
    }
    if (error) {
        WALOG(@"删除文件时出现问题:%@",[err localizedDescription]);
        return NO;
    }
    return success;
}

+ (BOOL)appendFile:(NSData *)data atPath:(NSString *)filePath withError:(NSError *__autoreleasing  _Nullable *)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    
    @try {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
    } @catch (NSException *exception) {
        err = [NSError errorWithDomain:@"appendFile" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: exception.description
        }];
        [fileHandle closeFile];
        return NO;
    }
    [fileHandle closeFile];
    return YES;
}

+ (BOOL)writeFile:(NSData *)data atPath:(NSString *)filePath withError:(NSError **)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    @try {
        [fileHandle writeData:data];
    } @catch (NSException *exception) {
        err = [NSError errorWithDomain:@"appendFile" code:-1 userInfo:@{
            NSLocalizedDescriptionKey: exception.description
        }];
        [fileHandle closeFile];
        return NO;
    }
    [fileHandle closeFile];
    return YES;
}

+ (UInt64)getFileSize:(NSString *)filePath {
    NSFileManager* fm = [NSFileManager defaultManager];
    UInt64 size = 0;
    BOOL isPath = NO;
    if([fm fileExistsAtPath:filePath isDirectory:&isPath]){
        if(isPath){
            NSArray *items = [fm contentsOfDirectoryAtPath:filePath error:nil];
            for(NSString *item in items){
                size += [FileUtils getFileSize:[filePath stringByAppendingPathComponent:item]];
            }
        }else{
            return [fm attributesOfItemAtPath:filePath error:nil].fileSize;
        }
    }
    return size;
}

+ (BOOL)isValidFile:(NSString *)filePath {
    NSFileManager* fm = [NSFileManager defaultManager];
    return [fm isReadableFileAtPath:filePath] && [fm fileExistsAtPath:filePath];
}

+ (BOOL)isFileExsit:(NSString *)path isDirectory:(BOOL *)isDir
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    if (!isDir) {
        isDir = &isDirectory;
    }
    return [fm fileExistsAtPath:path isDirectory:isDir];
}

+ (BOOL)isFileOrDirExist:(NSString *)path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir;
    return [fm fileExistsAtPath:path isDirectory:&isDir];
}

+ (BOOL)isWritableFileAtPath:(NSString *)path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    return [fm isWritableFileAtPath:path];
}

+ (BOOL)isReadableFileAtPath:(NSString *)path
{
    NSFileManager* fm = [NSFileManager defaultManager];
    return [fm isReadableFileAtPath:path];
}

+ (NSData *)getFileContentAtPath:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

+ (NSArray<NSString *> *)readDirAtPath:(NSString *)path error:(NSError **)error
{
    NSFileManager* fm = [NSFileManager defaultManager];
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    NSArray *array = [fm contentsOfDirectoryAtPath:path error:&err];
    return array;
    
}

+ (BOOL)createFileAtPath:(NSString *)path contents:(nullable NSData *)data attributes:(nullable NSDictionary<NSFileAttributeKey,id> *)attrs
{
    NSFileManager* fm = [NSFileManager defaultManager];
    return [fm createFileAtPath:path contents:data attributes:attrs];
}


+ (NSData *)readFileAtPath:(NSString *)path position:(UInt64)position length:(NSUInteger)length error:(NSError *__autoreleasing  _Nullable *)error
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    if (@available(iOS 13.0, *)) {
        [handle seekToOffset:position error:&err];
    } else {
        [handle seekToFileOffset:position];
    }
    NSData *data;
    if (length > 0) {
        if (@available(iOS 13.0, *)) {
            data = [handle readDataUpToLength:length error:&err];
        }else {
            data = [handle readDataOfLength:length];
        }
    } else {
        if (@available(iOS 13.0, *)) {
            data = [handle readDataToEndOfFileAndReturnError:&err];
        } else {
            data = [handle readDataToEndOfFile];
        }
    }
    return data;
}

+ (NSDictionary *)folderStatAtPath:(NSString *)path recursive:(BOOL)recursive withError:(NSError **)error
{
    NSError *err = nil;
    if (error != NULL) {
        err = *error;
    }
    BOOL isDir;
    [FileUtils isFileExsit:path isDirectory:&isDir];
    if (recursive && isDir) {
        //当 recursive 为 true 且 path 是一个目录的路径时，res.stats 是一个 Object，key 以 path 为根路径的相对路径，value 是该路径对应的 Stats 对象
        NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:&err];
        if (err) {
           return nil;
        }
        NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
        NSString *fileName;
        NSMutableDictionary *stats = [NSMutableDictionary dictionary];
        while (fileName = [filesEnumerator nextObject]) {
           struct stat st;
           int ret = stat([path stringByAppendingPathComponent:fileName].UTF8String, &st);
           if (ret != 0) {
               char buf[256];
               strerror_r(errno, buf, sizeof(buf));
               return nil;
           }
           BOOL isSubDir;
           [FileUtils isFileExsit:[path stringByAppendingPathComponent:fileName] isDirectory:&isSubDir];
           stats[fileName] = @{
                               @"mode"              : @(st.st_mode),
                               @"size"              : @(st.st_size),
                               @"lastAccessedTime"  : @(st.st_atime),
                               @"lastModifiedTime"  : @(st.st_mtime),
                               @"isDirectory"       : @(isSubDir),
                               @"isFile"            : @(!isSubDir)
                               };
        }
        return @{@"stats": stats};
    }
    
    struct stat st;
    int ret = stat(path.UTF8String, &st);
    if (ret != 0) {
        char buf[256];
        strerror_r(errno, buf, sizeof(buf));
        return nil;
    }
    
    NSDictionary *stats = [NSDictionary dictionary];
    stats = @{
                @"mode"              : @(st.st_mode),
                @"size"              : @(st.st_size),
                @"lastAccessedTime"  : @(st.st_atime),
                @"lastModifiedTime"  : @(st.st_mtime),
                @"isDirectory"       : @(isDir),
                @"isFile"            : @(!isDir)
            };
    return @{@"stats": stats};
}
@end
