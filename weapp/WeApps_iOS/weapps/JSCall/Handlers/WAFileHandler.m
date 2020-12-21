//
//  WAFIleHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAFileHandler.h"
#import "FileUtils.h"
#import "PathUtils.h"
#import "Device.h"
#import "JSONHelper.h"
#import "NSData+Base64.h"
#import "ZipArchive.h"

kSELString(saveFile)
kSELString(saveFileSync)
kSELString(removeSavedFile)
kSELString(openDocument)
kSELString(getSavedFileList)
kSELString(getSavedFileInfo)
kSELString(getFileInfo)
kSELString(getFileSize)
kSELString(createFile)
kSELString(createFolder)

static  NSString *const accessFile = @"access";
kSELString(accessSync)
kSELString(appendFile)
kSELString(appendFileSync)
kSELString(copyFile)
kSELString(copyFileSync)
kSELString(mkdir)
kSELString(mkdirSync)
kSELString(readdir)
kSELString(readdirSync)
kSELString(readFile)
kSELString(readFileSync)
static  NSString *const renameFile = @"rename";
kSELString(renameSync)
static  NSString *const removeDir = @"rmdir";
kSELString(rmdirSync)
static  NSString *const unlinkFile = @"unlink";
kSELString(unlinkSync)
kSELString(unzip)
kSELString(writeFile)
kSELString(writeFileSync)
kSELString(stat)
kSELString(statSync)


typedef enum : NSUInteger {
    DigestAlgorithmTypeMD5,
    DigestAlgorithmTypeSHA1,
} DigestAlgorithmType;

static NSArray *getEncodings() {
    static NSArray *encodings = nil;
    if (!encodings) {
        encodings = @[
            @"ascii",
            @"base64",
            @"binary",
            @"hex",
            @"ucs2",
            @"ucs-2",
            @"utf16le",
            @"utf-16le",
            @"utf-8",
            @"utf8",
            @"latin1"
        ];
    }
    return encodings;
}


@implementation WAFileHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            saveFile,
            removeSavedFile,
            openDocument,
            getSavedFileList,
            getSavedFileInfo,
            getFileInfo,
            getFileSize,
            createFile,
            createFolder
        ];
    }
    return methods;
}


JS_API(saveFile){
    
    kBeginCheck
    kEndCheck([NSString class], @"tempFilePath", NO)
    
    NSString *tempFilePath = event.args[@"tempFilePath"];
    NSString *fileName = [tempFilePath lastPathComponent];
    NSString *filePath = event.args[@"filePath"] ?: [[PathUtils filePath] stringByAppendingPathComponent:fileName];
    if (![FileUtils isFileOrDirExist:tempFilePath]) {
        //指定的 tempFilePath 找不到文件
        kFailWithErrorWithReturn(saveFile, -1, @"fail tempFilePath file not exist")
    }
    NSString *fileDir = [filePath stringByDeletingLastPathComponent];
    BOOL isDir;
    if (![FileUtils isFileExsit:fileDir isDirectory:&isDir] || !isDir) {
        //上级目录不存在
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory \"${%@}\"",fileDir];
        kFailWithErrorWithReturn(saveFile, -1, info)
    }
    if (![FileUtils isWritableFileAtPath:fileDir]) {
        //指定的 filePath 路径没有写权限
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open \"{%@}\"",fileDir];
        kFailWithErrorWithReturn(saveFile, -1, info)
    }
    NSError *error;
    if (![FileUtils moveFile:tempFilePath to:filePath error:&error]) {
        NSString *info = error.localizedDescription;
        kFailWithErrorWithReturn(saveFile, -1, info)
    }
    kSuccessWithDic(nil)
    return @"undefined";
}

JS_API(saveFileSync){
    return [self js_saveFile:event];
}

JS_API(removeSavedFile){
    
    kBeginCheck
    kEndCheck([NSString class], @"filePath", NO)
    
    NSString *path = event.args[@"filePath"];
    NSError *error = nil;
    if (![FileUtils isFileOrDirExist:path]) {
        kFailWithErrorWithReturn(removeSavedFile, -1, @"fail file not exist")
    }
    BOOL suc = [FileUtils deleteFile:path error:&error];
    if (suc && !error ) {
        kSuccessWithDic(nil)
        return @"undefined";
    } else {
        kFailWithErrorWithReturn(removeSavedFile, -1, error.localizedDescription)
    }
}

