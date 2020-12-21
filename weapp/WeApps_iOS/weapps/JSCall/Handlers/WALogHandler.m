//
//  LogHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/15.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALogHandler.h"

static  NSString *const kMethod = @"log";

@implementation WALogHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            kMethod
        ];
    }
    return methods;
}

JS_API(log){
    WALOG(@"web-log - %@", event.args);
    return @"";
}

@end
