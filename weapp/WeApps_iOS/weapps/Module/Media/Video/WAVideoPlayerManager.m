//
//  WAVideoManager.m
//  weapps
//
//  Created by tommywwang on 2020/10/19.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAVideoPlayerManager.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "WKWebViewHelper.h"
#import "WAContainerView.h"

@interface WAVideoPlayerManager ()

@property (nonatomic, strong) NSMutableDictionary *players;

@end

@implementation WAVideoPlayerManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _players = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)createVideoPlayer:(NSString *)playerId
                inWebView:(WKWebView *)webView
             withPosition:(NSDictionary *)position
         childrenPosition:(NSDictionary *)childrenPosition
                    state:(NSDictionary *)state
        completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webView withParams:position];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createVideoPlayer" code:-1 userInfo:@{
                NSLocalizedDescriptionKey: @"can not find videoPlayer container in webView"
            }]);
        }
        NSString *binderror = state[@"binderror"];
        if (binderror) {
            [WKWebViewHelper successWithResultData:@{
                @"errCode"  : @(-1),
                @"errMsg"   : @"can not find livePlayer container in webView"
            }
                                           webView:webView
                                          callback:binderror];
        }
        return;
    }
    WAContainerView *view = [[WAContainerView alloc] initWithFrame:container.bounds];
    view.resignRect = CGRectMake([childrenPosition[@"left"] floatValue],
                                 [childrenPosition[@"top"] floatValue],
                                 [childrenPosition[@"width"] floatValue],
                                 [childrenPosition[@"height"] floatValue]);
    @weakify(self)
    [view addViewWillDeallocBlock:^(WAContainerView * _Nonnull containerView) {
        @strongify(self)
        [self.players removeObjectForKey:playerId];
    }];
    //自动适配camera DOM节点的大小；
    container.boundsChangeBlock = ^(CGRect rect) {
        view.frame = rect;
    };
//    [container insertSubview:view atIndex:0];
    [container addSubview:view];

    WAVideoPlayer *player = [[WAVideoPlayer alloc] init];
    player.playerId = playerId;
    player.webView = webView;
    player.previewView = view;

    self.players[playerId] = player;

    [self player:player setVideoPlayerState:state isInit:YES];
}


/// 设置相关属性
/// @param playerId playerId
/// @param state 属性字典
- (void)videoPlayer:(NSString *)playerId setState:(NSDictionary *)state
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId domain:nil completionHandler:nil];
    [self player:player setVideoPlayerState:state isInit:NO];
}

/// 退出全屏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId exitFullScreenWithCompletionHandler:(void(^)(BOOL success,
                                                                                     NSDictionary *result,
                                                                                     NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"exitFullScreen"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player exitFullScreenWithCompletionHandler:completionHandler];
}

/// 退出画中画
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success,
                                                                                           NSDictionary *result,
                                                                                           NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"exitPictureInPicture"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player exitPictureInPictureWithCompletionHandler:completionHandler];
}

/// 显示状态栏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId showStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"showStatusBar"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player showStatusBarWithCompletionHandler:completionHandler];
}

/// 影藏状态栏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId hideStatusBarWithCompletionHandler:(void(^)(BOOL success,
                                            NSDictionary *result,
                                            NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"hideStatusBar"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player hideStatusBarWithCompletionHandler:completionHandler];
}

/// 暂停
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId pauseWithCompletionHandler:(void(^)(BOOL success,
                                                                             NSDictionary *result,
                                                                             NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"pause"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player pauseWithCompletionHandler:completionHandler];
}

/// 播放
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId playWithCompletionHandler:(void(^)(BOOL success,
                                                                            NSDictionary *result,
                                                                            NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"play"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player playWithCompletionHandler:completionHandler];
}

/// 设置播放速率
/// @param playerId playerId
/// @param rate 速率
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
    setPlaybackRate:(CGFloat)rate
playWithCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"playbackRate"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player playbackRate:rate withCompletionHandler:completionHandler];
}

/// 请求全屏
/// @param playerId playerId
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
requestFullScreenWithDirection:(NSNumber *)direction
  completionHandler:(void(^)(BOOL success,
                             NSDictionary *result,
                             NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"requestFullScreen"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player requestFullScreenWithDirection:direction
                         completionHandler:completionHandler];
}


/// 跳转到指定位置
/// @param playerId playerId
/// @param position 位置
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
               seek:(CGFloat)position
  completionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"seek"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player seek:position withCompletionHandler:completionHandler];
}

/// 发送弹幕
/// @param playerId playerId
/// @param danmu 弹幕
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId
          sendDanmu:(WADanmu *)danmu
  completionHandler:(void(^)(BOOL success,
                                   NSDictionary *result,
                                   NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"sendDanmu"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player sendDanmu:danmu withCompletionHandler:completionHandler];
}

/// 停止
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)videoPlayer:(NSString *)playerId stopWithCompletionHandler:(void(^)(BOOL success,
                                                                            NSDictionary *result,
                                                                            NSError *error))completionHandler
{
    WAVideoPlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                          domain:@"stop"
                                               completionHandler:completionHandler];
    if (!player) {
        return;
    }
    [player stopWithCompletionHandler:completionHandler];
}

