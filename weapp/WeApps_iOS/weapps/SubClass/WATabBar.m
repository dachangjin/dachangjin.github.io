//
//  WATabBar.m
//  weapps
//
//  Created by tommywwang on 2020/7/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WATabBar.h"
#import "Device.h"
#import "QMUIKit.h"
#import "PathUtils.h"
#import <SDWebImage/SDWebImage.h>

#define kItemOffset 10
#define kItemImageWH 26
#define kItemImageMarginTop 4
#define kItemTitleMarginTop 31
#define kItemTitleHeight 14

@interface WATabBarItem : UIButton

@property (nonatomic, strong) QMUILabel *badgeLabel;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) WATabBarItemConfig *config;

- (void)setConfig:(WATabBarItemConfig *)config
        withColor:(UIColor *)color
    selectedColor:(UIColor *)selectedColor;

- (void)updateWithColor:(UIColor *)color
      andSelectedColor :(UIColor *)selectedColor;

- (void)updateWithText:(NSString *)text
              iconPath:(NSString *)iconPath
   andSelectedIconPath:(NSString *)selectedIconPath;

- (void)showRedDot;

- (void)hideRedDot;

- (void)setBadge:(NSString *)badge;

- (void)removeBadge;
@end



@implementation WATabBarItem

- (void)showRedDot
{
    if (!_indicatorView) {
        _indicatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _indicatorView.backgroundColor = [UIColor redColor];
        _indicatorView.layer.cornerRadius = CGRectGetHeight(_indicatorView.frame) / 2;
        [self addSubview:_indicatorView];
    }
    _indicatorView.hidden = NO;
    [self layoutSubviews];
}

- (void)hideRedDot
{
    _indicatorView.hidden = YES;
}

- (void)setBadge:(NSString *)badge
{
    if (badge.length) {
        if (!_badgeLabel) {
            _badgeLabel = [[QMUILabel alloc] init];
            _badgeLabel.font = [UIFont boldSystemFontOfSize:11];
            _badgeLabel.contentEdgeInsets = UIEdgeInsetsMake(2, 4, 2, 4);
            _badgeLabel.clipsToBounds = YES;
            _badgeLabel.textAlignment = NSTextAlignmentCenter;
            _badgeLabel.backgroundColor = [UIColor redColor];
            _badgeLabel.textColor = [UIColor whiteColor];
            [self addSubview:_badgeLabel];
        }
        _badgeLabel.text = badge;
        _badgeLabel.hidden = NO;
        [self layoutSubviews];
    }
}

- (void)removeBadge
{
    _badgeLabel.text = @"";
    _badgeLabel.hidden = YES;
}

- (void)updateWithColor:(UIColor *)color andSelectedColor :(UIColor *)selectedColor
{
    if (color) {
        [self setTitleColor:color forState:UIControlStateNormal];
    }
    if (selectedColor) {
        [self setTitleColor:selectedColor forState:UIControlStateSelected];
        //设置边框
        self.qmui_borderColor = selectedColor;
    }
}

- (void)updateWithText:(NSString *)text iconPath:(NSString *)iconPath andSelectedIconPath:(NSString *)selectedIconPath
{
    [self setTitle:text forState:UIControlStateNormal];
    if (_config.hasIcon) {
        //设置icon
        self.titleLabel.font = [UIFont systemFontOfSize:10];
        if ([[iconPath lowercaseString] containsString:@"http"]) {
             [self sd_setImageWithURL:[NSURL URLWithString:iconPath]
                             forState:UIControlStateNormal
                     placeholderImage:nil
                              options:SDWebImageHandleCookies];
        } else {
            UIImage *image = [UIImage imageWithContentsOfFile:[PathUtils h5BundlePathForRelativePath:[NSString stringWithFormat:@"preview/%@",iconPath]]];
                   [self setImage:image forState:UIControlStateNormal];
        }
        if ([[selectedIconPath lowercaseString] containsString:@"http"]) {
            [self sd_setImageWithURL:[NSURL URLWithString:selectedIconPath]
                            forState:UIControlStateSelected
                    placeholderImage:nil
                             options:SDWebImageHandleCookies];
        } else {
            UIImage *selectedImage = [UIImage imageWithContentsOfFile:[PathUtils h5BundlePathForRelativePath:[NSString
                                                                                                              stringWithFormat:@"preview/%@",selectedIconPath]]];
            [self setImage:selectedImage forState:UIControlStateSelected];
        }
    }
}

