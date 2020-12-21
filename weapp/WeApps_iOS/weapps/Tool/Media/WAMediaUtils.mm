//
//  VideoUtils.m
//  weapps
//
//  Created by tommywwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "WAMediaUtils.h"
#import "SDAVAssetExportSession.h"
#import "PathUtils.h"
#import "FileUtils.h"

#define VIDEO_FRAMERATE_DEFAULT 30  //视频默认帧率

typedef  struct  {

char        fccID[4];

uint32_t      dwSize;

char        fccType[4];

} HEADER;

typedef  struct  {

char        fccID[4];

uint32_t      dwSize;

uint16_t      wFormatTag;

uint16_t      wChannels;

uint32_t      dwSamplesPerSec;

uint32_t      dwAvgBytesPerSec;

uint16_t      wBlockAlign;

uint16_t      uiBitsPerSample;

}FMT;

typedef  struct  {

char        fccID[4];

uint32_t      dwSize;

}DATA;

@implementation WAMediaUtils


//参考http://soundfile.sapp.org/doc/WaveFormat/
+ (NSData *)wavHeaderDataWithSamples:(uint32_t)sample
                                rate:(uint32_t)rate
                            channels:(uint16_t)channels
                       bitsPerChannel:(uint16_t)bitsPerChannel
                            dataSize:(uint32_t)dataSize
{
    
    HEADER header;
    header.fccID[0] = 'R';
    header.fccID[1] = 'I';
    header.fccID[2] = 'F';
    header.fccID[3] = 'F';
    header.dwSize = dataSize + 36;
    header.fccType[0] = 'W';
    header.fccType[1] = 'A';
    header.fccType[2] = 'V';
    header.fccType[3] = 'E';

    FMT fmt;
    fmt.fccID[0] = 'f';
    fmt.fccID[1] = 'm';
    fmt.fccID[2] = 't';
    fmt.fccID[3] = ' ';
    fmt.dwSize = 16;
    fmt.wFormatTag = 1;
    fmt.wChannels = channels;
    fmt.dwSamplesPerSec = sample;
    fmt.dwAvgBytesPerSec = rate;
    fmt.wBlockAlign = channels * bitsPerChannel / 8;
    fmt.uiBitsPerSample = bitsPerChannel;

    DATA data;
    data.fccID[0] = 'd';
    data.fccID[1] = 'a';
    data.fccID[2] = 't';
    data.fccID[3] = 'a';
    data.dwSize = dataSize;
    
    NSMutableData *wavHeaderData = [NSMutableData dataWithBytes:&header length:sizeof(header)];
    [wavHeaderData appendBytes:&fmt length:sizeof(fmt)];
    [wavHeaderData appendBytes:&data length:sizeof(data)];
//    NSMutableData *wavHeaderData = [NSMutableData dataWithBytes:&wavHeader length:sizeof(wavHeader)];
    return wavHeaderData;
}


+ (UIImage *)queryVideoImageOfFile:(NSString *)filePath withTime:(CMTime)tm error:(NSError **)error
{
    if (![FileUtils isValidFile:filePath]) {
        if (error) {
            *error = GetErrorWithCode(-1, @"queryVideoImageOfFile");
        }
        return nil;
    }
    NSURL *url = [NSURL fileURLWithPath:filePath];
  
    AVURLAsset *set = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *gen = [AVAssetImageGenerator assetImageGeneratorWithAsset:set];
    gen.appliesPreferredTrackTransform = YES;
    CMTime actualTm;
    CGImageRef imgRef = [gen copyCGImageAtTime:tm actualTime:&actualTm error:error];
    if (imgRef) {
        UIImage *image = [UIImage imageWithCGImage:imgRef scale:1.0 orientation:UIImageOrientationUp];
        CGImageRelease(imgRef);
        
        return image;
    } else if (*error) {
        *error = GetErrorWithCode(-1, [NSString stringWithFormat:@"queryVideoImageOfFile failed,file: (%@)",filePath]);
    }
    return nil;
}


+ (NSTimeInterval)getDurationWithVideo:(NSString *)path
{
    if (path.length == 0) {
        return 0;
    }
    return [self getDurationWithVideoURL:[NSURL fileURLWithPath:path]];
}


+ (NSTimeInterval)getDurationWithVideoURL:(NSURL *)url
{
    if (!url) {
        return 0;
    }
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url
                                                options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         [NSNumber numberWithBool:YES],
                                                         AVURLAssetPreferPreciseDurationAndTimingKey,
                                                         nil]];
    
    return [self getDurationWithAssert:asset];
}

+ (NSTimeInterval)getDurationWithAssert:(AVAsset *)asset
{
    NSTimeInterval durationInSeconds = 0.0;
    if (asset)
    {
        durationInSeconds = CMTimeGetSeconds(asset.duration);
    }
    return durationInSeconds;
}


+ (float)getFpsWithVideo:(AVAsset *)asset
{
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        return roundf(track.nominalFrameRate);
    }
    return 0;
}

