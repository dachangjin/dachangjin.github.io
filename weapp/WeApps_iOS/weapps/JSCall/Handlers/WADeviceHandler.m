//
//  WADeviceHandler.m
//  weapps
//
//  Created by tommywwang on 2020/6/29.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <AudioToolbox/AudioServices.h>
#import <EventKit/EventKit.h>
#import <Contacts/Contacts.h>

#import "WADeviceHandler.h"
#import "Device.h"
#import "JSONHelper.h"
#import "QMUITips+Mask.h"
#import "ScanQRCodeViewController.h"
#import "QRCodeGenerator.h"
#import "NSData+Base64.h"
#import "KeyChainWrap.h"
#import "NSString+UTF8Fixing.h"
#import "AuthorizationCheck.h"
#import "AppInfo.h"
#import "WBQRCodeVC.h"
#import "Weapps.h"


kSELString(addPhoneContact)
kSELString(getBatteryInfoSync)
kSELString(getBatteryInfo)
kSELString(setClipboardData)
kSELString(getClipboardData)
kSELString(getClipboardDataSync)
kSELString(onNetworkStatusChange)
kSELString(offNetworkStatusChange)
kSELString(getNetworkType)
kSELString(getNetworkTypeSync)
kSELString(setScreenBrightness)
kSELString(setKeepScreenOn)
kSELString(onUserCaptureScreen)
kSELString(offUserCaptureScreen)
kSELString(getScreenBrightness)
kSELString(makePhoneCall)
kSELString(sendSms)
kSELString(emailTo)
kSELString(scanCode)
kSELString(createQrCode)
kSELString(vibrateShort)
kSELString(vibrateLong)
kSELString(getScreenHeight)
kSELString(getScreenHeightSync)
kSELString(getScreenWidth)
kSELString(getScreenWidthSync)
kSELString(getSystemFreeSize)
kSELString(getSystemFreeSizeSync)
kSELString(getSimInfo)
kSELString(getDeviceTypeSync)
kSELString(getDeviceIdSync)
kSELString(getSimOperatorName)
kSELString(getSimOperatorNameSync)
kSELString(hasSimCardSync)
kSELString(isNetworkConnectedSync)
kSELString(isWifiConnectedSync)
kSELString(isMobileConnectedSync)
kSELString(addCalendarEvent)

kSELString(startAccelerometer)
kSELString(stopAccelerometer)
kSELString(onAccelerometerChange)
kSELString(offAccelerometerChange)

kSELString(startCompass)
kSELString(stopCompass)
kSELString(onCompassChange)
kSELString(offCompassChange)

kSELString(startDeviceMotionListening)
kSELString(stopDeviceMotionListening)
kSELString(onDeviceMotionChange)
kSELString(offDeviceMotionChange)

kSELString(startGyroscope)
kSELString(stopGyroscope)
kSELString(onGyroscopeChange)
kSELString(offGyroscopeChange)

kSELString(checkIsOpenAccessibility)

kSELString(onMemoryWarning)
kSELString(offMemoryWarning)

kSELString(reverseWebView)

static  NSString *const key = @"deviceKey";


@implementation WADeviceHandler

- (NSArray<NSString *> *)callingMethods
{
    static NSArray *methods = nil;
    if (!methods) {
        methods = @[
            addPhoneContact,
            getBatteryInfoSync,
            getBatteryInfo,
            setClipboardData,
            getClipboardData,
            getClipboardDataSync,
            onNetworkStatusChange,
            offNetworkStatusChange,
            getNetworkType,
            getNetworkTypeSync,
            setScreenBrightness,
            setKeepScreenOn,
            onUserCaptureScreen,
            offUserCaptureScreen,
            getScreenBrightness,
            makePhoneCall,
            sendSms,
            emailTo,
            scanCode,
            createQrCode,
            vibrateLong,
            vibrateShort,
            getScreenHeight,
            getScreenHeightSync,
            getScreenWidth,
            getScreenWidthSync,
            getSystemFreeSize,
            getSystemFreeSizeSync,
            getSimInfo,
            getDeviceTypeSync,
            getDeviceIdSync,
            getSimOperatorName,
            getSimOperatorNameSync,
            hasSimCardSync,
            isNetworkConnectedSync,
            isWifiConnectedSync,
            isMobileConnectedSync,
            addCalendarEvent,
            
            startAccelerometer,
            stopAccelerometer,
            onAccelerometerChange,
            offAccelerometerChange,
            
            startCompass,
            stopCompass,
            onCompassChange,
            offCompassChange,
            
            startDeviceMotionListening,
            stopDeviceMotionListening,
            onDeviceMotionChange,
            offDeviceMotionChange,
            
            startGyroscope,
            stopGyroscope,
            onGyroscopeChange,
            offGyroscopeChange,
            
            checkIsOpenAccessibility,
            
            onMemoryWarning,
            offMemoryWarning,
            
            reverseWebView
        ];
    }
    return methods;
}

