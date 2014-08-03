//
//  DZAudioQueuePlayer.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#ifndef __mypodcast__DZAudioQueuePlayer__
#define __mypodcast__DZAudioQueuePlayer__

#include <AudioToolbox/AudioToolbox.h>

const UInt32 kDZMaxNumBuffers = 16;

class DZAudioQueuePlayer {
    AudioQueueRef _queue;
    AudioFileStreamID _parser;
    AudioStreamBasicDescription _format;
    void * _magicCookie;
    UInt32 _magicCookieSize;
    AudioQueueBufferRef _freeBuffers[kDZMaxNumBuffers];
    
    UInt32 _numQueueBuffer;
    UInt32 _numFreeBuffer;
    
public:
    DZAudioQueuePlayer(AudioFileTypeID typeHint);
    virtual ~DZAudioQueuePlayer();

    OSStatus parse(const void * data, UInt32 length);
    OSStatus prime();
    OSStatus start();
    OSStatus pause();
    OSStatus stop();
    OSStatus flush();
    Float64 getCurrentTime();
    
    void onProperty(AudioFileStreamPropertyID pID);
    void onPackets(UInt32 numBytes, UInt32 numPackets, const void * data, AudioStreamPacketDescription * packetDesc);
    void onFinishBuffer(AudioQueueBufferRef buffer);
};

#endif /* defined(__mypodcast__DZAudioQueuePlayer__) */
