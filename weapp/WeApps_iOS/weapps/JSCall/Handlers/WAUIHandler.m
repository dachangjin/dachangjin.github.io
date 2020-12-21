//
//  WAUIHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAUIHandler.h"
#import "QMUITips+Mask.h"
#import "LCActionSheet.h"
#import "WALabel.h"

kSELString(showToast)
kSELString(showModal)
kSELString(showLoading)
kSELString(showActionSheet)
kSELString(hideToast)
kSELString(hideLoading)


@implementation WAUIHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            showToast,
            showModal,
            showLoading,
            showActionSheet,
            hideToast,
            hideLoading
        ];
    }
    return methods;
}

JS_API(showToast){
    
    kBeginCheck
    kCheck([NSString class], @"title", NO)
    kCheck([NSNumber class], @"duration", YES)
    kCheckIsBoolean([NSNumber class], @"mask", YES, YES)
    kCheck([NSString class], @"icon", YES)
    kEndCheck([NSString class], @"image", YES)
    
    NSString *title = event.args[@"title"];
    NSTimeInterval duration = 1.5;
    if (kWA_DictContainKey(event.args, @"duration")) {
        duration = [event.args[@"duration"] doubleValue] / 1000;
    }
    BOOL mask = NO;
    if (kWA_DictContainKey(event.args, @"mask")) {
        mask = [event.args[@"mask"] boolValue];
    }
    NSString *icon = @"success";
    if (kWA_DictContainKey(event.args, @"icon")) {
        icon = event.args[@"icon"];
        
    }
    if (kStringEqualToString(icon, @"success")) {
        [QMUITips showSucceed:title mask:mask inView:[event.webView.webHost currentViewController].view hideAfterDelay:duration];
    } else if (kStringEqualToString(icon, @"loading")) {
        [QMUITips showLoading:title mask:mask inView:[event.webView.webHost currentViewController].view hideAfterDelay:duration];
    } else if (kStringEqualToString(icon, @"none")) {
        [QMUITips showInfo:title mask:mask inView:[event.webView.webHost currentViewController].view hideAfterDelay:duration];
    } else {
        kFailWithError(showToast, -1, @"icon :params invalid")
        return @"";
    }
    if (event.success) {
        event.success(nil);
    }
    return @"";
}


JS_API(showModal){
    
    kBeginCheck
    kCheck([NSString class], @"title", YES)
    kCheck([NSString class], @"content", YES)
    kCheckIsBoolean([NSNumber class], @"showCancel", YES, YES)
    kCheck([NSString class], @"cancelText", YES)
    kCheck([NSString class], @"cancelColor", YES)
    kCheck([NSString class], @"confirmText", YES)
    kEndCheck([NSString class], @"confirmColor", YES)
    
    NSString *title = event.args[@"title"];
    NSString *content = event.args[@"content"];
    BOOL showCancel = YES;
    if (kWA_DictContainKey(event.args, @"showCancel")) {
        showCancel = [event.args[@"showCancel"] boolValue];
    }
    NSString *cancelText = @"取消";
    if (kWA_DictContainKey(event.args, @"cancelText")) {
        cancelText = event.args[@"cancelText"];
    }
    NSString *cancelColorText = @"#000000";
    if (kWA_DictContainKey(event.args, @"cancelColor")) {
        cancelColorText = event.args[@"cancelColor"];
    }
    UIColor *cancelColor = [UIColor qmui_rgbaColorWithHexString:cancelColorText];
    NSString *confirmText = @"确定";
    if (kWA_DictContainKey(event.args, @"confirmText")) {
        confirmText = event.args[@"confirmText"];
    }
    NSString *confirmColorText = @"#576B95";
    if (kWA_DictContainKey(event.args, @"confirmColor")) {
        confirmColorText = event.args[@"confirmColor"];
    }
    UIColor *confirmColor = [UIColor qmui_rgbaColorWithHexString:confirmColorText];
    QMUIDialogViewController *dialogViewController = [[QMUIDialogViewController alloc] init];
    dialogViewController.dialogViewMargins = UIEdgeInsetsMake(40, 20, 20, 20);
    dialogViewController.headerSeparatorColor = nil;
    dialogViewController.headerViewBackgroundColor = UIColorWhite;
    dialogViewController.title = title;
    dialogViewController.titleView.style = QMUINavigationTitleViewStyleSubTitleVertical;
    dialogViewController.titleView.verticalTitleFont = UIFontBoldMake(17);
    dialogViewController.titleTintColor = UIColorBlack;
    if (content) {
        WALabel *label = [[WALabel alloc] qmui_initWithFont:UIFontMake(14) textColor:UIColorGray];
        label.contentEdgeInsets = UIEdgeInsetsMake(0, 20, 20, 20);
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByCharWrapping;
        label.text = content;
        label.font = UIFontBoldMake(17);
        [label sizeToFit];
        dialogViewController.contentView = label;
    }
    if (showCancel) {
        [dialogViewController addCancelButtonWithText:cancelText
                                                block:^(__kindof QMUIDialogViewController * _Nonnull aDialogViewController) {
            kSuccessWithDic((@{
                @"cancel": [NSNumber numberWithBool:YES],
                @"confirm": [NSNumber numberWithBool:NO]
                             }))
        }];
        [dialogViewController.cancelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:[dialogViewController.cancelButton attributedTitleForState:UIControlStateNormal].string attributes:@{NSForegroundColorAttributeName: cancelColor}] forState:UIControlStateNormal];
        [dialogViewController.cancelButton setTitleColor:cancelColor forState:UIControlStateNormal];
        dialogViewController.cancelButton.backgroundColor = [UIColor whiteColor];
        dialogViewController.cancelButton.highlightedBackgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    }
    [dialogViewController addSubmitButtonWithText:confirmText
                                            block:^(QMUIDialogViewController *aDialogViewController) {
        [aDialogViewController hide];
        kSuccessWithDic((@{
            @"cancel": [NSNumber numberWithBool:NO],
            @"confirm": [NSNumber numberWithBool:YES]
                         }))
    }];

    [dialogViewController.submitButton setAttributedTitle:[[NSAttributedString alloc] initWithString:[dialogViewController.submitButton attributedTitleForState:UIControlStateNormal].string attributes:@{NSForegroundColorAttributeName: confirmColor}] forState:UIControlStateNormal];
    [dialogViewController.submitButton setTitleColor:confirmColor forState:UIControlStateNormal];
    dialogViewController.submitButton.backgroundColor = [UIColor whiteColor];
    dialogViewController.submitButton.highlightedBackgroundColor = [UIColor colorWithRed:236 / 255.0
                                                                                   green:236 / 255.0
                                                                                    blue:236 / 255.0 alpha:1.0];
    [dialogViewController show];
    return @"";

}

