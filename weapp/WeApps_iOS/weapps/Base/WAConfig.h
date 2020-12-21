//
//  WAConfig.h
//  weapps
//
//  Created by tommywwang on 2020/7/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WANavigationBarTextStyle) {
    WANavigationBarTextStyleWhite = 0,
    WANavigationBarTextStyleBlack
};

typedef NS_ENUM(NSUInteger, WANavigationStyle) {
    WANavigationStyleDefault,
    WANavigationStyleCustom  //custom h5自定义导航栏, 隐藏native导航栏
};

typedef NS_ENUM(NSUInteger, WABackgroundTextStyle) {
    WABackgroundTextStyleLight = 0,
    WABackgroundTextStyleDark
};

typedef NS_ENUM(NSUInteger, WATabBarPosition) {
    WATabBarPositionBottom = 0,
    WATabBarPositionTop
};


typedef NS_ENUM(NSUInteger, WATabBarBorderStyle) {
    WATabBarBorderStyleBlack = 0,
    WATabBarBorderStyleWhite
};


@interface WAWindowConfig : NSObject

@property (nonatomic, copy) NSString *navigationBarBackgroundColor; //导航栏背景颜色，如 #000000
@property (nonatomic, assign) WANavigationBarTextStyle navigationBarTextStyle; //导航栏标题颜色，仅支持 black / white
@property (nonatomic, copy) NSString *navigationBarTitleText; //导航栏标题文字内容
@property (nonatomic, copy) NSString *backgroundColor; //窗口的背景色
@property (nonatomic, copy) NSString *backgroundColorBottom;
@property (nonatomic, copy) NSString *backgroundColorTop;
@property (nonatomic, assign) WABackgroundTextStyle backgroundTextStyle; //下拉 loading 的样式，仅支持 dark / light
@property (nonatomic, assign) WANavigationStyle navigationStyle; //导航栏样式

- (id)initWithDic:(NSDictionary *)dict;

@end

@interface WAPageConfig : WAWindowConfig

@property (nonatomic, copy) NSString *pageHash; //h5页面url的hash

- (id)initWithDic:(NSDictionary *)dict;

@end

@interface WATabBarItemConfig : NSObject

@property (nonatomic, copy) NSString *pageHash; //h5页面url的hash
@property (nonatomic, copy) NSString *text;  //标题
@property (nonatomic, copy) NSString *iconPath;
@property (nonatomic, copy) NSString *selectedIconPath;
@property (nonatomic, assign) BOOL hasIcon;

- (id)initWithDic:(NSDictionary *)dict;


@end

@interface WATabBarConfig : NSObject

@property (nonatomic, assign) BOOL hiden;
@property (nonatomic, copy) NSString *color;  //tab 上的文字默认颜色，仅支持十六进制颜色
@property (nonatomic, copy) NSString *selectedColor; //  tab 上的文字选中时的颜色，仅支持十六进制颜色
@property (nonatomic, copy) NSString *backgroundColor;  // tab 的背景色，仅支持十六进制颜色
@property (nonatomic, assign) WATabBarPosition position; //位置
@property (nonatomic, assign) WATabBarBorderStyle borderStyle; //border颜色
@property (nonatomic, strong) NSArray <WATabBarItemConfig *>*tabBarItems;

- (id)initWithDic:(NSDictionary *)dict;

@end

@interface WANetworkConfig : NSObject

@property (nonatomic, assign) NSTimeInterval requsetTimeout; //请求超时时间，毫秒
@property (nonatomic, assign) NSTimeInterval downloadFileTimeout;  //下载文件超时时间，毫秒
@property (nonatomic, assign) NSTimeInterval uploadFileTimeout;  //上传文件超时时间，毫秒
- (id)initWithDic:(NSDictionary *)dict;

@end



@interface WAConfig : NSObject

@property (nonatomic, assign, readonly) BOOL isDebug;
@property (nonatomic, copy, readonly) NSString *homeHash;
@property (nonatomic, strong, readonly) WAWindowConfig *windowConfig;
@property (nonatomic, strong, readonly) NSDictionary<NSString *,WAPageConfig *> *pages;
@property (nonatomic, strong, readonly) WATabBarConfig *tabBarConfig;
@property (nonatomic, strong, readonly) WANetworkConfig *networkConfig;

- (id)initWithDic:(NSDictionary *)dict;

- (NSString *)getNavigationTitleByHash:(NSString *)hash;

- (NSString *)getNavigationBackgroundColorStringByHash:(NSString *)hash;

- (WANavigationBarTextStyle)getTitleColorStringByHash:(NSString *)hash;

- (NSString *)getBackgroundColorTopStringByHash:(NSString *)hash;

- (NSString *)getBackgroundColorBottomStringByHash:(NSString *)hash;

- (NSString *)getBackgroundColorStringByHash:(NSString *)hash;

- (WANavigationStyle)getNavigationStyleByHash:(NSString *)hash;

- (WABackgroundTextStyle)getBackgroundTextStyleByHash:(NSString *)hash;

- (BOOL)tabBarConfigContainItemOfHash:(NSString *)hash;

@end

NS_ASSUME_NONNULL_END
