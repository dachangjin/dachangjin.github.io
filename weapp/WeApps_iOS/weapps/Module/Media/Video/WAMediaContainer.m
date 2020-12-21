//
//  WAMediaContainer.m
//  weapps
//
//  Created by tommywwang on 2020/8/13.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMediaContainer.h"
#import "PathUtils.h"
#import "FileUtils.h"
#import "WAMediaUtils.h"
#import "IdGenerator.h"


@interface WAMediaContainer ()

@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, AVAssetTrack *> *trackDict;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, AVMutableCompositionTrack *> *addedCompositionTrackDict;
@property (nonatomic, strong) NSMutableArray <AVMutableAudioMixInputParameters *> *audioMixInputParameters;
@property (nonatomic, assign) NSInteger currentTrackId;

@end

@implementation WAMediaContainer

- (instancetype)init
{
    self = [super init];
    if (self) {
        _composition = [[AVMutableComposition alloc] init];
        _trackDict = [NSMutableDictionary dictionary];
        _addedCompositionTrackDict = [NSMutableDictionary dictionary];
        _audioMixInputParameters = [NSMutableArray array];
        _containerId = @([IdGenerator generateIdWithClass:[self class]]);
        _currentTrackId = 1;
    }
    return self;
}



- (void)extractDataSource:(NSString *)source
    withCompletionHandler:(void(^)(BOOL success,
                                   NSDictionary<NSNumber *, AVAssetTrack *> *results ,
                                   NSError *error))completionHandler
{
    AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:source]];
    NSArray *tracks = [asset tracks];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (AVAssetTrack *track in tracks) {
        dict[@(_currentTrackId++)] = track;
    }
    //将track保存
    [_trackDict addEntriesFromDictionary:dict];
    if (completionHandler) {
        completionHandler(YES, [dict copy], nil);
    }
}

- (void)addTrackById:(NSNumber *)trackId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    AVAssetTrack *track = _trackDict[trackId];
    if (!track) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSURLErrorDomain
                                                      code:-1 userInfo:@{
                                                          NSLocalizedDescriptionKey:
                                                              [NSString stringWithFormat:@"Parameter 1 should be a MediaTrack: {%@}", trackId]
                                                      }]);
        }
        return;
    }
    if (track.mediaType == AVMediaTypeVideo) {
        //只能添加一个视频轨道
        for (AVMutableCompositionTrack *addedTrack in _addedCompositionTrackDict.allValues) {
            if (addedTrack.mediaType == AVMediaTypeVideo) {
                if (completionHandler) {
                    completionHandler(NO, [NSError errorWithDomain:@"addTrack" code:-1 userInfo:@{
                        NSLocalizedDescriptionKey: @"Only can be added one video track"
                    }]);
                }
                return;
            }
        }
    }
    AVMutableCompositionTrack *compositionTrack = [_composition addMutableTrackWithMediaType:track.mediaType
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error;
    BOOL success = [compositionTrack insertTimeRange:compositionTrack.timeRange
                                             ofTrack:compositionTrack
                                              atTime:kCMTimeZero
                                               error:&error];
    if (success) {
        //将compositionTrack保存
        _addedCompositionTrackDict[trackId] = compositionTrack;
    }
    if (completionHandler) {
        completionHandler(success, error);
    }
}

- (void)removeTrackById:(NSNumber *)trackId withCompletionHandler:(void(^)(BOOL success, NSError *error))completionHandler
{
    AVMutableCompositionTrack *cpTrack = _addedCompositionTrackDict[trackId];
    if (!cpTrack) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSURLErrorDomain
                                                      code:-1
                                                  userInfo:@{NSLocalizedDescriptionKey:
                                                                 [NSString stringWithFormat:@"can not find track with id: {%@}",
                                                                  trackId]}]);
            
        }
        return;
    }
    [_composition removeTrack:cpTrack];
}

- (void)setTrackVolume:(CGFloat)volume withTrackId:(NSNumber *)trackId completionHandler:(void(^)(BOOL success,
                                                                                                  NSError *error))completionHandler
{
    AVAssetTrack *track = _trackDict[trackId];
    if (!track) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSURLErrorDomain
                                                      code:-1
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"can not find track with id: {%@}", trackId]
                                                  }]);
        }
        return;
    }
    if (track.mediaType != AVMediaTypeAudio) {
        if (completionHandler) {
            completionHandler(NO, [NSError errorWithDomain:NSURLErrorDomain
                                                      code:-1
                                                  userInfo:@{
                                                      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"track is audio with id: {%@}", trackId]
                                                  }]);
        }
        return;
    }
    AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    [parameters setVolume:volume atTime:kCMTimeZero];
    [_audioMixInputParameters addObject:parameters];
    if (completionHandler) {
        completionHandler(YES, nil);
    }
}

