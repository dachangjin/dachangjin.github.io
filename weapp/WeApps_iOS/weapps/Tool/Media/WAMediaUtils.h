//
//  VideoUtils.h
//  weapps
//
//  Created by tommywwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, WAVideoQualityType) {
    WAVideoQualityTypeLow = 1 << 0,
    WAVideoQualityTypeMedium = 1 << 1,
    WAVideoQualityTypeHigh = 1 << 2,
    WAVideoQualityTypeNone = 1 << 3,
};


/// 视频处理
@interface WAMediaUtils : NSObject



/// 根据pcm文件信息生成wav头
/// @param sample 采样率
/// @param rate 码率
/// @param channels 声道数
/// @param bitsPerChannel 每个采样所占bit
/// @param dataSize pcm文件大小
+ (NSData *)wavHeaderDataWithSamples:(uint32_t)sample
                                rate:(uint32_t)rate
                            channels:(uint16_t)channels
                      bitsPerChannel:(uint16_t)bitsPerChannel
                            dataSize:(uint32_t)dataSize;

/// 获取视频中的图片
/// @param filePath 视频路径
/// @param tm 时间
/// @param error 错误
+ (UIImage *)queryVideoImageOfFile:(NSString *)filePath withTime:(CMTime)tm error:(NSError **)error;

/// 获取视频时长
/// @param path 视频本地路径
+ (NSTimeInterval)getDurationWithVideo:(NSString *)path;

/// 获取视频时长
/// @param url 视频路径
+ (NSTimeInterval)getDurationWithVideoURL:(NSURL *)url;

/// 获取资源时长
/// @param asset 资源
+ (NSTimeInterval)getDurationWithAssert:(AVAsset *)asset;

/// 获取fps
/// @param asset 视频文件
+ (float)getFpsWithVideo:(AVAsset *)asset;

/// 获取视频轨道fps
/// @param assetTrack 视频轨道
+ (float)getFpsWithVideoTrack:(AVAssetTrack *)assetTrack;

/// 获取bitRate
/// @param asset 视频文件
+ (float)getBitRateWithVideo:(AVAsset *)asset;

/// 获取分辨率
/// @param asset 视频文件
+ (CGSize)queryVideoResolutionWithAsset:(AVAsset *)asset;

/// 获取分辨率
/// @param assetTrack 视频轨道
+ (CGSize)queryVideoResolutionWithAssetTrack:(AVAssetTrack *)assetTrack;

/// 时长转换mm:ss
/// @param duration 时长，秒数
+ (NSString *)stringByDuration:(NSInteger)duration;


/// 视频方向
/// @param asset 视频文件
+ (NSString *)orientationOfAsset:(AVAsset *)asset;


/// CMVideoCodecType转为string
/// @param codecType CMVideoCodecType
+ (NSString *)codecTypeToString:(CMVideoCodecType)codecType;

/// 压缩视频
/// @param URL 输入源
/// @param outUrl 输出源
/// @param qulityType 质量
/// @param bitRate 码率
/// @param fps 帧率
/// @param resolutionScale 相对原视频分辨率比，取值范围(0, 1]
/// @param completeBlock 完成回调
+ (void)compressVideo:(NSURL *)URL
               output:(NSURL *)outUrl
          withQuality:(WAVideoQualityType)qulityType
              bitRate:(NSUInteger)bitRate
                  fps:(NSUInteger)fps
      resolutionScale:(CGFloat)resolutionScale
             complete:(void(^)(BOOL success, NSError *err))completeBlock;

@end

NS_ASSUME_NONNULL_END
