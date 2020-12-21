//
//  ProURLHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/22.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "ProURLHandler.h"
#import "FileUtils.h"
#import "PathUtils.h"

@implementation ProURLHandler

- (NSURL *)URLByPath:(NSString *)path
{
    
    if ([path hasPrefix:@"http"]) {
        return [NSURL URLWithString:path];
    }
    //去掉query，先从document文件夹里面找Z
    NSString *urlPath = kStringContainString(path, @"?") ? [[path componentsSeparatedByString:@"?"] firstObject] :path;
    NSString *filePath = [[PathUtils webFilePath] stringByAppendingPathComponent:urlPath];
    if ([FileUtils isValidFile:filePath]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",[[PathUtils webFilePath] stringByAppendingPathComponent:path]]];
    }
    
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"H5" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    filePath = [bundle.bundlePath stringByAppendingPathComponent:urlPath];
    //添加query
    if ([FileUtils isValidFile:filePath]) {
        return [NSURL URLWithString:[NSString stringWithFormat:@"file://%@",[bundle.bundlePath stringByAppendingPathComponent:path]]];
    }
    return nil;
}

- (BOOL)handleRequest:(NSURLRequest *)request
{
    return YES;
}


@end