JS_API(openDocument){
    
    kBeginCheck
    kCheck([NSString class], @"filePath", NO)
    kCheckIsBoolean([NSNumber class], @"showMenu", YES, YES)
    kEndCheck([NSString class], @"fileType", YES)
    
    NSString *path = event.args[@"filePath"];
    if (![FileUtils isValidFile:path]) {
        kFailWithError(openDocument, -1, @"文件不存在，请检查filePath是否正确！")
        return @"";
    }
    BOOL showMenu = NO;
    if (event.args[@"showMenu"]) {
        showMenu = [event.args[@"showMenu"] boolValue];
    }
    NSString *fileType = event.args[@"fileType"];
    [event.webView.webHost openDocument:path
                                    showMenu:showMenu
                                    fileType:fileType
                                     success:event.success
                                        fail:event.fail];
    return @"";
}


JS_API(getSavedFileList){
    __block NSString *errorDes = @"";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSArray *fileInfos = [PathUtils filePathInfoWithError:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (fileInfos && error == nil) {
                kSuccessWithDic(@{@"fileList":fileInfos})
            } else {
                errorDes = error.localizedDescription ?: @"fail to get file list";
                kFailWithError(getSavedFileList, -1, errorDes)
            }
        });
    });
    return @"";
}

JS_API(getSavedFileInfo){
    
    kBeginCheck
    kEndCheck([NSString class], @"filePath", NO)
    
    NSString *filePath = event.args[@"filePath"];
    __block BOOL success = YES;
    __block NSString *errorDes = @"";
    if (![FileUtils isValidFile:filePath]) {
        success = NO;
        errorDes = [NSString stringWithFormat:@"file no exist, file {%@}", filePath];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        UInt64 fileSize = [FileUtils getFileSize:filePath];
        UInt64 timestamp = [FileUtils getFileCreateTime:filePath error:&error];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (error == nil) {
                kSuccessWithDic((@{
                    @"size": [NSNumber numberWithUnsignedLongLong:fileSize],
                    @"createTime": [NSNumber numberWithUnsignedLongLong:timestamp]
                                 }))
            } else {
                errorDes = error.localizedDescription ?: @"fail to get file";
                kFailWithError(getSavedFileInfo, -1, errorDes)
            }
        });
    });
    return @"";
}


JS_API(getFileInfo){
    
    kBeginCheck
    kCheck([NSString class], @"filePath", NO)
    kEndCheck([NSString class], @"digestAlgorithm", YES)
    
    NSString *filePath = event.args[@"filePath"];
    NSString *digestAlgorithm = event.args[@"digestAlgorithm"];
    DigestAlgorithmType type = DigestAlgorithmTypeMD5;
    if (kStringEqualToString([digestAlgorithm lowercaseString], @"sha1")) {
        type = DigestAlgorithmTypeSHA1;
    }
    __block BOOL success = YES;
    __block NSString *errorDes = @"";
    if (![FileUtils isValidFile:filePath]) {
        success = NO;
        errorDes = @"fail file not exist";
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UInt64 fileSize = [FileUtils getFileSize:filePath];
        NSData *digestData = nil;
        if (type == DigestAlgorithmTypeMD5) {
            digestData = [FileUtils calculateFileMD5Digest:filePath];
        } else {
            digestData = [FileUtils calculateFileSHA1Digest:filePath];
        }
        NSString *digest = [[NSString alloc] initWithData:digestData encoding:NSUTF8StringEncoding];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if (digest == nil) {
                kSuccessWithDic((@{@"size": [NSNumber numberWithUnsignedLongLong:fileSize],
                                   @"digest": digest
                                 }))
            } else {
                errorDes = @"fail to get file info";
                kFailWithError(getFileInfo, -1, errorDes)
            }
        });
    });
    return @"";
}


JS_API(getFileSize){
    
    kBeginCheck
    kEndCheck([NSString class], @"path", NO)
    
    NSString *path = event.args[@"path"];
    if (![FileUtils isValidFile:path]) {
        kFailWithError(getFileSize, -1, @"fail file not exist")
        return @"";
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UInt64 size = [FileUtils getFileSize:path];
        dispatch_async(dispatch_get_main_queue(), ^{
            kSuccessWithDic(@{@"size": @(size)})
        });
    });
    return @"";
}


