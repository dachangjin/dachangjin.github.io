//
//  MAMp3EncodeOperation.m
//  AudioQueueRecoder
//
//  Created by jreeqiu on 2019/3/1.
//  Copyright © 2020 tencent. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "MAMp3EncodeOperation.h"
#import "lame.h"
#import "MAAACEncoder.h"
#import "MARecordTools.h"
#import "WAMediaUtils.h"

@interface MAMp3EncodeOperation() {
    BOOL _setToStopped;
    MAAACEncoder *_aacEncoder;
    uint32_t _totalSize;
}
@end
@implementation MAMp3EncodeOperation

- (BOOL)prepareEncoder {
    _aacEncoder = [[MAAACEncoder alloc] init];
    _aacEncoder.format = _format;
    _aacEncoder.encodeBitRate = _encodeBitRate;
    return [_aacEncoder setupEncoder];
}

- (void)stop {
    _setToStopped = YES;
}

- (void)main {
    if (_currentMp3File.length == 0 || _innerPathFile.length == 0) {
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_currentMp3File]) {
        [[NSFileManager defaultManager] createFileAtPath:_currentMp3File contents:nil attributes:nil];
    }
    
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:_currentMp3File];
    [handle seekToEndOfFile];
    
    _totalSize = 0;
    if ([_formatType isEqualToString:@"mp3"]) {
        WALOG(@"encode mp3 file");
        // lame param init
        lame_t lame = lame_init();
        lame_set_num_channels(lame, _format.mChannelsPerFrame);
        lame_set_in_samplerate(lame, _format.mSampleRate);
        lame_set_brate(lame, _encodeBitRate/1000);
        lame_set_mode(lame, 1);
        lame_set_quality(lame, 2);
        lame_init_params(lame);
        while (true) {
            
            BOOL isLastData = NO;
            NSData *audioData = [_recordTools popQueueIsLastData:&isLastData];
            if (audioData != nil) {
                
                NSUInteger pcmLen = audioData.length;
                NSUInteger nsamples = pcmLen / 2;
                
                unsigned char *buffer = malloc(pcmLen);
                
                // mp3 encode
                int recvLen = 0;
                if (_format.mChannelsPerFrame == 1) {
                    recvLen = lame_encode_buffer(lame, (short *)audioData.bytes, (short *)audioData.bytes, (int)nsamples, buffer, (int)pcmLen);
                }else{
                    recvLen = lame_encode_buffer_interleaved(lame, (short *)audioData.bytes, (int)nsamples/2, buffer, (int)pcmLen);
                }
                
                NSData *piece = [NSData dataWithBytes:buffer length:recvLen];
                [handle writeData:piece];
                
                free(buffer);
                NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
                if (piece.length > 0) {
                    dictionary[@"frameBuffer"] = piece;
                }
                dictionary[@"isLastFrame"] = @(isLastData);
                
                [_recordTools performSelectorOnMainThread:@selector(mp3dataEncoded:) withObject:dictionary waitUntilDone:NO];
            }else {
                if (_setToStopped) {
                    break;
                } else {
                    [NSThread sleepForTimeInterval:0.05];
                }
            }
            
        }
        lame_close(lame);
    } else if ([[_formatType lowercaseString] isEqualToString:@"aac"]){
        WALOG(@"encode aac file");
        while (true) {
            BOOL isLastData = NO;
            NSData *audioData = [_recordTools popQueueIsLastData:&isLastData];
            if (audioData != nil) {
                NSData *piece = [_aacEncoder encodeBufferData:audioData];
                if (piece.length > 0) {
                    [handle writeData:piece];
                }
            }else {
                if (_setToStopped) {
                    break;
                } else {
                    [NSThread sleepForTimeInterval:0.05];
                }
            }
        }
    } else if ([[_formatType lowercaseString] isEqualToString:@"wav"] || [[_formatType lowercaseString] isEqualToString:@"pcm"]) {
        WALOG(@"encode PCM file");
        while (true) {
            BOOL isLastData = NO;
            NSData *audioData = [_recordTools popQueueIsLastData:&isLastData];
            if (audioData != nil) {
                [handle writeData:audioData];
                _totalSize += audioData.length;
            }else {
                if (_setToStopped) {
                    break;
                } else {
                    [NSThread sleepForTimeInterval:0.05];
                }
            }
        }
        if ([[_formatType lowercaseString] isEqualToString:@"wav"]) {
            // 将cpm转换为wav
            NSData *wavHeader = [WAMediaUtils wavHeaderDataWithSamples:_format.mSampleRate
                                                                  rate:_encodeBitRate
                                                              channels:_format.mChannelsPerFrame
                                                        bitsPerChannel:_format.mBitsPerChannel
                                                              dataSize:_totalSize];
            [handle seekToFileOffset:0];
            NSData *pcmData = [handle readDataToEndOfFile];
            [handle seekToFileOffset:0];
            [handle writeData:wavHeader];
            [handle writeData:pcmData];
        }
    }
    [handle closeFile];
    
    WALOG(@"finish encode");
    [_recordTools performSelectorOnMainThread:@selector(finish) withObject:nil waitUntilDone:NO];
}

@end