#pragma mark - private

- (void)player:(WAVideoPlayer *)player setVideoPlayerState:(NSDictionary *)state isInit:(BOOL)isInit
{
    if (state[@"initialTime"] &&
        [state[@"initialTime"] isKindOfClass:[NSNumber class]]) {
        player.initialTime = [state[@"initialTime"] floatValue];
    }
    if (state[@"src"] &&
        [state[@"src"] isKindOfClass:[NSString class]]) {
        player.url = state[@"src"];
    }
    if (state[@"duration"] &&
        [state[@"duration"] isKindOfClass:[NSNumber class]]) {
        player.duration = [state[@"duration"] floatValue];
    }
    if (state[@"controls"] &&
        [state[@"controls"] isKindOfClass:[NSNumber class]]) {
        player.showControls = [state[@"controls"] boolValue];
    }
    if (state[@"danmuList"] &&
        [state[@"danmuList"] isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *dict in state[@"danmuList"]) {
            if ([dict isKindOfClass:[NSDictionary class]]) {
                WADanmu *danmu = [[WADanmu alloc] initWithDict:dict];
                [array addObject:danmu];
            }
        }
        player.danmuList = [array copy];
    }
    //初始化有效
    if (isInit) {
        if (state[@"danmuBtn"] &&
            [state[@"danmuBtn"] isKindOfClass:[NSNumber class]]) {
            player.showDanmuBtn = [state[@"danmuBtn"] boolValue];
        }
        if (state[@"enableDanmu"] &&
            [state[@"enableDanmu"] isKindOfClass:[NSNumber class]]) {
            player.showDanmu = [state[@"enableDanmu"] boolValue];
        }
    }
    if (state[@"autoplay"] &&
        [state[@"autoplay"] isKindOfClass:[NSNumber class]]) {
        player.autoPlay = [state[@"autoplay"] boolValue];
    }
    if (state[@"loop"] &&
        [state[@"loop"] isKindOfClass:[NSNumber class]]) {        player.loop = [state[@"loop"] boolValue];
    }
    if (state[@"muted"] &&
        [state[@"muted"] isKindOfClass:[NSNumber class]]) {
        player.mute = [state[@"muted"] boolValue];
    }
    if (state[@"pageGesture"] &&
        [state[@"pageGesture"] isKindOfClass:[NSNumber class]]) {
        player.enablePageGesture = [state[@"pageGesture"] boolValue];
    }
    if (state[@"direction"] &&
        [state[@"direction"] isKindOfClass:[NSNumber class]]) {
        player.direction = state[@"direction"];
    }
    if (state[@"showProgress"] &&
        [state[@"showProgress"] isKindOfClass:[NSNumber class]]) {
        player.showProgress = [state[@"showProgress"] boolValue];
    }
    if (state[@"showFullScreenBtn"] &&
        [state[@"showFullScreenBtn"] isKindOfClass:[NSNumber class]]) {
        player.showFullScreenBtn = [state[@"showFullScreenBtn"] boolValue];
    }
    if (state[@"showPlayBtn"] &&
        [state[@"showPlayBtn"] isKindOfClass:[NSNumber class]]) {
        player.showPlayBtn = [state[@"showPlayBtn"] boolValue];
    }
    if (state[@"showCenterPlayBtn"] &&
        [state[@"showCenterPlayBtn"] isKindOfClass:[NSNumber class]]) {
        player.showCenterPlayBtn = [state[@"showCenterPlayBtn"] boolValue];
    }
    if (state[@"enableProgressGesture"] &&
        [state[@"enableProgressGesture"] isKindOfClass:[NSNumber class]]) {
        player.enableProgressGesture = [state[@"enableProgressGesture"] boolValue];
    }
    if (state[@"objectFit"] &&
        [state[@"objectFit"] isKindOfClass:[NSString class]]) {
        NSString *objectFit = state[@"objectFit"];
        if (kStringEqualToString(objectFit, @"contain")) {
            player.objectFit = WAVideoPlayerObjectFitContain;
        } else if (kStringEqualToString(objectFit, @"fill")) {
            player.objectFit = WAVideoPlayerObjectFitFill;
        } else if (kStringEqualToString(objectFit, @"cover")) {
            player.objectFit = WAVideoPlayerObjectFitCover;
        }
    }
    if (state[@"poster"] &&
        [state[@"poster"] isKindOfClass:[NSString class]]) {
        player.poster = state[@"poster"];
    }
    if (state[@"showMuteBtn"] &&
        [state[@"showMuteBtn"] isKindOfClass:[NSNumber class]]) {
        player.showMuteBtn = [state[@"showMuteBtn"] boolValue];
    }
    if (state[@"title"] &&
        [state[@"title"] isKindOfClass:[NSString class]]) {
        player.title = state[@"title"];
    }
    if (state[@"playBtnPosition"] &&
        [state[@"playBtnPosition"] isKindOfClass:[NSString class]]) {
        NSString *position = state[@"playBtnPosition"];
        if (kStringEqualToString(position, @"bottom")) {
            player.playBtnposition = WAVideoPlayerPlayButtonPositionBottom;
        } else if (kStringEqualToString(position, @"center")) {
            player.playBtnposition = WAVideoPlayerPlayButtonPositionCenter;
        }
    }
    if (state[@"enablePlayGesture"] &&
        [state[@"enablePlayGesture"] isKindOfClass:[NSNumber class]]) {
        player.enablePlayGesture = [state[@"enablePlayGesture"] boolValue];
    }
    if (state[@"vslideGesture"] &&
        [state[@"vslideGesture"] isKindOfClass:[NSNumber class]]) {
        player.vslideGesture = [state[@"vslideGesture"] boolValue];
    }
    if (state[@"vslideGestureInFullscreen"] &&
        [state[@"vslideGestureInFullscreen"] isKindOfClass:[NSNumber class]]) {
        player.vslideGestureInFullscreen = [state[@"vslideGestureInFullscreen"] boolValue];
    }
    if (state[@"pictureInPictureShowProgress"] &&
        [state[@"pictureInPictureShowProgress"] isKindOfClass:[NSNumber class]]) {
        player.pictureInPictureShowProgress = [state[@"pictureInPictureShowProgress"] boolValue];
    }
    if (state[@"enableAutoRotation"] &&
        [state[@"enableAutoRotation"] isKindOfClass:[NSNumber class]]) {
        player.enableAutoRotation = [state[@"enableAutoRotation"] boolValue];
    }
    if (state[@"showScreenLockButton"] &&
        [state[@"showScreenLockButton"] isKindOfClass:[NSNumber class]]) {
        player.showScreenLockButton = [state[@"showScreenLockButton"] boolValue];
    }
    if (state[@"showSnapshotButton"] &&
        [state[@"showSnapshotButton"] isKindOfClass:[NSNumber class]]) {
        player.showSnapshotButton = [state[@"showSnapshotButton"] boolValue];
    }
    if (state[@"bindplay"] &&
        [state[@"bindplay"] isKindOfClass:[NSString class]]) {
        player.bindplay = state[@"bindplay"];
    }
    if (state[@"bindpause"] &&
        [state[@"bindpause"] isKindOfClass:[NSString class]]) {
        player.bindpause = state[@"bindpause"];
    }
    if (state[@"bindended"] &&
        [state[@"bindended"] isKindOfClass:[NSString class]]) {
        player.bindended = state[@"bindended"];
    }
    if (state[@"bindtimeupdate"] &&
        [state[@"bindtimeupdate"] isKindOfClass:[NSString class]]) {
        player.bindtimeupdate = state[@"bindtimeupdate"];
    }
    if (state[@"bindfullscreenchange"] &&
        [state[@"bindfullscreenchange"] isKindOfClass:[NSString class]]) {
        player.bindfullscreenchange = state[@"bindfullscreenchange"];
    }
    if (state[@"bindwaiting"] &&
        [state[@"bindwaiting"] isKindOfClass:[NSString class]]) {
        player.bindwaiting = state[@"bindwaiting"];
    }
    if (state[@"binderror"] &&
        [state[@"binderror"] isKindOfClass:[NSString class]]) {
        player.binderror = state[@"binderror"];
    }
    if (state[@"bindprogress"] &&
        [state[@"bindprogress"] isKindOfClass:[NSString class]]) {
        player.bindprogress = state[@"bindprogress"];
    }
    if (state[@"bindloadedmetadata"] &&
        [state[@"bindloadedmetadata"] isKindOfClass:[NSString class]]) {
        player.bindloadedmetadata = state[@"bindloadedmetadata"];
    }
    if (state[@"bindcontrolstoggle"] &&
        [state[@"bindcontrolstoggle"] isKindOfClass:[NSString class]]) {
        player.bindcontrolstoggle = state[@"bindcontrolstoggle"];
    }
    if (state[@"bindenterpictureinpicture"] &&
        [state[@"bindenterpictureinpicture"] isKindOfClass:[NSString class]]) {
        player.bindenterpictureinpicture = state[@"bindenterpictureinpicture"];
    }
    if (state[@"bindleavepictureinpicture"] &&
        [state[@"bindleavepictureinpicture"] isKindOfClass:[NSString class]]) {
        player.bindleavepictureinpicture = state[@"bindleavepictureinpicture"];
    }
    if (state[@"bindseekcomplete"] &&
        [state[@"bindseekcomplete"] isKindOfClass:[NSString class]]) {
        player.bindseekcomplete = state[@"bindseekcomplete"];
    }
}

- (WAVideoPlayer *)checkIfPlayerExistWithPlayerId:(NSString *)playerId
                                           domain:(NSString *)domain
                                completionHandler:(void(^)(BOOL success,
                                                           NSDictionary *result,
                                                           NSError *error))completionHandler
{
    WAVideoPlayer *player = self.players[playerId];
    if (player) {
        return player;
    }
    if (completionHandler) {
        completionHandler(NO, nil, [NSError errorWithDomain:domain code:-1 userInfo:@{
            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find live player with id:{%@}",playerId]
        }]);
    }
    return nil;
}


@end
