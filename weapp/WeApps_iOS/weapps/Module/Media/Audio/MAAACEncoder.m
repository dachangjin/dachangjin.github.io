//
//  MAAACEncoder.m
//
//
//  Created by jreeqiu on 3/20/19.
//  Copyright (c) 2019 Tencent. All rights reserved.
//
//
#import "MAAACEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MAAACEncoder() {
    AudioConverterRef _audioConverter;
    uint8_t *_aacBuffer;
    NSUInteger _aacBufferSize;
    char *_pcmBuffer;
    size_t _pcmBufferSize;
}
@end

@implementation MAAACEncoder
- (void)dealloc {
    AudioConverterDispose(_audioConverter);
    free(_aacBuffer);
}

- (id)init {
    if (self = [super init]) {
        _audioConverter = NULL;
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        _aacBufferSize = 1024;
        _aacBuffer = malloc(_aacBufferSize * sizeof(uint8_t));
        memset(_aacBuffer, 0, _aacBufferSize);
    }
    return self;
}

- (BOOL)setupEncoder {
    AudioStreamBasicDescription inAudioStreamBasicDescription = _format;
    AudioStreamBasicDescription outAudioStreamBasicDescription = {0};
    // Always initialize the fields of a new audio stream basic description structure to zero, as shown here: ...
    outAudioStreamBasicDescription.mSampleRate = inAudioStreamBasicDescription.mSampleRate;
    // The number of frames per second of the data in the stream, when the stream is played at normal speed. For compressed formats, this field indicates the number of frames per second of equivalent decompressed data. The mSampleRate field must be nonzero, except when this structure is used in a listing of supported formats (see “kAudioStreamAnyRate”).
    outAudioStreamBasicDescription.mFormatID = kAudioFormatMPEG4AAC;
    // kAudioFormatMPEG4AAC_HE does not work. Can't find `AudioClassDescription`. `mFormatFlags` is set to 0.
    outAudioStreamBasicDescription.mFormatFlags = kMPEG4Object_AAC_LC;
    // Format-specific flags to specify details of the format. Set to 0 to indicate no format flags. See “Audio Data Format Identifiers” for the flags that apply to each format.
    outAudioStreamBasicDescription.mBytesPerPacket = 0;
    // The number of bytes in a packet of audio data. To indicate variable packet size, set this field to 0. For a format that uses variable packet size, specify the size of each packet using an AudioStreamPacketDescription structure.
    outAudioStreamBasicDescription.mFramesPerPacket = 1024;
    // The number of frames in a packet of audio data. For uncompressed audio, the value is 1. For variable bit-rate formats, the value is a larger fixed number, such as 1024 for AAC. For formats with a variable number of frames per packet, such as Ogg Vorbis, set this field to 0.
    outAudioStreamBasicDescription.mBytesPerFrame = 0;
    // The number of bytes from the start of one frame to the start of the next frame in an audio buffer. Set this field to 0 for compressed formats. ...
    outAudioStreamBasicDescription.mChannelsPerFrame = inAudioStreamBasicDescription.mChannelsPerFrame;
    // The number of channels in each frame of audio data. This value must be nonzero.
    outAudioStreamBasicDescription.mBitsPerChannel = 0;
    // ... Set this field to 0 for compressed formats.
    outAudioStreamBasicDescription.mReserved = 0;
    // Pads the structure out to force an even 8-byte alignment. Must be set to 0.
    AudioClassDescription *description = [self
                                          getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                          fromManufacturer:kAppleSoftwareAudioCodecManufacturer];
    OSStatus status = AudioConverterNewSpecific(&inAudioStreamBasicDescription,
                                                &outAudioStreamBasicDescription,
                                                1,
                                                description,
                                                &_audioConverter);
    if (status != 0) {
        WALOG(@"setup converter: %d", (int)status);
        return NO;
    }
    
    UInt32 size = sizeof(_encodeBitRate);
    status = AudioConverterSetProperty(_audioConverter,kAudioConverterEncodeBitRate, size, &_encodeBitRate);
    if (status != 0) {
        WALOG(@"EncodeBitRate setup converter: %d", (int)status);
        return NO;
    }
    return YES;
}

- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer {
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    OSStatus st;
    
    UInt32 size;
    st = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (st) {
        WALOG(@"error getting audio format propery info: %d", (int)(st));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    st = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (st) {
        WALOG(@"error getting audio format propery: %d", (int)(st));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

static OSStatus inInputDataProc(AudioConverterRef inAudioConverter,
                                UInt32 *ioNumberDataPackets,
                                AudioBufferList *ioData,
                                AudioStreamPacketDescription **outDataPacketDescription,
                                void *inUserData) {
    
    MAAACEncoder *encoder = (__bridge MAAACEncoder *)(inUserData);
    UInt32 requestedPackets = 0;
    if (ioNumberDataPackets) {
        requestedPackets = *ioNumberDataPackets;
    }
    //NSLog(@"Number of packets requested: %d", (unsigned int)requestedPackets);
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //NSLog(@"PCM buffer isn't full enough!");
        if (ioNumberDataPackets) {
            *ioNumberDataPackets = 0;
        }
        return -1;
    }
    if (ioNumberDataPackets) {
        *ioNumberDataPackets = 1;
    }
    //NSLog(@"Copied %zu samples into ioData", copiedSamples);
    return noErr;
}

- (size_t) copyPCMSamplesIntoBuffer:(AudioBufferList*)ioData {
    size_t originalBufferSize = _pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = _pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (UInt32)_pcmBufferSize;
    if (_pcmBuffer) {
        free(_pcmBuffer);
        _pcmBuffer = NULL;
    }
    _pcmBufferSize = 0;
    return originalBufferSize;
}

- (NSData *)encodeBufferData:(NSData *)data {
    _pcmBufferSize = [data length];
    _pcmBuffer = malloc([data length]);
    [data getBytes:_pcmBuffer length:_pcmBufferSize];
    
    
    memset(_aacBuffer, 0, _aacBufferSize);
    AudioBufferList outAudioBufferList = {0};
    outAudioBufferList.mNumberBuffers = 1;
    outAudioBufferList.mBuffers[0].mNumberChannels = _format.mChannelsPerFrame;
    outAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)_aacBufferSize;
    outAudioBufferList.mBuffers[0].mData = _aacBuffer;
    AudioStreamPacketDescription *outPacketDescription = NULL;
    UInt32 ioOutputDataPacketSize = 1;
    OSStatus status = AudioConverterFillComplexBuffer(_audioConverter,
                                                      inInputDataProc,
                                                      (__bridge void *)(self),
                                                      &ioOutputDataPacketSize,
                                                      &outAudioBufferList,
                                                      outPacketDescription);
    if (status == 0) {
        NSData *rawAAC = [NSData dataWithBytes:outAudioBufferList.mBuffers[0].mData
                                        length:outAudioBufferList.mBuffers[0].mDataByteSize];
        NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
        NSMutableData *fullData = [NSMutableData dataWithData:adtsHeader];
        [fullData appendData:rawAAC];
        return fullData;
    } else {
        
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        WALOG(@"encode %@",error);
        return nil;
    }
}
/**
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/

- (NSData*) adtsDataForPacketLength:(NSUInteger)packetLength {
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    // Variables Recycled by addADTStoPacket
    int profile = 2;  //AAC LC
    //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
    int freqIdx = [self freqIdx];
    int chanCfg = _format.mChannelsPerFrame;  //MPEG-4 Audio Channel Configuration. 1 Channel front-center
    NSUInteger fullLength = adtsLength + packetLength;
    // fill in ADTS data
    packet[0] = (char)0xFF;    // 11111111      = syncword
    packet[1] = (char)0xF9;    // 1111 1 00 1  = syncword MPEG-2 Layer CRC
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

- (int)freqIdx {
    NSArray *sampleRates = @[@(96000), @(88200), @(64000), @(48000), @(44100), @(32000),
                             @(24000), @(22050), @(16000), @(12000), @(11025), @(8000),
                             @(7350)];
    if ([sampleRates containsObject: @((NSInteger)_format.mSampleRate)]) {
        return (int)[sampleRates indexOfObject:@((NSInteger)_format.mSampleRate)];
    }
    return 0;
}
@end