JS_API(addPhoneContact){
    kBeginCheck
    kCheck([NSString class], @"firstName", NO)
    kCheck([NSString class], @"photoFilePath", YES)
    kCheck([NSString class], @"nickName", YES)
    kCheck([NSString class], @"lastName", YES)
    kCheck([NSString class], @"middleName", YES)
    kCheck([NSString class], @"remark", YES)
    kCheck([NSString class], @"mobilePhoneNumber", YES)
    kCheck([NSString class], @"weChatNumber", YES)
    kCheck([NSString class], @"addressCountry", YES)
    kCheck([NSString class], @"addressState", YES)
    kCheck([NSString class], @"addressCity", YES)
    kCheck([NSString class], @"addressStreet", YES)
    kCheck([NSString class], @"addressPostalCode", YES)
    kCheck([NSString class], @"organization", YES)
    kCheck([NSString class], @"title", YES)
    kCheck([NSString class], @"workFaxNumber", YES)
    kCheck([NSString class], @"workPhoneNumber", YES)
    kCheck([NSString class], @"hostNumber", YES)
    kCheck([NSString class], @"email", YES)
    kCheck([NSString class], @"url", YES)
    kCheck([NSString class], @"workAddressCountry", YES)
    kCheck([NSString class], @"workAddressState", YES)
    kCheck([NSString class], @"workAddressCity", YES)
    kCheck([NSString class], @"workAddressStreet", YES)
    kCheck([NSString class], @"workAddressPostalCode", YES)
    kCheck([NSString class], @"homeFaxNumber", YES)
    kCheck([NSString class], @"homePhoneNumber", YES)
    kCheck([NSString class], @"homeAddressCountry", YES)
    kCheck([NSString class], @"homeAddressState", YES)
    kCheck([NSString class], @"homeAddressCity", YES)
    kCheck([NSString class], @"homeAddressStreet", YES)
    kEndCheck([NSString class], @"homeAddressPostalCode", YES)
    
    CNMutableContact *contact = [[CNMutableContact alloc] init];
    contact.givenName           = event.args[@"firstName"];
    contact.imageData           = [NSData dataWithContentsOfFile:event.args[@"photoFilePath"]];
    contact.nickname            = event.args[@"nickName"];
    contact.familyName          = event.args[@"lastName"];
    contact.middleName          = event.args[@"middleName"];
    contact.note                = event.args[@"remark"];
    contact.organizationName    = event.args[@"organization"];
    contact.jobTitle            = event.args[@"title"];
    //设置邮箱
    if (event.args[@"email"]) {
        CNLabeledValue *email = [[CNLabeledValue alloc] initWithLabel:CNLabelHome value:event.args[@"email"]];
        contact.emailAddresses = @[email];
    }
    //设置url
    if (event.args[@"url"]) {
        CNLabeledValue *url = [[CNLabeledValue alloc] initWithLabel:CNLabelHome value:event.args[@"email"]];
        contact.urlAddresses = @[url];
    }
    //设置微信号
    if (event.args[@"weChatNumber"]) {
        CNSocialProfile *profile = [[CNSocialProfile alloc] initWithUrlString:nil
                                                                     username:nil
                                                               userIdentifier:event.args[@"weChatNumber"]
                                                                      service:nil];
        CNLabeledValue *wechat = [[CNLabeledValue alloc] initWithLabel:@"微信号" value:profile];
        contact.socialProfiles = @[wechat];
    }
    // 设置电话号码
    NSMutableArray *phones = [NSMutableArray array];
    if (event.args[@"mobilePhoneNumber"]) {
        CNPhoneNumber *mobileNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"mobilePhoneNumber"]];
        CNLabeledValue *mobilePhone = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberMobile value:mobileNumber];
        [phones addObject:mobilePhone];
    }
    //工作电话
    if (event.args[@"workPhoneNumber"]) {
        CNPhoneNumber *workNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"workPhoneNumber"]];
        CNLabeledValue *workPhone = [[CNLabeledValue alloc] initWithLabel:CNLabelWork value:workNumber];
        [phones addObject:workPhone];
    }
    //住宅电话
    if (event.args[@"homePhoneNumber"]) {
        CNPhoneNumber *homeNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"homePhoneNumber"]];
        CNLabeledValue *homePhone = [[CNLabeledValue alloc] initWithLabel:CNLabelHome value:homeNumber];
        [phones addObject:homePhone];
    }
    //公司电话
    if (event.args[@"hostNumber"]) {
        CNPhoneNumber *companyNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"hostNumber"]];
        CNLabeledValue *companyPhone = [[CNLabeledValue alloc] initWithLabel:@"公司电话" value:companyNumber];
        [phones addObject:companyPhone];
    }
    //工作传真
    if (event.args[@"workFaxNumber"]) {
        CNPhoneNumber *workFaxNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"workFaxNumber"]];
        CNLabeledValue *workFax = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberWorkFax value:workFaxNumber];
        [phones addObject:workFax];
    }
    //住宅传真
    if (event.args[@"homeFaxNumber"]) {
        CNPhoneNumber *homeFaxNumber = [[CNPhoneNumber alloc] initWithStringValue:event.args[@"homeFaxNumber"]];
        CNLabeledValue *homeFax = [[CNLabeledValue alloc] initWithLabel:CNLabelPhoneNumberWorkFax value:homeFaxNumber];
        [phones addObject:homeFax];
    }
    contact.phoneNumbers = phones;
    //联系地址
    NSMutableArray *addresses = [NSMutableArray array];
    if (event.args[@"addressCountry"] ||
        event.args[@"addressState"] ||
        event.args[@"addressCity"] ||
        event.args[@"addressStreet"] ||
        event.args[@"addressPostalCode"]) {
        CNMutablePostalAddress *address = [[CNMutablePostalAddress alloc] init];
        address.street = event.args[@"addressStreet"];
        address.country = event.args[@"addressCountry"];
        address.state = event.args[@"addressState"];
        address.city = event.args[@"addressCity"];
        address.postalCode = event.args[@"addressPostalCode"];
        CNLabeledValue *addressLabel = [[CNLabeledValue alloc] initWithLabel:@"联系地址" value:address];
        [addresses addObject:addressLabel];
    }
    //工作地址
    if (event.args[@"workAddressCountry"] ||
        event.args[@"workAddressState"] ||
        event.args[@"workAddressCity"] ||
        event.args[@"workAddressStreet"] ||
        event.args[@"workAddressPostalCode"]) {
        CNMutablePostalAddress *workAddress = [[CNMutablePostalAddress alloc] init];
        workAddress.street = event.args[@"workAddressStreet"];
        workAddress.country = event.args[@"workAddressCountry"];
        workAddress.state = event.args[@"workAddressState"];
        workAddress.city = event.args[@"workAddressCity"];
        workAddress.postalCode = event.args[@"workAddressPostalCode"];
        CNLabeledValue *workAddressValue = [[CNLabeledValue alloc] initWithLabel:CNLabelWork value:workAddress];
        [addresses addObject:workAddressValue];
    }
    //住宅地址
    if (event.args[@"homeAddressCountry"] ||
        event.args[@"homeAddressState"] ||
        event.args[@"homeAddressCity"] ||
        event.args[@"homeAddressStreet"] ||
        event.args[@"homeAddressPostalCode"]) {
        CNMutablePostalAddress *homeAddress = [[CNMutablePostalAddress alloc] init];
        homeAddress.street = event.args[@"homeAddressStreet"];
        homeAddress.country = event.args[@"homeAddressCountry"];
        homeAddress.state = event.args[@"homeAddressState"];
        homeAddress.city = event.args[@"homeAddressCity"];
        homeAddress.postalCode = event.args[@"homeAddressPostalCode"];
        CNLabeledValue *homeAddressValue = [[CNLabeledValue alloc] initWithLabel:CNLabelHome value:homeAddress];
        [addresses addObject:homeAddressValue];
    }
    CNSaveRequest *saveRequest = [[CNSaveRequest alloc] init];
    [saveRequest addContact:contact toContainerWithIdentifier:nil];
    // 写入联系人
    CNContactStore *store = [[CNContactStore alloc] init];
    NSError *error;
    BOOL success = [store executeSaveRequest:saveRequest error:&error];
    if (success) {
        kSuccessWithDic(nil)
    } else {
        kFailWithErr(error)
    }
    return @"";
}