JS_API(createFile){
    
    kBeginCheck
    kEndCheck([NSString class], @"fileName", NO)
    
    NSString *fileName = event.args[@"fileName"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *filePath =[[PathUtils filePath] stringByAppendingPathComponent:fileName];
        BOOL suc = [FileUtils createFileAtPath:filePath
                                      contents:nil
                                    attributes:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (suc) {
                kSuccessWithDic(@{@"filePath": filePath})
            } else {
                kFailWithError(createFile, -1, @"fail to create file")
            }
        });
    });
    return @"";
}


JS_API(createFolder){
    
    kBeginCheck
    kEndCheck([NSString class], @"folder", NO)
    
    NSString *folderName = event.args[@"folder"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSString *folderPath = [[PathUtils documentPath] stringByAppendingPathComponent:folderName];
        BOOL suc = [PathUtils createPath:folderPath error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (suc) {
                kSuccessWithDic(@{@"dir": folderPath})
            } else {
                [self event:event failWithError:error];
            }
        });
    });
    return @"";
}


JS_API(access){
    kBeginCheck
    kEndCheck([NSString class], @"path", NO)
    NSString *path = event.args[@"path"];
    BOOL isAccess = [FileUtils isFileOrDirExist:path];
    if (isAccess) {
        kSuccessWithDic(nil)
        return @"undefined";
    } else {
        NSString *info = [NSString stringWithFormat:@"accessSync: fail no such file or directory, access %@",path];
        kFailWithErrorWithReturn(accessFile, -1, info)
    }
}

JS_API(accessSync){
    return [self js_access:event];
}

