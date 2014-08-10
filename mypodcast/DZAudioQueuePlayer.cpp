//
//  DZAudioQueuePlayer.cpp
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#include "DZAudioQueuePlayer.h"

inline OSStatus dzDebug(OSStatus returnValue, const char * errMsg)
{
    if (returnValue != noErr) {
        fprintf(stderr, "[ERROR] %s\n", errMsg);
    }
    return returnValue;
}

inline bool dzDebugError(OSStatus returnValue, const char * errMsg)
{
    return noErr != dzDebug(returnValue, errMsg);
}

inline bool dzDebugOK(OSStatus returnValue, const char * errMsg)
{
    return noErr == dzDebug(returnValue, errMsg);
}

class DZAudioQueueBufferList
{
    AudioQueueBufferRef _freeBuffers[kDZMaxNumFreeBuffers];
    UInt32 _numQueueBuffers;
    UInt32 _numFreeBuffers;
    UInt32 _numByteQueued;
    
public:
    DZAudioQueueBufferList();
    virtual ~DZAudioQueueBufferList();
    
    AudioQueueBufferRef getFreeBufferForSize(UInt32 byteSize, AudioQueueRef audioQueue);
    void recycleBuffer(AudioQueueBufferRef bufferRef);
    UInt32 getNumQueueBuffers() { return this->_numQueueBuffers; }
    UInt32 getNumFreeBuffers() { return this->_numFreeBuffers; }
    UInt32 getNumByteQueued() { return this->_numByteQueued; }
};

//
//  DZAudioQueueBufferList Implementation
//

DZAudioQueueBufferList::DZAudioQueueBufferList()
{
    this->_numFreeBuffers = 0;
    this->_numQueueBuffers = 0;
    this->_numByteQueued = 0;
    for (int i = 0; i < kDZMaxNumFreeBuffers; ++i) {
        this->_freeBuffers[i] = NULL;
    }
}

DZAudioQueueBufferList::~DZAudioQueueBufferList()
{
    // Shall NOT free any buffers when the audio queue is running.
}

AudioQueueBufferRef DZAudioQueueBufferList::getFreeBufferForSize(UInt32 byteSize, AudioQueueRef audioQueue)
{
    int idx = -1;
    for (int i = 0; i < kDZMaxNumFreeBuffers; ++i) {
        if (this->_freeBuffers[i] == NULL || this->_freeBuffers[i]->mAudioDataBytesCapacity < byteSize) {
            continue;
        }
        if (idx == -1 || this->_freeBuffers[i]->mAudioDataBytesCapacity < this->_freeBuffers[idx]->mAudioDataBytesCapacity) {
            idx = i;
        }
    }
    AudioQueueBufferRef buffer = NULL;
    if (idx != -1) {
        buffer = this->_freeBuffers[idx];
        this->_freeBuffers[idx] = NULL;
        this->_numFreeBuffers--;
    } else {
        if (dzDebugError(AudioQueueAllocateBuffer(audioQueue, byteSize * 2, &buffer),
                         "Fail to allocate new audio queue buffer.")) {
            buffer = NULL;
        }
    }
    this->_numQueueBuffers++;
    this->_numByteQueued += byteSize;
    return buffer;
}