JS_API(showLoading){
    
    kBeginCheck
    kCheck([NSString class], @"title", YES)
    kEndChecIsBoonlean(@"mask", YES)
    
    NSString *title = event.args[@"title"];
    BOOL mask = NO;
    if (kWA_DictContainKey(event.args, @"mask")) {
        mask = [event.args[@"mask"] boolValue];
    }
    [QMUITips showLoading:title mask:mask inView:[event.webView.webHost currentViewController].view hideAfterDelay:NSTimeIntervalSince1970];
    return @"";

}


JS_API(showActionSheet){

    
    kBeginCheck
    kCheck([NSString class], @"alertText", YES)
    kCheck([NSArray class], @"itemList", NO)
    kEndCheck([NSString class], @"itemColor", YES)
    
    NSArray *itemList = event.args[@"itemList"];
    NSString *alertText = event.args[@"alertText"];
    if (itemList.count > 6) {
        kFailWithError(showActionSheet, -1, @"fail parameter error: itemList.count should not be large than 6")
        return @"";
    }
    NSString *itemColor = @"#000000";
    if (kWA_DictContainKey(event.args, @"itemColor")) {
        itemColor = event.args[@"itemColor"];
    }
    UIColor *color = [UIColor qmui_rgbaColorWithHexString:itemColor];
    if (!color) {
        kFailWithError(showActionSheet, -1, @"itemColor: itemColor invalid")
        return @"";
    }
    LCActionSheet *actionSheet = [LCActionSheet sheetWithTitle:alertText
                                             cancelButtonTitle:@"取消"
                                                       clicked:^(LCActionSheet *actionSheet, NSInteger buttonIndex) {
        if (actionSheet.cancelButtonIndex == buttonIndex) {
            kFailWithError(showActionSheet, -1, @"cancel");
        } else {
            kSuccessWithDic(@{@"tapIndex": [NSNumber numberWithInteger:buttonIndex - 1]
                            })
        }
    } otherButtonTitleArray:itemList];
    actionSheet.buttonColor = color;
    actionSheet.scrolling = NO;
    [actionSheet show];

    return @"";
}

JS_API(hideToast){
    [QMUITips hideAllTips];
    kSuccessWithDic(nil)
    return @"";

}

JS_API(hideLoading){
    [QMUITips hideAllTips];
    kSuccessWithDic(nil)
    return @"";

}

@end