JS_API(appendFile){
    kBeginCheck
    kCheck([NSString class], @"filePath", NO)
    kEndCheck([NSString class], @"encoding", YES)
    id data = event.args[@"data"];
    if (!([data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSData class]])) {
        NSString *info = [NSString stringWithFormat:@"parameter error: paremeter.data should be string or ArrayBuffer instead of %@", [self jsTypeOfObject:data]];
        kFailWithErrorWithReturn(appendFile, -1, info)
    }
    NSString *filePath = event.args[@"filePath"];
    NSString *encoding = event.args[@"encoding"];
    NSArray *encodings = getEncodings();
    if (encoding && ![encodings containsObject:encoding]) {
        //encoding格式错误
        NSString *info = [NSString stringWithFormat:@"fail unsupported encoding,{%@}", encoding];
        kFailWithErrorWithReturn(appendFile, -1, info)
    }
    if (encoding) {
        encoding = @"utf8";
    }
    BOOL isDir;
    BOOL isExist = [FileUtils isFileExsit:filePath isDirectory:&isDir];
    //文件是否存在
    if (!isExist) {
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, open ${%@}",filePath];
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
    //是否文件夹
    if (isDir) {
        NSString *info = [NSString stringWithFormat:@"fail illegal operation on a directory, open ${%@}",filePath];
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
    //是否可写
    if ([FileUtils isWritableFileAtPath:filePath]) {
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}",filePath];
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
    NSError *error;
    NSData *fileData = [self parsingSavedDataWithData:data WithEncodingType:encoding];
    BOOL success = [FileUtils appendFile:fileData atPath:filePath withError:&error];
    if (success) {
        kSuccessWithDic(nil);
        return @"undefined";
    } else {
        NSString *info = error.description ?: [NSString stringWithFormat:@"fail to append, append {%@}",filePath];
        kFailWithErrorWithReturn(appendFile, -1, info)
    }
}

JS_API(appendFileSync){
    return [self js_appendFile:event];
}


JS_API(copyFile){
    kBeginCheck
    kCheck([NSString class], @"srcPath", NO)
    kEndCheck([NSString class], @"destPath", NO)
    NSString *srcPath = event.args[@"srcPath"];
    NSString *destPath = event.args[@"destPath"];
    
    BOOL isDir;
    BOOL isExist = [FileUtils isFileExsit:srcPath isDirectory:&isDir];
    //源文件是否存在
    if (!isExist) {
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, copyFile ${%@} -> ${%@}",srcPath, destPath];
        kFailWithErrorWithReturn(copyFile, -1, info);
    }
    //目标路径是否可写
    if ([FileUtils isWritableFileAtPath:destPath]) {
        NSString *info = [NSString stringWithFormat:@"fail permission denied, copyFile ${%@} -> ${%@}",srcPath, destPath];
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
    //手机是否有剩余空间
    UInt64 size = [FileUtils getFileSize:srcPath];
    if (size > [Device systemFreeSize]) {
        NSString *info = @"fail the maximum size of the file storage limit is exceeded";
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
    NSError *error;
    BOOL success = [FileUtils copyFile:srcPath
                                    to:destPath
                                 error:&error];
    if (success) {
        kSuccessWithDic(nil);
        return @"undefined";
    } else {
        NSString *info = error.description;
        kFailWithErrorWithReturn(appendFile, -1, info);
    }
}

JS_API(copyFileSync){
    return [self js_copyFile:event];
}

JS_API(mkdir){
    kBeginCheck
    kCheck([NSString class], @"dirPath", NO)
    kEndChecIsBoonlean(@"recursive", YES)
    NSString *dirPath = event.args[@"dirPath"];
    BOOL recursive = NO;
    if ([event.args[@"recursive"] boolValue]) {
        recursive = YES;
    }
    //是否已经存在
    if ([FileUtils isFileOrDirExist:dirPath]) {
        NSString *info = [NSString stringWithFormat:@"fail file already exists ${%@}", dirPath];
        kFailWithErrorWithReturn(@"mkdir", -1, info)
    }
    //非递归情况下，父路径是否存在
    NSString *parentDir = [dirPath stringByDeletingLastPathComponent];
    if (!recursive && ![FileUtils isFileOrDirExist:parentDir]) {
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory ${%@}", parentDir];
        kFailWithErrorWithReturn(@"mkdir", -1, info)
    }
    //TODO: 权限问题
    
    return @"";
}

JS_API(mkdirSync){
    return [self js_mkdir:event];
}

JS_API(readdir){
    kBeginCheck
    kEndCheck([NSString class], @"dirPath", NO)
    NSString *dirPath = event.args[@"dirPath"];
    
    BOOL isDir;
    //文件夹不存在
    if (![FileUtils isFileExsit:dirPath isDirectory:&isDir]) {
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory ${%@}", dirPath];
        kFailWithErrorWithReturn(@"readdir", -1, info)
    } else if (!isDir){
        //不是文件夹类型
        NSString *info = [NSString stringWithFormat:@"fail not a directory ${%@}", dirPath];
        kFailWithErrorWithReturn(@"readdir", -1, info)
    }
    //文件夹不可读
    if (![FileUtils isReadableFileAtPath:dirPath]) {
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}", dirPath];
        kFailWithErrorWithReturn(@"readdir", -1, info)
    }
    NSError *error;
    NSArray *fileNames = [FileUtils readDirAtPath:dirPath error:&error];
    if (fileNames) {
        kSuccessWithDic(@{
            @"files": fileNames
                        })
        return [JSONHelper exchengeDictionaryToString:fileNames];
    } else {
        NSString *info = error.userInfo[NSLocalizedDescriptionKey] ?: error.localizedFailureReason;
        kFailWithErrorWithReturn(readdir, -1, info)
    }
}

JS_API(readdirSync){
    return [self js_readdir:event];
}

JS_API(readFile){
    kBeginCheck
    kCheck([NSString class], @"filePath", NO)
    kCheck([NSString class], @"encoding", YES)
    kCheck([NSString class], @"position", YES)
    kEndCheck([NSString class], @"length", YES)
    NSString *filePath = event.args[@"filePath"];
    
    BOOL isDir;
    BOOL exist = [FileUtils isFileExsit:filePath isDirectory:&isDir];
    if (!exist || isDir) {
        //不存在或为文件夹
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, open ${%@}", filePath];
        kFailWithErrorWithReturn(readFile, -1, info)
    }
    //不可读
    if (![FileUtils isReadableFileAtPath:filePath]) {
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}", filePath];
        kFailWithErrorWithReturn(readFile, -1, info)
    }
    NSString *encoding = event.args[@"encoding"];
    NSArray *encodings = getEncodings();
    if (encoding && ![encodings containsObject:encoding]) {
        //encoding格式错误
        NSString *info = [NSString stringWithFormat:@"fail unsupported encoding,{%@}", encoding];
        kFailWithErrorWithReturn(readFile, -1, info)
    }
    UInt64 position = [event.args[@"position"] unsignedLongLongValue];
    NSUInteger length = [event.args[@"length"] unsignedIntegerValue];
    
    NSError *error;
    NSData *data = [FileUtils readFileAtPath:filePath position:position length:length error:&error];
    if (!data) {
        NSString *info = [NSString stringWithFormat:@"fail to read file {%@}", filePath];
        kFailWithErrorWithReturn(readFile, -1, info)
    }
    if (encoding) {
        NSString *dataString = [self encodeData:data withEncodingTypeString:encoding];
        kSuccessWithDic(@{
            @"data": dataString
                        })
        return dataString;
    } else {
        NSString *base64String = [data base64String];
        kSuccessWithDic(@{
            @"data": base64String
                        })
        return base64String;
    }
}

JS_API(readFileSync){
    return [self js_readFile:event];
}

JS_API(rename){
    
    kBeginCheck
    kCheck([NSString class], @"oldPath", NO)
    kEndCheck([NSString class], @"newPath", NO)
    NSString *oldPath = event.args[@"oldPath"];
    NSString *newPath = event.args[@"newPath"];
    NSString *desDir = [newPath stringByDeletingLastPathComponent];
    if (![FileUtils isValidFile:oldPath] || ![FileUtils isFileOrDirExist:desDir]) {
        //源文件不存在，或目标文件路径的上层目录不存在
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, rename ${%@} -> ${%@}", oldPath, newPath];
        kFailWithErrorWithReturn(@"rename", -1, info)
    }
    if (![FileUtils isWritableFileAtPath:oldPath]) {
        //源文件不可写
        NSString *info = [NSString stringWithFormat:@"fail permission denied, rename ${%@} -> ${%@}", oldPath, newPath];
        kFailWithErrorWithReturn(@"rename", -1, info)
    }
    
    NSError *error;
    if (![FileUtils moveFile:oldPath to:newPath error:&error]) {
        NSString *info = error.localizedDescription;
        kFailWithErrorWithReturn(@"rename", -1, info)
    }
    kSuccessWithDic(nil)
    return @"undefined";
}

JS_API(renameSync){
    return [self js_rename:event];
}


JS_API(removeDir){
    kBeginCheck
    kCheck([NSString class], @"dirPath", NO)
    kEndChecIsBoonlean(@"recursive", YES)
    
    NSString *dirPath = event.args[@"dirPath"];
    BOOL recursive = NO;
    if ([event.args[@"recursive"] boolValue]) {
        recursive = YES;
    }
    BOOL isDir;
    if (![FileUtils isFileExsit:dirPath isDirectory:&isDir] || !isDir) {
        //不存在文件夹
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory ${%@}",dirPath];
        kFailWithErrorWithReturn(removeDir, -1, info)
    }
    if (![FileUtils isWritableFileAtPath:dirPath]) {
        //不可写
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}",dirPath];
        kFailWithErrorWithReturn(removeDir, -1, info)
    }
    if (!recursive) {
        NSArray *items = [FileUtils readDirAtPath:dirPath error:nil];
        if (items.count) {
            //存在子目录
            kFailWithErrorWithReturn(removeDir, -1, @"fail directory not empty")
        }
    }
    NSError *error;
    if ([FileUtils deleteFile:dirPath error:&error]) {
        kSuccessWithDic(nil)
        return @"undefined";
    }
    NSString *info = error.localizedDescription ?: [NSString stringWithFormat: @"fail to remove dir {%@}",dirPath];
    kFailWithErrorWithReturn(removeDir, -1, info)
}

