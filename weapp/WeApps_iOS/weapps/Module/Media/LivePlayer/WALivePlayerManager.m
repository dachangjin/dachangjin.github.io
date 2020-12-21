//
//  WALivePlayerManager.m
//  weapps
//
//  Created by tommywwang on 2020/9/17.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WALivePlayerManager.h"
#import "WALivePlayer.h"
#import "UIScrollView+WKChildScrollVIew.h"
#import "WKWebViewHelper.h"
#import "WAContainerView.h"

@interface WALivePlayerManager ()

@property (nonatomic, strong) NSMutableDictionary *players;

@end

@implementation WALivePlayerManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _players = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)createLivePlayer:(NSString *)playerId
               inWebView:(WKWebView *)webView
            withPosition:(NSDictionary *)position
                   state:(NSDictionary *)state
       completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    UIScrollView *container = [WKWebViewHelper findContainerInWebView:webView withParams:position];
    if (!container) {
        if (completionHandler) {
            completionHandler(NO, nil, [NSError errorWithDomain:@"createLivePlayerContext"
                                                           code:-1
                                                       userInfo:@{
                NSLocalizedDescriptionKey: @"can not find livePlayer container in webView"
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
    @weakify(self)
    [view addViewWillDeallocBlock:^(WAContainerView * _Nonnull containerView) {
        @strongify(self)
        [self.players removeObjectForKey:playerId];
    }];
    //自动适配camera DOM节点的大小
    container.boundsChangeBlock = ^(CGRect rect) {
        view.frame = rect;
    };
    [container insertSubview:view atIndex:0];
    WALivePlayer *player = [[WALivePlayer alloc] init];
    player.playerId = playerId;
    player.webView = webView;
    player.previewView = view;
    
    self.players[playerId] = player;
    
    [self player:player setLivePlayerState:state];
}

- (void)livePlayer:(NSString *)playerId setState:(NSDictionary *)state
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId domain:nil completionHandler:nil];
    [self player:player setLivePlayerState:state];
}

/// 退出全屏
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId exitFullScreenWithCompletionHandler:(void(^)(BOOL success,
                                                                                     NSDictionary *result,
                                                                                     NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
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
- (void)livePlayer:(NSString *)playerId exitPictureInPictureWithCompletionHandler:(void(^)(BOOL success,
                                                                                           NSDictionary *result,
                                                                                           NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"exitPictureInPicture"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player exitPictureInPictureWithCompletionHandler:completionHandler];
}

/// 静音
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId muteWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"mute"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player muteWithCompletionHandler:completionHandler];
}

/// 暂停
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId pauseWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"pause"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player pauseWithCompletionHandler:completionHandler];
}

/// 播放
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId playWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"play"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player playWithCompletionHandler:completionHandler];
}

/// 请求全屏
/// @param playerId playerId
/// @param direction 全屏时的方向0：正常竖直 | 90：逆时针90度 | -90： 顺时针90度
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId requestFullScreenWithDirection:(NSNumber *)direction
                     completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"requestFullScreen"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player requestFullScreenWithDirection:direction completionHandler:completionHandler];
}

/// 恢复
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId resumeWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"resume"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player resumeWithCompletionHandler:completionHandler];
}


/// 截图
/// @param playerId playerId
/// @param quality 图片质量 raw :原图，compressed:压缩图
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId snapShotWithQuality:(NSString *)quality
          completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"snapShot"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player snapShotWithQuality:quality completionHandler:completionHandler];
}

/// 停止
/// @param playerId playerId
/// @param completionHandler 完成回调
- (void)livePlayer:(NSString *)playerId stopWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = [self checkIfPlayerExistWithPlayerId:playerId
                                                            domain:@"stop"
                                                 completionHandler:completionHandler];
    if (!player) {
       return;
    }
    [player stopWithCompletionHandler:completionHandler];
}

#pragma mark - private


- (void)player:(WALivePlayer *)player setLivePlayerState:(NSDictionary *)state
{
    if (state[@"src"] &&
        [state[@"src"] isKindOfClass:[NSString class]]) {
        player.url = state[@"src"];
    }
    if (state[@"autoplay"] &&
        [state[@"autoplay"] isKindOfClass:[NSNumber class]]) {
        player.isAutoPlay = [state[@"autoplay"] boolValue];
    }
    if (state[@"muted"] &&
        [state[@"muted"] isKindOfClass:[NSNumber class]]) {
        player.isMuted = [state[@"muted"] boolValue];
    }
    if (state[@"orientation"] &&
        [state[@"orientation"] isKindOfClass:[NSString class]]) {
        NSString *orientation = state[@"orientation"];
        if (kStringEqualToString(orientation, @"vertical")) {
            player.orientation = WALivePlayerOrientationVertical;
        } else if (kStringEqualToString(orientation, @"horizontal")) {
            player.orientation = WALivePlayerOrientationHorizontal;
        }
    }
    if (state[@"objectFit"] &&
        [state[@"objectFit"] isKindOfClass:[NSString class]]) {
        NSString *fillMode = state[@"objectFit"];
        if (kStringEqualToString(fillMode, @"contain")) {
            player.fillMode = WALivePlayerFillModeContain;
        } else if (kStringEqualToString(fillMode, @"fillCrop")) {
            player.fillMode = WALivePlayerFillModeFillCrop;
        }
    }
    if (state[@"minCache"] &&
        [state[@"minCache"] isKindOfClass:[NSNumber class]]) {
        player.minCache = [state[@"minCache"] floatValue];
    }
    if (state[@"maxCache"] &&
        [state[@"maxCache"] isKindOfClass:[NSNumber class]]) {
        player.maxCache = [state[@"maxCache"] floatValue];
    }
    if (state[@"soundMode"] &&
        [state[@"soundMode"] isKindOfClass:[NSString class]]) {
        NSString *soundMode = state[@"soundMode"];
        if (kStringEqualToString(soundMode, @"speaker")) {
            player.soundMode = WALivePlayerSoundModeSpeaker;
        } else if (kStringEqualToString(soundMode, @"ear")) {
            player.soundMode = WALivePlayerSoundModeEar;
        }
    }
    if (state[@"bindstatechange"] &&
        [state[@"bindstatechange"] isKindOfClass:[NSString class]]) {
        player.bindstatechange = state[@"bindstatechange"];
    }
    if (state[@"bindfullscreenchange"] &&
        [state[@"bindfullscreenchange"] isKindOfClass:[NSString class]]) {
        player.bindfullscreenchange = state[@"bindfullscreenchange"];
    }
    if (state[@"bindnetstatus"] &&
        [state[@"bindnetstatus"] isKindOfClass:[NSString class]]) {
        player.bindnetstatus = state[@"bindnetstatus"];
    }
    if (state[@"bindaudiovolumenotify"] &&
        [state[@"bindaudiovolumenotify"] isKindOfClass:[NSString class]]) {
        player.bindaudiovolumenotify = state[@"bindaudiovolumenotify"];
    }
    if (state[@"bindenterpictureinpicture"] &&
        [state[@"bindenterpictureinpicture"] isKindOfClass:[NSString class]]) {
        player.bindenterpictureinpicture = state[@"bindenterpictureinpicture"];
    }
    if (state[@"bindleavepictureinpicture"] &&
        [state[@"bindleavepictureinpicture"] isKindOfClass:[NSString class]]) {
        player.bindleavepictureinpicture = state[@"bindleavepictureinpicture"];
    }
}

- (WALivePlayer *)checkIfPlayerExistWithPlayerId:(NSString *)playerId
                                          domain:(NSString *)domain
                               completionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    WALivePlayer *player = self.players[playerId];
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