+ (float)getFpsWithVideoTrack:(AVAssetTrack *)track
{
    if (![track.mediaType isEqualToString:AVMediaTypeVideo]) {
        return 0;
    }
    return roundf(track.nominalFrameRate);
}

+ (float)getBitRateWithVideo:(AVAsset *)asset
{
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
       AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo][0];
       return roundf(track.estimatedDataRate);
    }
    return 0;
}


+ (CGSize)queryVideoResolutionWithAsset:(AVAsset *)asset
{
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        return [self queryVideoResolutionWithAssetTrack:track];
    }
    return CGSizeZero;
}

+ (CGSize)queryVideoResolutionWithAssetTrack:(AVAssetTrack *)assetTrack
{
    if (![assetTrack.mediaType isEqualToString:AVMediaTypeVideo]) {
        return CGSizeZero;;
    }
    CGSize naturalSize = assetTrack.naturalSize;
    if (!CGSizeEqualToSize(naturalSize, CGSizeZero)) {
        return GetSizeWithTransform(assetTrack.preferredTransform, naturalSize);
    }
    return CGSizeZero;;
}

+ (NSString *)stringByDuration:(NSInteger)duration
{
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)duration / 60, (long)duration % 60];
}


+ (NSString *)orientationOfAsset:(AVAsset *)asset
{
    if ([asset tracksWithMediaType:AVMediaTypeVideo].count > 0) {
        AVAssetTrack *track = [asset tracksWithMediaType:AVMediaTypeVideo][0];
        return getOrientation(track.preferredTransform);
    }
    return @"unknown";
}

+ (NSString *)codecTypeToString:(CMVideoCodecType)codecType
{
    if (codecType == kCMVideoCodecType_422YpCbCr8) return @"422YpCbCr8";
    if (codecType == kCMVideoCodecType_Animation) return @"Animation";
    if (codecType == kCMVideoCodecType_Cinepak) return @"Cinepak";
    if (codecType == kCMVideoCodecType_JPEG) return @"JPEG";
    if (codecType == kCMVideoCodecType_JPEG_OpenDML) return @"JPEG OpenDML";
    if (codecType == kCMVideoCodecType_SorensonVideo) return @"Sorenson Video";
    if (codecType == kCMVideoCodecType_SorensonVideo3) return @"Sorenson Video 3";
    if (codecType == kCMVideoCodecType_H263) return @"H263";
    if (codecType == kCMVideoCodecType_H264) return @"H264";
    if (codecType == kCMVideoCodecType_HEVC) return @"HEVC";
    if (codecType == kCMVideoCodecType_MPEG4Video) return @"MPEG4 Video";
    if (codecType == kCMVideoCodecType_MPEG2Video) return @"MPEG2 Video";
    if (codecType == kCMVideoCodecType_MPEG1Video) return @"MPEG1 Video";
    if (codecType == kCMVideoCodecType_DVCNTSC) return @"DVC NTSC";
    if (codecType == kCMVideoCodecType_DVCPAL) return @"DVC PAL";
    if (codecType == kCMVideoCodecType_DVCProPAL) return @"DVCPro PAL";
    if (codecType == kCMVideoCodecType_DVCPro50NTSC) return @"DVCPro50 NTSC";
    if (codecType == kCMVideoCodecType_DVCPro50PAL) return @"DVCPro50 PAL";
    if (codecType == kCMVideoCodecType_DVCPROHD720p60) return @"DVCPRO HD 720p 60";
    if (codecType == kCMVideoCodecType_DVCPROHD720p50) return @"DVCPRO HD 720p 50";
    if (codecType == kCMVideoCodecType_DVCPROHD1080i60) return @"DVCPRO HD 1080i 60";
    if (codecType == kCMVideoCodecType_DVCPROHD1080i50) return @"DVCPRO HD 1080i 50";
    if (codecType == kCMVideoCodecType_DVCPROHD1080p30) return @"DVCPRO HD 1080p 30";
    if (codecType == kCMVideoCodecType_DVCPROHD1080p25) return @"DVCPRO HD 1080p 25";
    if (codecType == kCMVideoCodecType_AppleProRes4444) return @"Apple ProRes 4444";
    if (codecType == kCMVideoCodecType_AppleProRes422HQ) return @"Apple ProRes 422 HQ";
    if (codecType == kCMVideoCodecType_AppleProRes422) return @"Apple ProRes 422";
    if (codecType == kCMVideoCodecType_AppleProRes422LT) return @"Apple ProRes 422 LT";
    if (codecType == kCMVideoCodecType_AppleProRes422Proxy) return @"Apple ProRes 422 Proxy";
    return @"Unknown";
}

+ (void)compressVideo:(NSURL *)URL
         output:(NSURL *)outUrl
    withQuality:(WAVideoQualityType)qulityType
        bitRate:(NSUInteger)bitRate
            fps:(NSUInteger)fps