JS_API(rmdirSync){
    return [self js_removeDir:event];
}


JS_API(unlink){
    kBeginCheck
    kEndCheck([NSString class], @"filePath", NO)
    NSString *filePath = event.args[@"filePath"];
    BOOL isDir;
    if (![FileUtils isFileExsit:filePath isDirectory:&isDir]) {
        //文件不存在
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory ${%@}",filePath];
        kFailWithErrorWithReturn(unlinkFile, -1, info)
    }
    if (isDir) {
        //filePath为一个目录
        NSString *info = [NSString stringWithFormat:@"fail operation not permitted, unlink ${%@}",filePath];
        kFailWithErrorWithReturn(unlinkFile, -1, info)
    }
    if (![FileUtils isWritableFileAtPath:filePath]) {
        //没有写权限
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}",filePath];
        kFailWithErrorWithReturn(unlinkFile, -1, info)
    }
    NSError *error;
    BOOL success = [FileUtils deleteFile:filePath error:&error];
    if (success) {
        kSuccessWithDic(nil)
        return @"undefined";
    }
    NSString *info = error.localizedDescription ?: [NSString stringWithFormat:@"fail to unlink {%@}",filePath];
    kFailWithErrorWithReturn(unlinkFile, -1, info)
}


JS_API(unlinkSync){
    return [self js_unlink:event];
}