- (void)destroy
{
    for (AVMutableCompositionTrack *cpTrack in [_addedCompositionTrackDict allValues]) {
        [_composition removeTrack:cpTrack];
    }
    [_trackDict removeAllObjects];
    [_addedCompositionTrackDict removeAllObjects];
    [_audioMixInputParameters removeAllObjects];
    _currentTrackId = 1;
}

- (void)exportWithCompletionHandler:(void(^)(BOOL success, NSDictionary *result, NSError *error))completionHandler
{
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:_composition
                                                                      presetName:AVAssetExportPresetMediumQuality];
    NSString *outputPath = [[PathUtils tempFilePath] stringByAppendingPathComponent:
                            [NSString stringWithFormat:@"%@.mp4",[[NSUUID UUID] UUIDString]]];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    exporter.outputURL = outputURL;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [_audioMixInputParameters copy];

    exporter.audioMix = audioMix;
    NSNumber *containerId = self.containerId;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            switch ([exporter status]) {
                    
                case AVAssetExportSessionStatusFailed:
                case AVAssetExportSessionStatusCancelled:
                {
                    WALOG(@"合成失败：%@",[[exporter error] localizedDescription]);
                    if (completionHandler) {
                        completionHandler(NO, nil, exporter.error);
                    }
                }
                    break;
                    
                case AVAssetExportSessionStatusCompleted:
                    if (completionHandler) {
                        NSDictionary *result = [self getOutputMediaInfoWithOutputPath:outputPath inContainer:containerId];
                        completionHandler(YES, result, nil);
                    }
                    break;
                    
                default:
                    if (completionHandler) {
                        completionHandler(NO,nil, exporter.error);
                    }
                    break;
            }
        });
    }];
}

- (NSDictionary *)getOutputMediaInfoWithOutputPath:(NSString *)path inContainer:(NSNumber *)containerId
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    kWA_DictSetObjcForKey(dict, @"bitrate", @([WAMediaUtils getBitRateWithVideo:[AVAsset assetWithURL:[NSURL fileURLWithPath:path]]]))
    kWA_DictSetObjcForKey(dict, @"containerId", containerId)
    kWA_DictSetObjcForKey(dict, @"size", @([FileUtils getFileSize:path]))
    kWA_DictSetObjcForKey(dict, @"tempFilePath", path)
    NSEnumerator *enumerator = [[_addedCompositionTrackDict allKeys] reverseObjectEnumerator];
    AVMutableCompositionTrack *track = nil;
    BOOL isLastAudio = NO;
    while ((track = enumerator.nextObject)) {
        //只会有一个视频轨道
        CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions.firstObject;
        CMVideoCodecType codec = CMVideoFormatDescriptionGetCodecType(desc);
        NSString *codecName = [WAMediaUtils codecTypeToString:codec];
        NSNumber *duration = @(CMTimeGetSeconds(track.timeRange.duration) * 1000);
        NSNumber *bitrate = @(roundf(track.estimatedDataRate));
        
        if (track.mediaType == AVMediaTypeVideo) {
            CGSize size = [WAMediaUtils queryVideoResolutionWithAssetTrack:track];
            NSDictionary *vidioDict = @{
                @"bitrate"      : bitrate,
                @"codecName"    : codecName,
                @"duration"     : duration,
                @"fps"          : @([WAMediaUtils getFpsWithVideoTrack:track]),
                @"height"       : @(size.height),
                @"width"        : @(size.width)
            };
            kWA_DictSetObjcForKey(dict, @"video", vidioDict)
        }
        //只包含最后一个音频轨道信息
        if (track.mediaType == AVMediaTypeAudio && !isLastAudio) {
            size_t size = 0;
            UInt32 channel = 0;
            Float64 samplerate = 0;
            const AudioFormatListItem * item = CMAudioFormatDescriptionGetFormatList(desc, &size);
            if (item != NULL) {
                channel = item[0].mASBD.mChannelsPerFrame;
                samplerate = item[0].mASBD.mSampleRate;
            }
            NSDictionary *audioDict = @{
                @"bitrate"      : bitrate,
                @"codecName"    : codecName,
                @"duration"     : duration,
                @"channel"      : @(channel),
                @"samplerate"   : @(samplerate)
            };
            
            kWA_DictSetObjcForKey(dict, @"audio", audioDict)
            isLastAudio = YES;
        }
    }
    return [dict copy];
}

@end
