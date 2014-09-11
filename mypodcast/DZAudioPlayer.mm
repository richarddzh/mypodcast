//
//  DZAudioPlayer.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZAudioPlayer.h"
#import "DZAudioQueuePlayer.h"
#import "DZFileStream.h"
#import "DZEventCenter.h"
#import "DZItem+DZItemOperation.h"
#import "DZItem+DZItemDownload.h"
#import <AVFoundation/AVFoundation.h>

const UInt32 kDZBufferSize = 40000;         //40K
const UInt32 kDZMaxQueueDataSize = 100000;  //100K
const UInt32 kDZMinPreloadSize = 1000000;   //1M

static AVAudioSession * _sharedAudioSession = nil;

@interface DZAudioPlayer ()
{
    uint8_t _buffer[kDZBufferSize];
    DZAudioQueuePlayer * _player;
    DZFileStream * _stream;
    DZPlayerStatus _status;
    DZItem * _currentItem;
    NSTimer * _timer;
    NSTimeInterval _seekTime;
    BOOL _shallSeekWhenStarted;
}
- (void)playStream:(NSTimer *)timer;
- (void)configureAudioSession;
- (void)abortCurrentPlayback;
@end

@implementation DZAudioPlayer

- (void)configureAudioSession
{
    if (_sharedAudioSession == nil) {
        _sharedAudioSession = [AVAudioSession sharedInstance];
        NSError * err = nil;
        [_sharedAudioSession setCategory:AVAudioSessionCategoryPlayback error:&err];
        if (err != nil) {
            NSLog(@"Fail to set audio session category for error: %@", err.debugDescription);
        }
        [_sharedAudioSession setActive:YES error:&err];
        if (err != nil) {
            NSLog(@"Fail to activate audio session for error: %@", err.debugDescription);
        }
    }
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        [self configureAudioSession];
        self->_player = NULL;
        self->_status = DZPlayerStatus_Stop;
        self->_stream = nil;
        self->_shallSeekWhenStarted = NO;
        self->_currentItem = nil;
    }
    return self;
}

- (void)dealloc
{
    [self abortCurrentPlayback];
}

- (void)close
{
    [self abortCurrentPlayback];
}

- (void)abortCurrentPlayback
{
    if (self->_timer != nil) {
        self->_currentItem.lastPlayTimeInterval = self.currentTime;
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_PlayerWillAbortPlaying
                                              userInfo:nil
                                            fromSource:self];
        [self->_timer invalidate];
        self->_timer = nil;
    }
    if (self->_player != NULL) {
        delete self->_player;
        self->_player = NULL;
    }
    if (self->_stream != nil) {
        [self->_currentItem closeFileStream];
        [self->_stream close];
        self->_stream = nil;
    }
}

- (void)playItem:(DZItem *)item
{
    [self abortCurrentPlayback];
    if (item == nil) {
        return;
    }
    self->_currentItem = item;
    self->_stream = [self->_currentItem openFileStream];
    if (self->_stream == nil) {
        return;
    }
    self->_status = DZPlayerStatus_PauseWait;
    self->_player = new DZAudioQueuePlayer(0);
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                    target:self
                                                  selector:@selector(playStream:)
                                                  userInfo:nil
                                                   repeats:YES];
    if (item.lastPlayTimeInterval > 0) {
        self->_shallSeekWhenStarted = YES;
        self->_seekTime = item.lastPlayTimeInterval;
    } else {
        self->_shallSeekWhenStarted = NO;
        self->_seekTime = 0;
    }
    [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_PlayerWillStartPlaying
                                          userInfo:nil
                                        fromSource:self];
}