JS_API(unzip){
    kBeginCheck
    kCheck([NSString class], @"zipFilePath", NO)
    kEndCheck([NSString class], @"targetPath", NO)
    
    NSString *zipFilePath = event.args[@"zipFilePath"];
    NSString *targetPath = event.args[@"targetPath"];
    NSString *targetDir = [targetPath stringByDeletingLastPathComponent];
    BOOL isDir;
    if (![FileUtils isFileExsit:zipFilePath isDirectory:&isDir] ||
        isDir ||
        ![FileUtils isFileExsit:targetDir isDirectory:&isDir] ||
        !isDir) {
        //源文件不存在，或目标文件路径的上层目录不存在
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, unzip ${%@} -> ${%@}", zipFilePath, targetPath];
        kFailWithErrorWithReturn(unzip, -1, info)
    }
    if (![FileUtils isWritableFileAtPath:targetPath]) {
        //指定目标文件路径没有写权限
        NSString *info = [NSString stringWithFormat:@"fail permission denied, unzip ${%@} -> ${%@}", zipFilePath, targetPath];
        kFailWithErrorWithReturn(unzip, -1, info)
    }
    NSError *error;
    BOOL success = [SSZipArchive unzipFileAtPath:zipFilePath
                    toDestination:targetPath
                        overwrite:YES
                         password:nil
                            error:&error];
    if (success) {
        kSuccessWithDic(nil)
        return @"undefined";
    }
    NSString *info = error.localizedDescription ?: [NSString stringWithFormat:@"fail to unzip, unzip ${%@} -> ${%@}", zipFilePath, targetPath];
    kFailWithErrorWithReturn(unzip, -1, info)
}



JS_API(writeFile){
    kBeginCheck
    kCheck([NSString class], @"filePath", NO)
    kEndCheck([NSString class], @"encoding", YES)
    id data = event.args[@"data"];
    if (!([data isKindOfClass:[NSString class]] || [data isKindOfClass:[NSData class]])) {
        NSString *info = [NSString stringWithFormat:@"parameter error: paremeter.data should be string or ArrayBuffer instead of %@", [self jsTypeOfObject:data]];
        kFailWithErrorWithReturn(writeFile, -1, info)
    }
    NSString *filePath = event.args[@"filePath"];
    NSString *encoding = event.args[@"encoding"];
    NSArray *encodings = getEncodings();
    if (encoding && ![encodings containsObject:encoding]) {
        //encoding格式错误
        NSString *info = [NSString stringWithFormat:@"fail unsupported encoding,{%@}", encoding];
        kFailWithErrorWithReturn(writeFile, -1, info)
    }
    if (encoding) {
        encoding = @"utf8";
    }
    NSString *fileDir = [filePath stringByDeletingLastPathComponent];
    BOOL isDir;
    if (![FileUtils isFileExsit:fileDir isDirectory:&isDir] || !isDir) {
        //指定的 filePath 所在目录不存在
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory, open ${%@}",filePath];
        kFailWithErrorWithReturn(writeFile, -1, info);
    }
    //是否可写
    if ([FileUtils isWritableFileAtPath:fileDir]) {
        NSString *info = [NSString stringWithFormat:@"ail permission denied, open ${%@}",fileDir];
        kFailWithErrorWithReturn(writeFile, -1, info);
    }
    NSError *error;
    NSData *fileData = [self parsingSavedDataWithData:data WithEncodingType:encoding];
    BOOL success = [FileUtils writeFile:fileData atPath:filePath withError:&error];
    if (success) {
        kSuccessWithDic(nil);
        return @"undefined";
    } else {
        NSString *info = error.description ?: [NSString stringWithFormat:@"fail to write file, write {%@}", filePath];
        kFailWithErrorWithReturn(writeFile, -1, info)
    }
    return @"";
}

JS_API(writeFileSync){
    return [self js_writeFile:event];
}