resolutionScale:(CGFloat)resolutionScale
       complete:(void(^)(BOOL success, NSError *err))completeBlock
{
    if (![FileUtils isValidFile:URL.path]) {
        if (completeBlock) {
            completeBlock(NO,[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"文件不存在"}]);
        }
        return;
    }
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];

    if (!asset || [asset tracksWithMediaType:AVMediaTypeVideo].count < 1) {
        if (completeBlock) {
            completeBlock(NO,[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"创建asset失败或未找到视频通道"}]);
        }
        return;
    }

    //quality有值,使用系统按low，medium，high压缩
    if (qulityType != WAVideoQualityTypeNone) {
        NSString *quality = @"low";
        switch (qulityType) {
            case WAVideoQualityTypeHigh:
                quality = AVAssetExportPresetHighestQuality;
                break;
            case WAVideoQualityTypeMedium:
                quality = AVAssetExportPresetMediumQuality;
                break;
            case WAVideoQualityTypeLow:
                quality = AVAssetExportPresetLowQuality;
                break;
            default:
                break;
        }
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset
                                                                               presetName:quality];
        exportSession.outputURL = outUrl;
        exportSession.outputFileType = AVFileTypeMPEG4;
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status != AVAssetExportSessionStatusCompleted) {
                if (exportSession.status == AVAssetExportSessionStatusCancelled) {
                    if (completeBlock) {
                         completeBlock(NO,[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"压缩失败"}]);
                     }
                }else{
                    completeBlock(NO, exportSession.error);
                }
            } else {
                if (completeBlock) {
                    completeBlock(YES,nil);
                }
            }
        }];
        return;
    }
    
    
    NSArray *metaData = asset.commonMetadata;
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize naturalSize = videoTrack.naturalSize;
    CGSize compressSize;
    if(naturalSize.width == 0 || naturalSize.height == 0){
        if (completeBlock) {
            completeBlock(NO,[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"compress fail, error(fail to get video resolution)"}]);
        }
        return;
    }

    compressSize.height = naturalSize.height * resolutionScale;
    compressSize.width = naturalSize.width * resolutionScale;
    if (bitRate <= 0) {
        bitRate = 3700;
    }

    compressSize = GetSizeWithTransform(videoTrack.preferredTransform, compressSize);

    NSDictionary *videoSettings = @{
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: [NSNumber numberWithFloat:compressSize.width],
        AVVideoHeightKey: [NSNumber numberWithFloat:compressSize.height],
        AVVideoCompressionPropertiesKey: @
        {
            AVVideoAverageBitRateKey: [NSNumber numberWithLong:bitRate],
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
            AVVideoAverageNonDroppableFrameRateKey: @(fps)
        },
    };

    if (fps <= 0) {
        fps  = VIDEO_FRAMERATE_DEFAULT;
    }
    if (fps > videoTrack.nominalFrameRate) {
        fps = videoTrack.nominalFrameRate;
    }

    SDAVAssetExportSession *session = [[SDAVAssetExportSession alloc] initWithAsset:asset];
    session.videoSettings = videoSettings;
    session.audioSettings = @
    {
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @(44100),
        AVEncoderBitRateKey: @(64000),
    };
    session.outputURL = outUrl;
    session.outputFileType = AVFileTypeMPEG4;
    session.metadata = metaData;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status != AVAssetExportSessionStatusCompleted) {
            if (session.status == AVAssetExportSessionStatusCancelled) {
                if (completeBlock) {
                     completeBlock(NO,[NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: @"压缩失败"}]);
                 }
            }else{
                completeBlock(NO, session.error);
            }
        } else {
            if (completeBlock) {
                completeBlock(YES,nil);
            }
        }
    }];
}


static CGSize GetSizeWithTransform(CGAffineTransform transform, CGSize inputSize)
{
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
        return CGSizeMake(inputSize.height, inputSize.width);
    }
    return inputSize;
}


   
static NSError *GetErrorWithCode(NSInteger errorCode, NSString *errDesc)
{
    NSDictionary *info = nil;
    if (errDesc) {
        info = @{NSLocalizedFailureReasonErrorKey:errDesc};
    }
    return [NSError errorWithDomain:@"VideoUtils"
                               code:errorCode
                           userInfo:info];
}


static NSString *getOrientation(CGAffineTransform transform)
{
    if (transform.a == 0 && transform.b == 1 && transform.c == -1 && transform.d == 0) {
        return @"up";
    } else if (transform.a == 0 && transform.b == -1 && transform.c == -1 && transform.d == 0) {
        return @"up-mirrored";
    } else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == -1){
        return @"right";
    } else if (transform.a == -1 && transform.b == 0 && transform.c == 0 && transform.d == 1) {
        return @"right-mirrored";
    } else if (transform.a == 0 && transform.b == -1 && transform.c == 1 && transform.d == 0){
        return @"down";
    } else if (transform.a == 0 && transform.b == 1 && transform.c == 1 && transform.d == 0){
        return @"down-mirrored";
    } else if (transform.a == 1 && transform.b == 0 && transform.c == 0 && transform.d == 1) {
        return @"left";
    } else if (transform.a == 1 && transform.b == 0 && transform.c == 0 && transform.d == -1){
        return @"lef-mirrored";
    }
    return @"unknown";
}
@end