JS_API(getBatteryInfoSync){
    
    NSDictionary *dic = @{
        @"level": [NSString stringWithFormat:@"%.0f",[Device batteryLevel] * 100],
        @"isCharging": [NSNumber numberWithBool:[Device isCharging]]
    };
    return [JSONHelper exchengeDictionaryToString:dic];
}

JS_API(getBatteryInfo){
    NSDictionary *dic = @{
        @"level": [NSString stringWithFormat:@"%.0f",[Device batteryLevel] * 100],
        @"isCharging": [NSNumber numberWithBool:[Device isCharging]]
    };
    kSuccessWithDic(dic)
    return @"";
}


JS_API(setClipboardData){
    
    kBeginCheck
    kEndCheck([NSString class], @"data", NO)
    
    NSString *content = event.args[@"data"];
    if (content && [content isKindOfClass:[NSString class]]) {
        [UIPasteboard generalPasteboard].string = content;
        kSuccessWithDic(@{@"data": content})
        [QMUITips showSucceed:@"内容已复制" inView:[event.webView.webHost currentViewController].view hideAfterDelay:1.5];
    } else {
        kFailWithError(setClipboardData, -1, @"data: params invalid")
        [QMUITips showError:@"内容为空" inView:[event.webView.webHost currentViewController].view hideAfterDelay:1.5];
    }
    return @"";
}


