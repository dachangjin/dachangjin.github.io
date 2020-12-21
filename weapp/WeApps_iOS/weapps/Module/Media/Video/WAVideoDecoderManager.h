//
//  WAVideoDecoderManager.h
//  weapps
//
//  Created by tommywwang on 2020/8/21.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WAVideoDecoder.h"
#import "WebView.h"


NS_ASSUME_NONNULL_BEGIN

@interface WAVideoDecoderManager : NSObject

- (NSNumber *)createMediaContainerWithWebView:(WebView *)webView;

- (void)startWithDecoder:(NSNumber *)decoderId
                 webView:(WebView *)webView
                  source:(NSString *)source
                  inMode:(WAVideoDecoderMode)mode
       completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)stopWithDecoder:(NSNumber *)decoderId
      completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)seekTo:(NSNumber *)position withDecoder:(NSNumber *)decoderId
    completionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (void)removeDecoder:(NSNumber *)decoderId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler;

- (NSDictionary *)getFrameDataWithDecoder:(NSNumber *)decoderId;

- (void)onStartCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)onStopCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)onSeekCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)onBufferChangeCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)onEndCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)offStartCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)offStopCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)offSeekCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)offBufferChangeCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;

- (void)offEndCallback:(NSString *)callback withDecoderId:(NSNumber *)decoderId;
@end

NS_ASSUME_NONNULL_END
