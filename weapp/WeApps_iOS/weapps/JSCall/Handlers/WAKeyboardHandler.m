//
//  WAKeyboardHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAKeyboardHandler.h"

static  NSString *const onKeyboardHeightChange = @"onKeyboardHeightChange";
static  NSString *const offKeyboardHeightChange = @"offKeyboardHeightChange";
static  NSString *const hideKeyboard = @"hideKeyboard";
static  NSString *const getSelectedTextRange = @"getSelectedTextRange";


@implementation WAKeyboardHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            onKeyboardHeightChange,
            offKeyboardHeightChange,
            hideKeyboard,
            getSelectedTextRange
        ];
    }
    return methods;
}

JS_API(onKeyboardHeightChange){
    
    if ([event.webView.webHost respondsToSelector:@selector(addKeyboardChangeCallback:)]) {
        [event.webView.webHost addKeyboardChangeCallback:event.callbacak];
        WALOG(@"onKeyboardHeightChange success")
    } else {
        WALOG(@"onKeyboardHeightChange fail")
    }
    return @"";

}

JS_API(offKeyboardHeightChange){
    
    if ([event.webView.webHost respondsToSelector:@selector(removeKeyboardChangeCallback:)]) {
        [event.webView.webHost removeKeyboardChangeCallback:event.callbacak];
        
    }
    return @"";

}

JS_API(hideKeyboard){
    if ([event.webView.webHost respondsToSelector:@selector(hideKeyboardsuccess:fail:)]) {
        [event.webView.webHost hideKeyboardsuccess:event.success fail:event.fail];
    } else {
        if (event.fail) {
            event.fail(nil);
        }
    }
    return @"";

}



@end