void DZAudioQueueBufferList::recycleBuffer(AudioQueueBufferRef bufferRef) {
    if (bufferRef == NULL) {
        return;
    }
    this->_numQueueBuffers--;
    this->_numByteQueued -= bufferRef->mAudioDataByteSize;
    // fprintf(stderr, "Try recycle buffer, free %u, queue %u(%u)\n",
    //        (unsigned int)this->_numFreeBuffers,
    //        (unsigned int)this->_numQueueBuffers,
    //        (unsigned int)this->_numByteQueued);
    int idx = -1;
    for (int i = 0; i < kDZMaxNumFreeBuffers; ++i) {
        if (this->_freeBuffers[i] != NULL &&
            (idx == -1 || this->_freeBuffers[i]->mAudioDataBytesCapacity < this->_freeBuffers[idx]->mAudioDataBytesCapacity)) {
            idx = i;
        }
        if (this->_freeBuffers[i] == NULL) {
            this->_freeBuffers[i] = bufferRef;
            this->_numFreeBuffers++;
            return;
        }
    }
    dzDebugError(!noErr, "Free buffers list is full. Will drop the smallest buffer.");
    AudioQueueBufferRef bufferToDrop = bufferRef;
    if (bufferRef->mAudioDataBytesCapacity > this->_freeBuffers[idx]->mAudioDataBytesCapacity) {
        bufferToDrop = this->_freeBuffers[idx];
        this->_freeBuffers[idx] = bufferRef;
    }
    // Leaking buffer but we can not free buffer when the queue is running.
    // The buffer will be finally disposed along with the audio queue.
}

//
//  AudioFileStream and AudioQueue Callback Functions
//


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

//
//  DZAudioQueuePlayer Implementation
//

DZAudioQueuePlayer::DZAudioQueuePlayer(AudioFileTypeID typeHint)
{
    this->_parser = NULL;
    this->_queue = NULL;
    this->_magicCookie = NULL;
    this->_magicCookieSize = 0;
    if (dzDebugError(AudioFileStreamOpen(this, OnProperty, OnPackets, typeHint, &(this->_parser)),
                     "Open Audio File Stream Failed.")) {
        this->_parser = NULL;
    }
    this->_bufferList = new DZAudioQueueBufferList();
    this->_timeAmendment = 0;
}

DZAudioQueuePlayer::~DZAudioQueuePlayer()
{
    // Destructor of DZAudioQueueBufferList shall not free any
    // audio queue buffers allocated by the audio queue.
    delete this->_bufferList;
    
    // AudioQueueDispose will free its audio queue buffers.
    AudioQueueDispose(this->_queue, true);
    AudioFileStreamClose(this->_parser);
}

OSStatus DZAudioQueuePlayer::parse(const void *data, UInt32 length)
{
    return dzDebug(AudioFileStreamParseBytes(this->_parser, length, data, 0),
                   "Audio file stream parse error.");
}

