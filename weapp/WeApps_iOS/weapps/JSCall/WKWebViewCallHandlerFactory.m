//
//  WKWebViewMessageHandlerFactory.m
//  weapps
//
//  Created by tommywwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WKWebViewCallHandlerFactory.h"
#import "WASystemHandler.h"
#import "WAUIHandler.h"
#import "WAScrollHandler.h"
#import "WAKeyboardHandler.h"
#import "WANetworkHandler.h"
#import "WAStorageHandler.h"
#import "WAImageHandler.h"
#import "WAVideoHandler.h"
#import "WAFileHandler.h"
#import "WALogHandler.h"
#import "WADeviceHandler.h"
#import "WAAppHandler.h"
#import "WARouteHandler.h"
#import "WALoginHandler.h"
#import "WAShareHandler.h"
#import "WALocationHandler.h"
#import "WARecordHandler.h"
#import "WAVoiceHandler.h"
#import "WACameraHandler.h"
#import "WAMediaContainerHandler.h"
#import "WAVideoDecoderHandler.h"
#import "WABluetoothHandler.h"
#import "WAVoIPHandler.h"
#import "WALivePushHandler.h"
#import "WALivePlayerHandler.h"
#import "WAIBeaconHandler.h"
#import "WAWIFIHandler.h"
#import "WAMapHandler.h"

@implementation WKWebViewCallHandlerFactory

+ (JSAsyncCallBaseHandler *)handlerByEvent:(JSAsyncEvent *)event
{
    for (JSAsyncCallBaseHandler *handler in [self handlers]) {
        if ([handler respondsToSelector:@selector(callingMethods)]) {
            NSArray<NSString *> *methods = [handler callingMethods];
            if ([methods containsObject:event.funcName]) {
                return handler;
            }
        }
    }
    return nil;
}


+ (NSArray<JSAsyncCallBaseHandler *> *)handlers
{
    static NSArray *handlers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handlers = @[
            [[WASystemHandler alloc] init],
            [[WAUIHandler alloc] init],
            [[WAScrollHandler alloc] init],
            [[WAKeyboardHandler alloc] init],
            [[WANetworkHandler alloc] init],
            [[WAStorageHandler alloc] init],
            [[WAImageHandler alloc] init],
            [[WAVideoHandler alloc] init],
            [[WAFileHandler alloc] init],
            [[WALogHandler alloc] init],
            [[WADeviceHandler alloc] init],
            [[WAAppHandler alloc] init],
            [[WARouteHandler alloc] init],
            [[WALoginHandler alloc] init],
            [[WAShareHandler alloc] init],
            [[WALocationHandler alloc] init],
            [[WARecordHandler alloc] init],
            [[WAVoiceHandler alloc] init],
            [[WACameraHandler alloc] init],
            [[WAMediaContainerHandler alloc] init],
            [[WAVideoDecoderHandler alloc] init],
            [[WABluetoothHandler alloc] init],
            [[WAVoIPHandler alloc] init],
            [[WALivePushHandler alloc] init],
            [[WALivePlayerHandler alloc] init],
            [[WAIBeaconHandler alloc] init],
            [[WAWIFIHandler alloc] init],
            [[WAMapHandler alloc] init]
        ];
    });
    return handlers;
}


@end