- (void)setConfig:(WATabBarItemConfig *)config withColor:(UIColor *)color selectedColor:(UIColor *)selectedColor
{
    _config = config;
    
    [self setTitleColor:color forState:UIControlStateNormal];
    [self setTitleColor:selectedColor forState:UIControlStateSelected];
    [self setTitle:_config.text forState:UIControlStateNormal];
    
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:14];
    //设置边框
    self.qmui_borderColor = selectedColor;
    self.qmui_borderPosition = QMUIViewBorderPositionBottom;
    self.qmui_borderLocation = QMUIViewBorderLocationInside;
    
    if (_config.hasIcon) {
        //设置icon
        self.qmui_borderWidth = 0;
        self.titleLabel.font = [UIFont systemFontOfSize:10];
        self.titleLabel.font = [UIFont systemFontOfSize:10];
        if ([[_config.iconPath lowercaseString] containsString:@"http"]) {
             [self sd_setImageWithURL:[NSURL URLWithString:_config.iconPath]
                             forState:UIControlStateNormal
                     placeholderImage:nil
                              options:SDWebImageHandleCookies];
        } else {
            UIImage *image = [UIImage imageWithContentsOfFile:[PathUtils h5BundlePathForRelativePath:[NSString stringWithFormat:@"preview/%@",_config.iconPath]]];
                   [self setImage:image forState:UIControlStateNormal];
        }
        if ([[_config.selectedIconPath lowercaseString] containsString:@"http"]) {
            [self sd_setImageWithURL:[NSURL URLWithString:_config.selectedIconPath]
                            forState:UIControlStateSelected
                    placeholderImage:nil
                             options:SDWebImageHandleCookies];
        } else {
            UIImage *selectedImage = [UIImage imageWithContentsOfFile:[PathUtils h5BundlePathForRelativePath:
                                                                       [NSString stringWithFormat:@"preview/%@",_config.selectedIconPath]]];
            [self setImage:selectedImage forState:UIControlStateSelected];
        }
    }
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    if (_config.hasIcon) {
        self.qmui_borderWidth = 0;
        return;
    }
    if (selected) {
        self.qmui_borderWidth = 2;
    } else {
        self.qmui_borderWidth = 0;
    }
}

//让highlighted效果失效
- (void)setHighlighted:(BOOL)highlighted{}


- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
    if (!_config.hasIcon) {
        return contentRect;
    }
    return CGRectMake(0, kItemTitleMarginTop, contentRect.size.width, kItemTitleHeight);
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
    if (!_config.hasIcon) {
        return contentRect;
    }
    //icon大小固定为26*26
    return CGRectMake((contentRect.size.width - kItemImageWH) / 2, kItemImageMarginTop, kItemImageWH, kItemImageWH);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!self.imageView) {
        return;
    }
    CGPoint center = self.imageView.center;
    if (_indicatorView && !_indicatorView.hidden) {
        _indicatorView.center = CGPointMake(center.x + kItemOffset, kItemOffset);
        [self bringSubviewToFront:_indicatorView];
    }
    if (_badgeLabel && !_badgeLabel.hidden) {
        [_badgeLabel sizeToFit];
        _badgeLabel.layer.cornerRadius = MIN(_badgeLabel.frame.size.height / 2, _badgeLabel.frame.size.width / 2);
        _badgeLabel.center = CGPointMake(center.x + kItemOffset,  kItemOffset);
        [self bringSubviewToFront:_badgeLabel];
    }
}

@end

@interface WATabBar ()

@property (nonatomic, copy) void(^selectBlock)(NSString *urlHash, NSUInteger index);
@property (nonatomic, strong) NSArray<WATabBarItem *> *tabarItems;
@property (nonatomic, assign) NSUInteger currentIndex;
@end

@implementation WATabBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
    }
    return self;
}

- (void)updateBounds
{
    self.bounds = CGRectMake(0, 0, K_SCREEN_WIDTH, [self hintHeight]);
}

- (CGFloat)hintHeight
{
    if (_config.hiden) {
        return 0;
    }
    return _config.tabBarItems.count > 0 ? (_config.position == WATabBarPositionBottom ? [Device stantardTabbarHeight] : 40) : 0;
}