JS_API(getClipboardData){
    NSString *string = [UIPasteboard generalPasteboard].string;
    kSuccessWithDic(@{
        @"data": string ? string : @""
                    })
    return @"";
}


JS_API(getClipboardDataSync){
    return [UIPasteboard generalPasteboard].string;
}


JS_API(onNetworkStatusChange){
    if ([event.webView.webHost respondsToSelector:@selector(addReachibilityChangeCallback:)]) {
        [event.webView.webHost addReachibilityChangeCallback:event.callbacak];
        WALOG(@"onNetworkStatusChange success")
    } else {
        WALOG(@"onNetworkStatusChange fail")
    }
    return @"";
}


JS_API(offNetworkStatusChange){
    if ([event.webView.webHost respondsToSelector:@selector(removeReachibilityChangeCallback:)]) {
        [event.webView.webHost removeReachibilityChangeCallback:event.callbacak];
        WALOG(@"offNetworkStatusChange success")
    } else {
        WALOG(@"offNetworkStatusChange fail")
    }
    return @"";
}

JS_API(getNetworkType){
    kSuccessWithDic(@{@"networkType": [Device networkType]})
    return @"";
}

JS_API(getNetworkTypeSync){
    return [Device networkType];
}

JS_API(setScreenBrightness){
    
    kBeginCheck
    kEndCheck([NSNumber class], @"value", NO)
    
    if (event.args[@"value"] && [event.args[@"value"] isKindOfClass:[NSNumber class]]) {
        CGFloat value = [event.args[@"value"] floatValue];
        if (value < 0 || value > 1) {
            kFailWithError(setClipboardData, -1, @"value 不在范围内")
        } else {
            [Device setScreenBrightness:value];
            kSuccessWithDic(nil)
        }
    } else  {
        kFailWithError(setScreenBrightness, -1, @"value: params invalid")
    }
    return @"";
}

JS_API(setKeepScreenOn){
    
    kBeginCheck
    kEndChecIsBoonlean(@"keepScreenOn", NO)
    
    if (event.args[@"keepScreenOn"] && [event.args[@"keepScreenOn"] isKindOfClass:[NSNumber class]]) {
        BOOL value = [event.args[@"keepScreenOn"] boolValue];
        [Device setKeepScreenOn:value];
        kSuccessWithDic(nil)
    } else {
       kFailWithError(setKeepScreenOn, -1, @"keepScreenOn: params invalid")
    }
    return @"";
}