- (void)playStream:(NSTimer *)timer
{
    if (self->_player == NULL || self->_stream == nil || self->_status == DZPlayerStatus_Stop) {
        return;
    }
    
    [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_PlayerIsPlaying
                                          userInfo:nil
                                        fromSource:self];
    
    // If a seek is made before the queue is started, seek when it is ready.
    if (self->_shallSeekWhenStarted && self->_player->getStatus() == DZAudioQueuePlayerStatus_Running) {
        self->_shallSeekWhenStarted = NO;
        [self seekTo:self->_seekTime];
    }
    
    // Feed data to the queue player anyway.
    if (self->_player->getNumByteQueued() < kDZMaxQueueDataSize) {
        if ([self->_stream hasBytesAvailable]) {
            NSInteger read = [self->_stream read:self->_buffer maxLength:kDZBufferSize];
            if (read > 0) {
                self->_player->parse(self->_buffer, (UInt32)read);
            }
        } else {
            self->_player->flush();
        }
    }
    
    // All buffered data played and no more data to read, then stop.
    if (self->_player->getNumQueueBuffer() == 0 && ![self->_stream hasBytesAvailable]) {
        self->_player->stop(false);
        // Release stream and timer, but cannot stop and delete queue because playing may continue.
        [self->_currentItem closeFileStream];
        [self->_stream close];
        self->_stream = nil;
        self->_status = DZPlayerStatus_Stop;
        [self->_timer invalidate];
        self->_timer = nil;
        self->_currentItem.lastPlayTimeInterval = 0;
        self->_currentItem.isRead = YES;
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_PlayerDidFinishPlaying
                                              userInfo:nil
                                            fromSource:self];
        return;
    }
    
    // Wait for the stream to prepare for data.
    if ([self->_stream shallWait:kDZMinPreloadSize] && self->_status == DZPlayerStatus_Play) {
        self->_status = DZPlayerStatus_PauseWait;
        self->_player->pause();
    } else if (![self->_stream shallWait:kDZMinPreloadSize] && self->_status == DZPlayerStatus_PauseWait) {
        self->_status = DZPlayerStatus_Play;
        self->_player->start();
    }
}

- (void)playPause
{
    switch (self->_status) {
        case DZPlayerStatus_Play:
            self->_player->pause();
        case DZPlayerStatus_PauseWait:
            // Audio queue has already paused to wait for streaming data.
            self->_status = DZPlayerStatus_UserPause;
            break;
        case DZPlayerStatus_Stop:
            // Start over and play.
            [self playItem:self->_currentItem];
            // Fall through to set PauseWait so that playback will begin when data are ready.
        case DZPlayerStatus_UserPause:
            self->_status = DZPlayerStatus_PauseWait;
            break;
        default:
            break;
    }
}

- (void)seekTo:(NSTimeInterval)time
{
    if (self->_player == NULL
        || self->_stream == NULL
        || self->_status == DZPlayerStatus_Stop) {
        return;
    }
    if (self->_player->getStatus() == DZAudioQueuePlayerStatus_NotReady
        || self->_player->getStatus() == DZAudioQueuePlayerStatus_ReadyToStart) {
        self->_shallSeekWhenStarted = YES;
        self->_seekTime = time;
        return;
    }
    Float64 oldTime = self->_player->getCurrentTime();
    SInt64 byteOffset = self->_player->seek(time);
    if (byteOffset >= 0) {
        if (![self->_stream seek:(NSUInteger)byteOffset]) {
            byteOffset = self->_player->seek(oldTime);
            [self->_stream seek:(NSUInteger)byteOffset];
        }
        if (self->_status == DZPlayerStatus_Play) {
            self->_status = DZPlayerStatus_PauseWait;
        }
    }
}

- (float)downloadBufferProgress
{
    if (self->_stream.numByteFileLength == 0) {
        return 0;
    }
    return (float)(self->_stream.numByteDownloaded) / self->_stream.numByteFileLength;
}

- (DZPlayerStatus)status
{
    return self->_status;
}

- (NSTimeInterval)currentTime
{
    return self->_player->getCurrentTime();
}

- (DZItem *)currentItem
{
    return self->_currentItem;
}


@end
