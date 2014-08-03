//
//  DZAudioQueuePlayer.cpp
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#include "DZAudioQueuePlayer.h"

void OnProperty(void * inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 * ioFlags)
{
    DZAudioQueuePlayer * _this = (DZAudioQueuePlayer *)inClientData;
    if (_this != NULL) {
        _this->onProperty(inPropertyID);
    }
}

void OnPackets(void * inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription * inPacketDescriptions)
{
    DZAudioQueuePlayer * _this = (DZAudioQueuePlayer *)inClientData;
    if (_this != NULL) {
        _this->onPackets(inNumberBytes, inNumberPackets, inInputData, inPacketDescriptions);
    }
}

void QueueCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
    DZAudioQueuePlayer * _this = (DZAudioQueuePlayer *)inUserData;
    if (_this != NULL) {
        _this->onFinishBuffer(inBuffer);
    }
}

DZAudioQueuePlayer::DZAudioQueuePlayer(AudioFileTypeID typeHint)
{
    this->_parser = NULL;
    this->_queue = NULL;
    this->_magicCookie = NULL;
    this->_magicCookieSize = 0;
    AudioFileStreamOpen(this, OnProperty, OnPackets, typeHint, &(this->_parser));
    for (int i = 0; i < kDZMaxNumBuffers; ++i) {
        this->_freeBuffers[i] = NULL;
    }
    this->_numFreeBuffer = 0;
    this->_numQueueBuffer = 0;
}

DZAudioQueuePlayer::~DZAudioQueuePlayer()
{
    for (int i = 0; i < kDZMaxNumBuffers; ++i) {
        if (this->_freeBuffers[i] != NULL) {
            AudioQueueFreeBuffer(this->_queue, this->_freeBuffers[i]);
        }
    }
    AudioQueueDispose(this->_queue, true);
    AudioFileStreamClose(this->_parser);
}

OSStatus DZAudioQueuePlayer::parse(const void *data, UInt32 length)
{
    return AudioFileStreamParseBytes(this->_parser, length, data, 0);
}

void DZAudioQueuePlayer::onProperty(AudioFileStreamPropertyID pID)
{
    UInt32 propertySize = 0;
    switch (pID) {
        case kAudioFileStreamProperty_DataFormat:
            propertySize = sizeof(this->_format);
            if (noErr == AudioFileStreamGetProperty(this->_parser, pID, &(propertySize), &(this->_format))) {
                if (noErr != AudioQueueNewOutput(&(this->_format), QueueCallback, this, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &(this->_queue))) {
                    this->_queue = NULL;
                }
            }
            break;
        case kAudioFileStreamProperty_MagicCookieData:
            if (noErr == AudioFileStreamGetPropertyInfo(this->_parser, pID, &(propertySize), NULL)) {
                this->_magicCookie = malloc(propertySize);
                this->_magicCookieSize = propertySize;
                if (this->_magicCookie != NULL && noErr != AudioFileStreamGetProperty(this->_parser, pID, &(propertySize), this->_magicCookie)) {
                    free(this->_magicCookie);
                    this->_magicCookie = NULL;
                    this->_magicCookieSize = 0;
                }
            }
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:
            if (this->_queue != NULL && this->_magicCookie != NULL) {
                AudioQueueSetProperty(this->_queue, kAudioQueueProperty_MagicCookie, this->_magicCookie, this->_magicCookieSize);
            }
            break;
        default:
            break;
    }
}

void DZAudioQueuePlayer::onPackets(UInt32 numBytes, UInt32 numPackets, const void *data, AudioStreamPacketDescription *packetDesc)
{
    if (numBytes <= 0 || numPackets <= 0 || data == NULL) {
        return;
    }
    printf("Free Buffer: %u, Queue Buffer: %u\n", this->_numFreeBuffer, this->_numQueueBuffer);
    int idx = -1;
    AudioQueueBufferRef buffer = NULL;
    for (int i = 0; i < kDZMaxNumBuffers; ++i) {
        if (this->_freeBuffers[i] != NULL
            && this->_freeBuffers[i]->mAudioDataBytesCapacity >= numBytes) {
            idx = i;
        }
    }
    if (idx >= 0 && idx < kDZMaxNumBuffers) {
        buffer = this->_freeBuffers[idx];
        this->_freeBuffers[idx] = NULL;
        this->_numFreeBuffer--;
    }
    if (buffer == NULL) {
        if (noErr != AudioQueueAllocateBuffer(this->_queue, numBytes * 2, &(buffer))) {
            buffer = NULL;
        }
    }
    if (buffer != NULL) {
        buffer->mAudioDataByteSize = numBytes;
        memcpy(buffer->mAudioData, data, numBytes);
        AudioQueueEnqueueBuffer(this->_queue, buffer, packetDesc ? numPackets : 0, packetDesc);
        this->_numQueueBuffer++;
    }
}

void DZAudioQueuePlayer::onFinishBuffer(AudioQueueBufferRef buffer)
{
    this->_numQueueBuffer--;
    int idx = -1;
    UInt32 minSize = 0;
    for (int i = 0; i < kDZMaxNumBuffers; ++i) {
        if (this->_freeBuffers[i] == NULL) {
            idx = i;
            break;
        }
        if (idx == -1 || this->_freeBuffers[i]->mAudioDataBytesCapacity < minSize) {
            idx = i;
            minSize = this->_freeBuffers[i]->mAudioDataBytesCapacity;
        }
    }
    if (this->_freeBuffers[idx] == NULL) {
        this->_freeBuffers[idx] = buffer;
        this->_numFreeBuffer++;
    } else if (minSize < buffer->mAudioDataBytesCapacity) {
        AudioQueueFreeBuffer(this->_queue, this->_freeBuffers[idx]);
        this->_freeBuffers[idx] = buffer;
    } else {
        AudioQueueFreeBuffer(this->_queue, buffer);
    }
}

OSStatus DZAudioQueuePlayer::flush()
{
    return AudioQueueFlush(this->_queue);
}

OSStatus DZAudioQueuePlayer::prime()
{
    return AudioQueuePrime(this->_queue, 0, NULL);
}

OSStatus DZAudioQueuePlayer::start()
{
    AudioQueueSetParameter(this->_queue, kAudioQueueParam_Volume, 1.0);
    return AudioQueueStart(this->_queue, NULL);
}

OSStatus DZAudioQueuePlayer::pause()
{
    return AudioQueuePause(this->_queue);
}

OSStatus DZAudioQueuePlayer::stop()
{
    return AudioQueueStop(this->_queue, true);
}

Float64 DZAudioQueuePlayer::getCurrentTime()
{
    AudioTimeStamp timeStamp;
    AudioQueueGetCurrentTime(this->_queue, NULL, &(timeStamp), NULL);
    return timeStamp.mSampleTime / this->_format.mSampleRate;
}