JS_API(onUserCaptureScreen){
    if ([event.webView.webHost respondsToSelector:@selector(addUserCaptureScreenCallback:)]) {
        [event.webView.webHost addUserCaptureScreenCallback:event.callbacak];
        WALOG(@"onUserCaptureScreen success")
    } else {
        WALOG(@"onUserCaptureScreen fail")
    }
    return @"";
}

JS_API(offUserCaptureScreen){
    if ([event.webView.webHost respondsToSelector:@selector(removeUserCaptureScreenCallback:)]) {
        [event.webView.webHost removeUserCaptureScreenCallback:event.callbacak];
        WALOG(@"offUserCaptureScreen success")
    } else {
        WALOG(@"offUserCaptureScreen fail")
    }
    return @"";
}

JS_API(getScreenBrightness){
    CGFloat value = [Device screenBrightness];
    kSuccessWithDic(@{@"value": [NSNumber numberWithFloat:value]})
    return @"";
}


JS_API(makePhoneCall){
    
    kBeginCheck
    kEndCheck([NSString class], @"phoneNumber", NO)
    
    NSString *number = event.args[@"phoneNumber"];
    if (!number || ![number isKindOfClass:[NSString class]]) {
        kFailWithError(makePhoneCall, -1, @"phoneNumber: params invalid")
        return @"";
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@",number]];
    [self handlerWithUrl:url withEvent:event];
    return @"";
}

JS_API(sendSms){
    
    kBeginCheck
    kEndChecIsBoonlean(@"phoneNumber", NO)
    
    NSString *number = event.args[@"phoneNumber"];
    if (!number || ![number isKindOfClass:[NSString class]]) {
        kFailWithError(sendSms, -1, @"phoneNumber: params invalid")
        return @"";
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"sms://%@",number]];
    [self handlerWithUrl:url withEvent:event];
    return @"";
}


JS_API(emailTo){
    
    kBeginCheck
    kEndChecIsBoonlean(@"emial", NO)
    
    NSString *email = event.args[@"emial"];
    if (!email || ![email isKindOfClass:[NSString class]]) {
        kFailWithError(emailTo, -1, @"emial: params invalid")
        return @"";
    }
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@",email]];
    [self handlerWithUrl:url withEvent:event];
    return @"";
}


JS_API(scanCode){

    kBeginCheck
    kCheckIsBoolean([NSNumber class], @"onlyFromCamera", YES, YES)
    kEndCheck([NSArray class], @"scanType", YES)
    
    BOOL onlyFromCamera = NO;
    if (kWA_DictContainKey(event.args, @"onlyFromCamera")) {
        onlyFromCamera = [event.args[@"onlyFromCamera"] boolValue];
    }

    NSArray *scanTypeArray = @[@"barcode", @"qrcode"];
    if (kWA_DictContainKey(event.args, @"scanType")) {
        scanTypeArray = event.args[@"scanType"];
        NSArray *validScanTypes = @[@"barCode", @"qrCode", @"datamatrix", @"pdf417"];
        for (NSString *type in scanTypeArray) {
            if (![validScanTypes containsObject:type]) {
                NSString *info = [NSString stringWithFormat:@"scanType contain invalid type:%@",type];
                kFailWithErrorWithReturn(@"scanCode", -1, info);
            }
        }
    }
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"未检测到您的摄像头" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:nil];
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:121 userInfo:@{NSLocalizedDescriptionKey:@"未检测到摄像头"}];
        [alertC addAction:alertA];
        [[event.webView.webHost currentViewController] presentViewController:alertC animated:YES completion:nil];
        [self event:event failWithError:error];
        return @"";
    }
    
    UIViewController *webViewVC = [event.webView.webHost currentViewController];

    
    WBQRCodeVC *VC = [[WBQRCodeVC alloc] init];
    VC.scanPrams = @{
        @"onlyFromCamera": [NSNumber numberWithBool:onlyFromCamera],
        @"scanType": scanTypeArray
    };
    @weakify(VC)
    VC.scanCodeCallBack = ^(NSDictionary *dic){
        @strongify(VC)
        kSuccessWithDic(dic)
        if (webViewVC.navigationController) {
               [webViewVC.navigationController popViewControllerAnimated:YES];
           } else {
               [VC dismissViewControllerAnimated:YES completion:nil];
           }
    };
    if (webViewVC.navigationController) {
        [webViewVC.navigationController pushViewController:VC animated:YES];
    } else {
        [webViewVC presentViewController:VC animated:YES completion:nil];
    }
    return @"";
}

