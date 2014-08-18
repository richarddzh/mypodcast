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

const UInt32 kDZMaxNumFreeBuffers = 8;

class DZAudioQueueBufferList;
class DZAudioQueuePlayer;

typedef enum _dz_audio_queue_player_status_ {
    DZAudioQueuePlayerStatus_NotReady = 0,
    DZAudioQueuePlayerStatus_ReadyToStart,
    DZAudioQueuePlayerStatus_Running,
    DZAudioQueuePlayerStatus_Paused,
    DZAudioQueuePlayerStatus_Stopped,
    DZAudioQueuePlayerStatus_Error = -1
} DZAudioQueuePlayerStatus;

class DZAudioQueuePlayer {
    AudioQueueRef _queue;
    AudioFileStreamID _parser;
    AudioStreamBasicDescription _format;
    void * _magicCookie;
    UInt32 _magicCookieSize;
    
    DZAudioQueueBufferList * _bufferList;
    Float64 _timeAmendment;
    DZAudioQueuePlayerStatus _status;
    
public:
    DZAudioQueuePlayer(AudioFileTypeID typeHint);
    virtual ~DZAudioQueuePlayer();

    OSStatus parse(const void * data, UInt32 length);
    OSStatus prime();
    OSStatus start();
    OSStatus pause();
    OSStatus stop(bool immediately = true);
    OSStatus flush();
    // Negative return value means that seeking is failed.
    SInt64 seek(float time);
    Float64 getCurrentTime();
    
    // Should use the following function to observe buffer status.
    UInt32 getNumByteQueued();
    UInt32 getNumFreeBuffer();
    UInt32 getNumQueueBuffer();
    DZAudioQueuePlayerStatus getStatus();
    
    // The following functions are called by callback function.
    // They shall not be directly called.
    void onProperty(AudioFileStreamPropertyID pID);
    void onPackets(UInt32 numBytes, UInt32 numPackets, const void * data, AudioStreamPacketDescription * packetDesc);
    void onFinishBuffer(AudioQueueBufferRef buffer);
};

#endif /* defined(__mypodcast__DZAudioQueuePlayer__) */
