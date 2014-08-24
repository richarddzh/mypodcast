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
#import "DZItem.h"
#import <AVFoundation/AVFoundation.h>

const UInt32 kDZBufferSize = 40000;         //40K
const UInt32 kDZMaxQueueDataSize = 100000;  //100K
const UInt32 kDZMinPreloadSize = 1000000;   //1M

FOUNDATION_EXTERN NSString * const kDZPlayerIsPlaying = @"kDZPlayerIsPlaying";
FOUNDATION_EXTERN NSString * const kDZPlayerDidFinishPlaying = @"kDZPlayerDidFinishPlaying";
FOUNDATION_EXTERN NSString * const kDZPlayerWillStartPlaying = @"kDZPlayerWillStartPlaying";

static AVAudioSession * _sharedAudioSession = nil;
static DZAudioPlayer * _sharedInstance = nil;

@interface DZAudioPlayer ()
{
    uint8_t _buffer[kDZBufferSize];
    DZAudioQueuePlayer * _player;
    DZFileStream * _stream;
    DZPlayerStatus _status;
    DZItem * _feedItem;
    NSTimer * _timer;
    BOOL _shallSeekWhenStarted;
    NSTimeInterval _seekTime;
}
- (void)playStream:(NSTimer *)timer;
- (void)configureAudioSession;
- (void)prepareBeforePlay;
- (void)abortCurrentPlayback;
@end

@implementation DZAudioPlayer

+ (DZAudioPlayer *)sharedInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZAudioPlayer alloc]init];
    }
    return _sharedInstance;
}

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
        self->_feedItem = nil;
        self->_stream = nil;
        self->_shallSeekWhenStarted = NO;
    }
    return self;
}

- (void)dealloc
{
    [self abortCurrentPlayback];
}

- (void)abortCurrentPlayback
{
    if (self->_feedItem != nil && self->_player != NULL
        && (self->_player->getStatus() == DZAudioQueuePlayerStatus_Running
            || self->_player->getStatus() == DZAudioQueuePlayerStatus_Paused))
    {
        self->_feedItem.lastPlay = @(self->_player->getCurrentTime());
    }
    if (self->_timer != nil) {
        [self->_timer invalidate];
        self->_timer = nil;
    }
    if (self->_player != NULL) {
        delete self->_player;
        self->_player = NULL;
    }
    if (self->_stream != nil) {
        [self->_stream close];
        self->_stream = nil;
    }
    if (self->_feedItem != nil) {
        self->_feedItem = nil;
    }
}

- (DZItem *)feedItem
{
    return self->_feedItem;
}

- (void)setFeedItem:(DZItem *)feedItem
{
    if (feedItem == self->_feedItem) {
        return;
    }
    [self abortCurrentPlayback];
    self->_feedItem = feedItem;
    [self prepareBeforePlay];
}

- (void)prepareBeforePlay
{
    if (self->_feedItem == nil || self->_feedItem.url == nil) {
        return;
    }
    if (self->_timer != nil) {
        [self->_timer invalidate];
        self->_timer = nil;
    }
    if (self->_player != NULL) {
        delete self->_player;
        self->_player = NULL;
    }
    if (self->_stream != nil) {
        [self->_stream close];
        self->_stream = nil;
    }
    self->_stream = [DZFileStream streamWithURL:[NSURL URLWithString:self->_feedItem.url]];
    if (self->_stream == nil) {
        return;
    }
    self->_status = DZPlayerStatus_UserPause;
    self->_player = new DZAudioQueuePlayer(0);
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                    target:self
                                                  selector:@selector(playStream:)
                                                  userInfo:nil
                                                   repeats:YES];
    self->_shallSeekWhenStarted = NO;
    self->_seekTime = 0;
    if ([self->_feedItem.lastPlay doubleValue] > 0) {
        [self seekTo:[self->_feedItem.lastPlay doubleValue]];
    }
    [self fireEventWithInfo:kDZPlayerWillStartPlaying];
}

- (void)playStream:(NSTimer *)timer
{
    if (self->_player == NULL || self->_stream == nil || self->_status == DZPlayerStatus_Stop) {
        return;
    }
    
    [self fireEventWithInfo:kDZPlayerIsPlaying];
    
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
        [self->_stream close];
        self->_stream = nil;
        self->_status = DZPlayerStatus_Stop;
        [self->_timer invalidate];
        self->_timer = nil;
        self->_feedItem.read = @(YES);
        self->_feedItem.lastPlay = @(0.0f);
        [self fireEventWithInfo:kDZPlayerDidFinishPlaying];
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
            [self prepareBeforePlay];
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
        || self->_status == DZPlayerStatus_Stop
        || self->_feedItem == nil) {
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


@end