JS_API(createQrCode){
    
    kBeginCheck
    kEndCheck([NSString class], @"content", NO)
    
    NSString *content = event.args[@"content"];
    if (!content || ![content isKindOfClass:[NSString class]]) {
        kFailWithErrorWithReturn(createQrCode, -1, @"content: params invalid")
    }
    if ([self isInvalidObject:event.args[@"size"] ofClass:[NSNumber class]]) {
        kFailWithErrorWithReturn(createQrCode, -1, @"size: params invalid")
    }
    CGFloat size = [event.args[@"size"] floatValue];
    UIImage *image = [QRCodeGenerator qRImageFromString:content imageSize:size];
    if (image) {
        NSData *imageData =UIImagePNGRepresentation(image);
        kSuccessWithDic((@{@"base64": [NSString stringWithFormat:@"data:image/png;base64,%@",[imageData base64String]]}))
    } else {
        kFailWithError(createQrCode, -1, @"生成二维码失败")
    }
    return @"";
}


JS_API(vibrateLong){
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    kSuccessWithDic(nil)
    return @"";
}

JS_API(vibrateShort){
    
    kBeginCheck
    kEndCheck([NSString class], @"type", YES)
    
    NSString *type = event.args[@"type"];
    NSArray *validTypes = @[@"light", @"medium", @"heavy"];
    
    if (type.length && ![validTypes containsObject:type]) {
        NSString *info = [NSString stringWithFormat:@"invalid parameter:type:%@", type];
        kFailWithErrorWithReturn(vibrateShort, -1, info)
    }
    
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    if ([type isEqualToString:@"light"]) {
        style = UIImpactFeedbackStyleLight;
    } else if ([type isEqualToString:@"heavy"]) {
        style = UIImpactFeedbackStyleHeavy;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: style];
            [generator prepare];
            [generator impactOccurred];
            kSuccessWithDic(nil)
        } else {
            kFailWithError(vibrateShort, -1, @"系统不支持")
        }
    });
    return @"";
}

JS_API(getScreenHeight){
    kSuccessWithDic(@{
        @"heigt": [NSNumber numberWithFloat:K_SCREEN_HEIGHT]
              })
    return @"";
}

JS_API(getScreenHeightSync){
    return [NSString stringWithFormat:@"%.0f",K_SCREEN_HEIGHT];
}

JS_API(getScreenWidth){
    kSuccessWithDic(@{
        @"width": [NSNumber numberWithFloat:K_SCREEN_WIDTH]
              })
    return @"";
}

JS_API(getScreenWidthSync){
    return [NSString stringWithFormat:@"%.0f",K_SCREEN_WIDTH];
}

JS_API(getSystemFreeSize){
    float size = [Device systemFreeSize];
    kSuccessWithDic(@{
        @"size": [NSNumber numberWithFloat:size]
                    })
    return @"";
}

JS_API(getSystemFreeSizeSync){
    float size = [Device systemFreeSize];
    return [NSString stringWithFormat:@"%.0f",size];
}

JS_API(getSimInfo){
    kSuccessWithDic(@{@"simList": [Device carriers]})
    return @"";
}


JS_API(getDeviceTypeSync){
    return [Device platformString];
}

JS_API(getDeviceIdSync){
    NSData *data = [KeyChainWrap getDataForKey:key];
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    NSString *uuidString = [[NSUUID UUID] UUIDString];
    [KeyChainWrap deleteDataForKey:key];
    if ([KeyChainWrap setData:[uuidString dataUsingEncoding:NSUTF8StringEncoding] forKey:key]) {
        return uuidString;
    }
    return @"";
}


JS_API(getSimOperatorName){
    kSuccessWithDic(@{
        @"carrierName": [Device carrierName]
                    })
    return @"";
}