- (void)setTabBarConfig:(WATabBarConfig *)config
{
    _config = config;
    _currentIndex = 0;
    //设置边框
    self.qmui_borderWidth = 0.3;
    if (_config.position == WATabBarPositionBottom) {
        self.qmui_borderPosition = QMUIViewBorderPositionTop;
    } else {
        self.qmui_borderPosition = QMUIViewBorderPositionBottom;
    }
    if (_config.borderStyle == WATabBarBorderStyleBlack) {
        self.qmui_borderColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    } else {
        self.qmui_borderColor = [UIColor colorWithWhite:0.8 alpha:1];
    }
    //设置背景色
    self.backgroundColor = [UIColor qmui_rgbaColorWithHexString:_config.backgroundColor];
    //清除tabBarItem
    for (WATabBarItem *item in _tabarItems) {
        [item removeFromSuperview];
    }
    //重新添加item
    UIColor *color = [UIColor qmui_rgbaColorWithHexString:_config.color];
    UIColor *selectedColor = [UIColor qmui_rgbaColorWithHexString:_config.selectedColor];
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:_config.tabBarItems.count];
    
    CGFloat gap = 2; //间隙，两个item之间需要double
    
    CGFloat y = 1;    //item y
    CGFloat width = (self.frame.size.width - _config.tabBarItems.count * 2 * gap) / _config.tabBarItems.count; // item宽度
    CGFloat height = [self hintHeight] - 1; //item 高度
    
    for (NSUInteger i = 0; i < _config.tabBarItems.count; i++) {
        WATabBarItemConfig *itemConfig = _config.tabBarItems[i];
        WATabBarItem *item = [WATabBarItem buttonWithType:UIButtonTypeCustom];
        [item setConfig:itemConfig withColor:color selectedColor:selectedColor];
        CGFloat x = gap + width * i + gap * 2 * i;
        item.frame = CGRectMake(x, y, width, height);
        @weakify(self)
        [item setQmui_tapBlock:^(__kindof UIControl *sender) {
            @strongify(self);
            [self setSelectAtIndex:i ignoreCallback:NO];
        }];
        
        [self addSubview:item];
        [array addObject:item];
    }
    _tabarItems = [array copy];
    ((WATabBarItem *)[_tabarItems firstObject]).selected = YES;
    [self updateBounds];
}


- (void)showRedDotAtIndex:(NSUInteger)index
{
    if (index >= _tabarItems.count) {
        return;
    }
    WATabBarItem *item = _tabarItems[index];
    [item showRedDot];
}

- (void)hideRedDotAtIndex:(NSUInteger)index
{
    if (index >= _tabarItems.count) {
        return;
    }
    WATabBarItem *item = _tabarItems[index];
    [item hideRedDot];
}

- (void)setBadge:(NSString *)badge atIndex:(NSUInteger)index
{
    if (index >= _tabarItems.count) {
        return;
    }
    WATabBarItem *item = _tabarItems[index];
    [item setBadge:badge.length <= 4 ? badge : @"..."];
}

- (void)removeBadgeAtIndex:(NSUInteger)index
{
    if (index >= _tabarItems.count) {
        return;
    }
    WATabBarItem *item = _tabarItems[index];
    [item removeBadge];
}

- (void)updateTabBarBackgroundColor:(UIColor *)backgroundColor
                          itemColor:(UIColor *)itemColor
                  selectedItemColor:(UIColor *)selectedItemColor
                        borderStyle:(WATabBarBorderStyle)style
{
    if (backgroundColor) {
        self.backgroundColor = backgroundColor;
    }
    if (style == WATabBarBorderStyleBlack) {
        self.qmui_borderColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    } else {
        self.qmui_borderColor = [UIColor colorWithWhite:0.8 alpha:0.8];
    }
    for (WATabBarItem *item in _tabarItems) {
        [item updateWithColor:itemColor andSelectedColor:selectedItemColor];
    }
}

- (void)updateTabBarItemText:(NSString *)text
                    iconPath:(NSString *)iconPath
            selectedIconPath:(NSString *)selectedIconPath
                     atIndex:(NSUInteger)index
{
    if (index >= _tabarItems.count) {
        return;
    }
    WATabBarItem *item = _tabarItems[index];
    [item updateWithText:text
                iconPath:iconPath
     andSelectedIconPath:selectedIconPath];
    
}

- (void)setSelectBlock:(void(^)(NSString *urlHash, NSUInteger index))block
{
    _selectBlock = block;
}

- (void)setSelectAtIndex:(NSUInteger)index ignoreCallback:(BOOL)ignore
{
    if (index == _currentIndex || index < 0 || index > _tabarItems.count - 1) {
        return;
    }
    for (WATabBarItem *item in _tabarItems) {
        item.selected = NO;
    }
    WATabBarItem *item = _tabarItems[index];
    item.selected = YES;
    _currentIndex = index;
    if (!ignore && _selectBlock) {
        _selectBlock(item.config.pageHash, index);
    }
}

- (void)setSelectOfUrlHash:(NSString *)hash ignoreCallback:(BOOL)ignore
{
    
    if (_tabarItems.count == 0) {
        return;
    }
    WATabBarItem *item = _tabarItems[_currentIndex];
    if (kStringEqualToString(item.config.pageHash, hash)) {
        return;
    }
    NSUInteger index = 0;
    BOOL contain = NO;
    NSUInteger preCurrentIndex = _currentIndex;
    for (NSUInteger i = 0; i < _tabarItems.count; i ++) {
        WATabBarItem *item = _tabarItems[i];
        if (kStringEqualToString(item.config.pageHash, hash)) {
            item.selected = YES;
            index = i;
            _currentIndex = i;
            contain = YES;
            break;
        }
    }
    if (contain) {
        ((WATabBarItem *)_tabarItems[preCurrentIndex]).selected = NO;
    }
    if (contain && !ignore && _selectBlock) {
        _selectBlock(hash, index);
    }
}


@end