void DZAudioQueuePlayer::onProperty(AudioFileStreamPropertyID pID)
{
    UInt32 propertySize = 0;
    switch (pID) {
        case kAudioFileStreamProperty_DataFormat:
            propertySize = sizeof(this->_format);
            if (dzDebugOK(AudioFileStreamGetProperty(this->_parser, pID, &(propertySize), &(this->_format)), "Fail to get audio file stream property: DataFormat.")) {
                if (this->_queue != NULL) {
                    dzDebug(!noErr, "Audio file stream duplicated data format.");
                } else {
                    if (dzDebugError(AudioQueueNewOutput(&(this->_format), QueueCallback, this, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &(this->_queue)), "Create new output audio queue failed.")) {
                        this->_queue = NULL;
                    }
                }
            }
            break;
        case kAudioFileStreamProperty_MagicCookieData:
            if (noErr == AudioFileStreamGetPropertyInfo(this->_parser, pID, &(propertySize), NULL)) {
                this->_magicCookie = malloc(propertySize);
                this->_magicCookieSize = propertySize;
                if (this->_magicCookie != NULL && dzDebugError(AudioFileStreamGetProperty(this->_parser, pID, &(propertySize), this->_magicCookie), "Fail to get audio file stream property: MagicCookieData.")) {
                    free(this->_magicCookie);
                    this->_magicCookie = NULL;
                    this->_magicCookieSize = 0;
                }
            }
            break;
        case kAudioFileStreamProperty_ReadyToProducePackets:
            if (this->_queue != NULL && this->_magicCookie != NULL) {
                dzDebug(AudioQueueSetProperty(this->_queue, kAudioQueueProperty_MagicCookie, this->_magicCookie, this->_magicCookieSize), "Fail to set audio queue property: MagicCookie.");
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
    AudioQueueBufferRef buffer = this->_bufferList->getFreeBufferForSize(numBytes, this->_queue);
    if (buffer != NULL) {
        buffer->mAudioDataByteSize = numBytes;
        memcpy(buffer->mAudioData, data, numBytes);
        dzDebug(AudioQueueEnqueueBuffer(this->_queue, buffer, packetDesc ? numPackets : 0, packetDesc),
                "Fail to enqueue audio queue buffer.") ;
    }
}

void DZAudioQueuePlayer::onFinishBuffer(AudioQueueBufferRef buffer)
{
    this->_bufferList->recycleBuffer(buffer);
}

OSStatus DZAudioQueuePlayer::flush()
{
    return dzDebug(AudioQueueFlush(this->_queue), "Fail to flush audio queue.");
}

OSStatus DZAudioQueuePlayer::prime()
{
    return dzDebug(AudioQueuePrime(this->_queue, 0, NULL), "Fail to prime audio queue.");
}

OSStatus DZAudioQueuePlayer::start()
{
    dzDebug(AudioQueueSetParameter(this->_queue, kAudioQueueParam_Volume, 1.0),
            "Fail to set audio queue property: Volumn.");
    return dzDebug(AudioQueueStart(this->_queue, NULL), "Fail to start audio queue.");
}

OSStatus DZAudioQueuePlayer::pause()
{
    return dzDebug(AudioQueuePause(this->_queue), "Fail to pause audio queue.");
}

OSStatus DZAudioQueuePlayer::stop(bool immediately)
{
    return dzDebug(AudioQueueStop(this->_queue, immediately), "Fail to stop audio queue.");
}

Float64 DZAudioQueuePlayer::getCurrentTime()
{
    AudioTimeStamp timeStamp;
    if (this->_format.mSampleRate == 0) {
        return 0;
    }
    if (dzDebugError(AudioQueueGetCurrentTime(this->_queue, NULL, &(timeStamp), NULL),
                     "Fail to get audio queue current time.")) {
        return 0;
    }
    return timeStamp.mSampleTime / this->_format.mSampleRate + this->_timeAmendment;
}

SInt64 DZAudioQueuePlayer::seek(float time)
{
    if (this->_format.mSampleRate <= 0 || this->_format.mFramesPerPacket <= 0) {
        return -1;
    }
    SInt64 dataOffset = 0;
    UInt32 propertySize = sizeof(dataOffset);
    if (dzDebugError(AudioFileStreamGetProperty(this->_parser, kAudioFileStreamProperty_DataOffset, &propertySize, &dataOffset), "Fail to get stream data offset.")) {
        return -1;
    }
    if (dzDebugError(AudioQueueReset(this->_queue), "Fail to reset audio queue.")) {
        return -1;
    }
    AudioTimeStamp timeStamp;
    if (dzDebugError(AudioQueueGetCurrentTime(this->_queue, NULL, &(timeStamp), NULL),
                     "Fail to get audio queue current time.")) {
        return -1;
    }
    SInt64 packetOffset = round(time * this->_format.mSampleRate / this->_format.mFramesPerPacket);
    SInt64 byteOffset = 0;
    UInt32 ioFlag = 0;
    if (dzDebugError(AudioFileStreamSeek(this->_parser, packetOffset, &byteOffset, &ioFlag),
                     "Fail to seek in audio file stream.")) {
        return -1;
    }
    this->_timeAmendment = time - timeStamp.mSampleTime / this->_format.mSampleRate;
    return byteOffset + dataOffset;
}

UInt32 DZAudioQueuePlayer::getNumByteQueued()
{
    return this->_bufferList->getNumByteQueued();
}

UInt32 DZAudioQueuePlayer::getNumFreeBuffer()
{
    return this->_bufferList->getNumFreeBuffers();
}

UInt32 DZAudioQueuePlayer::getNumQueueBuffer()
{
    return this->_bufferList->getNumQueueBuffers();
}