JS_API(getSimOperatorNameSync){
    return [Device carrierName];
}

JS_API(hasSimCardSync){
    return [Device simCount] ? @"true": @"false";
}

JS_API(isNetworkConnectedSync){
    return [Device isReachable] ? @"true": @"false";
}

JS_API(isWifiConnectedSync){
    return [Device isReachableViaWIFI] ? @"true": @"false";
}

JS_API(isMobileConnectedSync){
    return [Device isReachableViaWWAN] ? @"true": @"false";
}

JS_API(addCalendarEvent){
    if ([self isInvalidObject:event.args[@"title"] ofClass:[NSString class]] ||
        [self isInvalidObject:event.args[@"description"] ofClass:[NSString class]] ||
        [self isInvalidObject:event.args[@"reminderTime"] ofClass:[NSNumber class]] ) {
        kFailWithError(addCalendarEvent, -1, @"params invalid")
        return @"";
    }
    NSString *title = event.args[@"title"];
    NSString *description = event.args[@"description"];
    NSTimeInterval remindTime = [event.args[@"reminderTime"] doubleValue] / 1000;
    
    UIViewController *VC = [event.webView.webHost currentViewController];
    if (![AuthorizationCheck eventAuthorizationCheck]) {
        NSString *message = [NSString stringWithFormat:@"%@需要访问您日程表，请打开权限",[AppInfo appName]];
        kWAShowAlertView(@"权限受限", message, VC);
        return @"";
    }
    
    EKEventStore *store = [[EKEventStore alloc] init];
    
    EKEvent *evt = [EKEvent eventWithEventStore:store];
    evt.title = title;
    evt.notes = description;
    
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:remindTime];

    
    NSDate *endDate = [NSDate dateWithTimeInterval:60 sinceDate:startDate];

    evt.startDate = startDate;
    evt.endDate = endDate;
    evt.allDay = NO;

    // 添加闹钟结合（开始前多少秒）若为正则是开始后多少秒。
    EKAlarm *elarm = [EKAlarm alarmWithRelativeOffset:-300];
    [evt addAlarm:elarm];

    [evt setCalendar:[store defaultCalendarForNewEvents]];

    NSError *error = nil;
    BOOL success = [store saveEvent:evt span:EKSpanThisEvent error:&error];
    if (success) {
        kSuccessWithDic(nil)
    } else {
        [self event:event failWithError:error];
    }
    return @"";
}

#pragma mark - **********************Accelerometer*******************

JS_API(startAccelerometer){
    kBeginCheck
    kEndCheck([NSString class], @"interval", YES)
    
    NSArray *intervals = @[@"game", @"ui", @"normal"];
    NSString *interval = event.args[@"interval"];
    if (!interval) {
        interval = @"normal";
    }
    if (![intervals containsObject:interval]) {
        NSString *info = [NSString stringWithFormat:@"parameter interval not valid: {%@}",interval];
        kFailWithErrorWithReturn(startAccelerometer, -1, info)
    }
    CGFloat timeInterval = 0.2;
    if (kStringEqualToString(interval, @"game")) {
        timeInterval = 0.02;
    } else if (kStringEqualToString(interval, @"ui")) {
        timeInterval = 0.06;
    }
    [[Weapps sharedApps].deviceManager startAccelerometerWithInterval:timeInterval completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopAccelerometer){
    [[Weapps sharedApps].deviceManager stopAccelerometerWithCompletionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onAccelerometerChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                 onAccelerometerChangeCallback:event.callbacak];
    return @"";
}

JS_API(offAccelerometerChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                offAccelerometerChangeCallback:event.callbacak];
    return @"";
}


#pragma mark -  ************************Compass*******************
JS_API(startCompass){
    [[Weapps sharedApps].deviceManager startCompassWithCompletionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopCompass){
    [[Weapps sharedApps].deviceManager stopCompassWithCompletionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onCompassChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                       onCompassChangeCallback:event.callbacak];
    return @"";
}

JS_API(offCompassChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                      offCompassChangeCallback:event.callbacak];
    return @"";
}

#pragma mark - **************************DeviceMotion*****************