JS_API(stat){
    kBeginCheck
    kCheck([NSString class], @"path", NO)
    kEndChecIsBoonlean(@"recursive", YES)
    
    NSString *path = event.args[@"path"];
    BOOL recursive = [event.args[@"recursive"] boolValue];
    
    if (![FileUtils isFileOrDirExist:path]) {
        NSString *info = [NSString stringWithFormat:@"fail no such file or directory ${%@}", path];
        kFailWithErrorWithReturn(stat, -1, info)
    }
    if (![FileUtils isWritableFileAtPath:path]) {
        NSString *info = [NSString stringWithFormat:@"fail permission denied, open ${%@}", path];
        kFailWithErrorWithReturn(stat, -1, info)
    }
    NSError *error;
    NSDictionary *dict = [FileUtils folderStatAtPath:path
                                           recursive:recursive
                                           withError:&error];
    if (dict) {
        kSuccessWithDic(dict)
        return [JSONHelper exchengeDictionaryToString:dict];
    } else {
        NSString *info = error.localizedDescription ?: @"fail to get stat";
        kFailWithErrorWithReturn(stat, -1, info)
    }
}

JS_API(statSync){
    return [self js_stat:event];
}


#pragma mark private

- (NSString *)encodeData:(NSData *)data withEncodingTypeString:(NSString *)encoding
{
    NSString *filestring;
    if ([encoding isEqualToString:@"utf8"] || [encoding isEqualToString:@"utf-8"]) {
        filestring = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else if ([encoding isEqualToString:@"ascii"]) {
        filestring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    } else if ([encoding isEqualToString:@"base64"]) {
        filestring = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    } else if([encoding isEqualToString:@"ucs2"]
              || [encoding isEqualToString:@"ucs-2"]
              || [encoding isEqualToString:@"utf16le"]
              || [encoding isEqualToString:@"utf-16le"]) {
        filestring = [[NSString alloc] initWithData:data encoding:NSUTF16LittleEndianStringEncoding];
    } else if ([encoding isEqualToString:@"hex"]) {
        NSUInteger capacity = data.length * 2;
        NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
        const unsigned char *buf = data.bytes;
        NSInteger i;
        for (i = 0; i < data.length; ++i) {
            [sbuf appendFormat:@"%02lx", (unsigned long)buf[i]];
        }
        filestring = [sbuf copy];
    } else if([encoding isEqualToString:@"latin1"]) {
        filestring = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    }else if ([encoding isEqualToString:@"binary"]){
        filestring = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    }
    return filestring;
}


/**
 * 获取nsdata 读取param中encoding方式
 *
 * @param data id data
 * @param encodingType type string
 * @return nsdata
 */
- (NSData *)parsingSavedDataWithData:(id)data
                    WithEncodingType:(NSString *)encodingType {
    NSString *encoding = encodingType;
    id objData = data;
    
    NSData *saveData = nil;
    // objData class __NSCFString
    if ([objData isKindOfClass:[NSString class]]) {
        NSStringEncoding encodingType = NSUTF8StringEncoding;
        if ([encoding isEqualToString:@"base64"]) {
            saveData = [[NSData alloc] initWithBase64EncodedString:objData options:NSDataBase64DecodingIgnoreUnknownCharacters];
        } else if ([encoding isEqualToString:@"hex"]) {
            saveData = [WAFileHandler dataFromHexString:objData];
        } else {
            if ([encoding isEqualToString:@"utf8"] // 来源是字符串，目标是二进制，使用utf8编码
                || [encoding isEqualToString:@"utf-8"]) {
                encodingType = NSUTF8StringEncoding;
            } else if ([encoding isEqualToString:@"ascii"]
                       || [encoding isEqualToString:@"binary"]) {
                encodingType = NSNonLossyASCIIStringEncoding;
            } else if ([encoding isEqualToString:@"latin1"]) {
                encodingType = NSISOLatin1StringEncoding;
            } else if ([encoding isEqualToString:@"ucs2"]
                       || [encoding isEqualToString:@"ucs-2"]
                       || [encoding isEqualToString:@"utf16le"]
                       || [encoding isEqualToString:@"utf-16le"]) {
                encodingType = NSUTF16LittleEndianStringEncoding;
            } else {
                // 默认 utf8编码
                encodingType = NSUTF8StringEncoding;
            }
            saveData = [objData dataUsingEncoding:encodingType];
        }
    } else if ([objData isKindOfClass:[NSData class]]) {
        saveData = objData;
    }
    return saveData;
} //parsingSavedDataFromParams

+ (NSData *)dataFromHexString:(NSString *)string
{
    NSMutableData *commandToSend= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < [string length]/2; i++) {
        byte_chars[0] = [string characterAtIndex:i*2];
        byte_chars[1] = [string characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [commandToSend appendBytes:&whole_byte length:1];
    }
    return [commandToSend copy];
}
@end
