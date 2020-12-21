//
//  NSString+UTF8Fixing.m
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#define UTF8_FILLING "A"

#import "NSString+UTF8Fixing.h"

@implementation NSString (UTF8Fixing)

- (nullable NSData *)fix_dataUsingEncoding:(NSStringEncoding)encoding {
    NSData* data = [self dataUsingEncoding:encoding];
    if (data == nil) {
        data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    }
    return data;
}

- (nullable instancetype)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding {
    NSString* str = [self initWithData:data encoding:encoding];
    if (str == nil && NSUTF8StringEncoding == encoding) {
        str = [self initWithData:[NSString UTF8Fixing:data] encoding:encoding];
    }
    return str;
}

+ (NSData *)UTF8Fixing:(NSData *)data {
    NSMutableData *newData = [NSMutableData dataWithData:data];
    int loc = 0;
    char tmpchar;
    while (loc < [newData length]) {
        [newData getBytes:&tmpchar range:NSMakeRange(loc, 1)];
        if ((tmpchar & 0x80) == 0) {
            loc++;
            continue;
        }
        else if ((tmpchar & 0xE0) == 0xC0) {
            loc++;
            if (loc < newData.length) {
                [newData getBytes:&tmpchar range:NSMakeRange(loc, 1)];
                if ((tmpchar & 0xC0) == 0x80) {
                    loc++;
                    continue;
                }
            }
            loc--;
            [newData replaceBytesInRange:NSMakeRange(loc, 1) withBytes:UTF8_FILLING length:1];
            loc++;
            continue;
        }
        else if ((tmpchar & 0xF0) == 0xE0) {
            loc++;
            if (loc < newData.length) {
                [newData getBytes:&tmpchar range:NSMakeRange(loc, 1)];
                if ((tmpchar & 0xC0) == 0x80) {
                    loc++;
                    if (loc < newData.length) {
                        [newData getBytes:&tmpchar range:NSMakeRange(loc, 1)];
                        if ((tmpchar & 0xC0) == 0x80) {
                            loc++;
                            continue;
                        }
                    }
                    loc--;
                }
            }
            loc--;
            [newData replaceBytesInRange:NSMakeRange(loc, 1) withBytes:UTF8_FILLING length:1];
            loc++;
            continue;
        }
        else {
            [newData replaceBytesInRange:NSMakeRange(loc, 1) withBytes:UTF8_FILLING length:1];
            loc++;
            continue;
        }
    }
    return newData;
}

@end