JS_API(startDeviceMotionListening){
    kBeginCheck
    kEndCheck([NSString class], @"interval", YES)
    
    NSArray *intervals = @[@"game", @"ui", @"normal"];
    NSString *interval = event.args[@"interval"];
    if (!interval) {
        interval = @"normal";
    }
    if (![intervals containsObject:interval]) {
        NSString *info = [NSString stringWithFormat:@"parameter interval not valid: {%@}",interval];
        kFailWithErrorWithReturn(startDeviceMotionListening, -1, info)
    }
    CGFloat timeInterval = 0.2;
    if (kStringEqualToString(interval, @"game")) {
        timeInterval = 0.02;
    } else if (kStringEqualToString(interval, @"ui")) {
        timeInterval = 0.06;
    }
    [[Weapps sharedApps].deviceManager startDeviceMotionListeningWithInterval:timeInterval
                                                            completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopDeviceMotionListening){
    [[Weapps sharedApps].deviceManager stopDeviceMotionListeningWithCompletionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onDeviceMotionChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                  onDeviceMotionChangeCallback:event.callbacak];
    return @"";
}

JS_API(offDeviceMotionChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                 offDeviceMotionChangeCallback:event.callbacak];
    return @"";
}

#pragma mark - ************************Gyroscope*******************
JS_API(startGyroscope){
    kBeginCheck
    kEndCheck([NSString class], @"interval", YES)
    
    NSArray *intervals = @[@"game", @"ui", @"normal"];
    NSString *interval = event.args[@"interval"];
    if (!interval) {
        interval = @"normal";
    }
    if (![intervals containsObject:interval]) {
        NSString *info = [NSString stringWithFormat:@"parameter interval not valid: {%@}",interval];
        kFailWithErrorWithReturn(startGyroscope, -1, info)
    }
    CGFloat timeInterval = 0.2;
    if (kStringEqualToString(interval, @"game")) {
        timeInterval = 0.02;
    } else if (kStringEqualToString(interval, @"ui")) {
        timeInterval = 0.06;
    }
    [[Weapps sharedApps].deviceManager startGyroscopeWithInterval:timeInterval
                                                 completionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(stopGyroscope){
    [[Weapps sharedApps].deviceManager stopGyroscopeWithCompletionHandler:^(BOOL success, NSError * _Nonnull error) {
        if (success) {
            kSuccessWithDic(nil)
        } else {
            kFailWithErr(error)
        }
    }];
    return @"";
}

JS_API(onGyroscopeChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                     onGyroscopeChangeCallback:event.callbacak];
    return @"";
}

JS_API(offGyroscopeChange){
    [[Weapps sharedApps].deviceManager webView:event.webView
                    offGyroscopeChangeCallback:event.callbacak];
    return @"";
}


#pragma mark - **************************************Accessibility****************************************
JS_API(checkIsOpenAccessibility){
    BOOL isOpen = UIAccessibilityIsVoiceOverRunning();
    kSuccessWithDic(@{@"open": @(isOpen)});
    return @"";
}


#pragma mark - ********************************MemoryWarning****************************************
JS_API(onMemoryWarning){
    [[Weapps sharedApps].deviceManager webView:event.webView
                       onMemoryWarningCallback:event.callbacak];
    return @"";
}

JS_API(offMemoryWarning){
    [[Weapps sharedApps].deviceManager webView:event.webView
                      offMemoryWarningCallback:event.callbacak];
    return @"";
}

#pragma mark - ************************反正webView**************************
JS_API(reverseWebView){
    
    event.webView.transform = CGAffineTransformMakeRotation(M_PI);
    return @"";
}

//*************************************************************************
#pragma mark private
- (void)handlerWithUrl:(NSURL *)url withEvent:(JSAsyncEvent *)event
{
   if (@available(iOS 10.0, *)) {
       [[UIApplication sharedApplication] openURL:url
                                          options:@{UIApplicationOpenURLOptionUniversalLinksOnly: @(NO)}
                                completionHandler:^(BOOL success)
        {
           if (success) {
               kSuccessWithDic(nil)
           } else {
               kFailWithError(event.funcName, -1, @"openURL失败")
           }
       }];
   } else {
       BOOL success = [[UIApplication sharedApplication] openURL:url];
       if (success) {
           kSuccessWithDic(nil)
       } else {
           kFailWithError(event.funcName, -1, @"openURL失败")
       }
   }
}




@end
