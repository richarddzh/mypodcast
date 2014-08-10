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
#import <AVFoundation/AVFoundation.h>

static AVAudioSession * _sharedAudioSession = nil;

typedef enum _dz_player_status_ {
    DZPlayerStatusStop = 0,
    DZPlayerStatusPlay,
    DZPlayerStatusPauseWait,
    DZPlayerStatusUserPause,
} DZPlayerStatus;

@interface DZAudioPlayer ()
{
    uint8_t _buffer[kDZBufferSize];
    DZAudioQueuePlayer * _player;
    DZFileStream * _stream;
    DZPlayerStatus _status;
    NSString * _url;
    NSTimer * _timer;
}
- (void)playStream:(NSTimer *)timer;
- (void)configureAudioSession;
- (void)updatePlayProgress;
- (void)setPlayButtonImageWithName:(NSString *)name;
@end

@implementation DZAudioPlayer

@synthesize playSlider, bufferProgressView, playTimeLabel, remainTimeLabel, playButton, audioDuration;

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
        self->_status = DZPlayerStatusStop;
        self->_url = nil;
        self->_stream = nil;
        self.isDraggingSlider = NO;
    }
    return self;
}

- (void)prepareForURL:(NSString *)url
{
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
    self->_url = url;
    self->_stream = [DZFileStream streamWithURL:[NSURL URLWithString:url]];
    if (url == nil || self->_stream == nil) {
        return;
    }
    self->_status = DZPlayerStatusUserPause;
    [self setPlayButtonImageWithName:@"play"];
    self->_player = new DZAudioQueuePlayer(0);
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                    target:self
                                                  selector:@selector(playStream:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)playStream:(NSTimer *)timer
{
    if (self->_player == NULL || self->_stream == nil || self->_status == DZPlayerStatusStop) {
        return;
    }
    [self updatePlayProgress];
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
    if (self->_player->getNumQueueBuffer() == 0 && ![self->_stream hasBytesAvailable]) {
        self->_player->stop(false);
        [self->_stream close];
        self->_stream = nil;
        self->_status = DZPlayerStatusStop;
        [self->_timer invalidate];
        self->_timer = nil;
        [self setPlayButtonImageWithName:@"play"];
        return;
    }
    if ([self->_stream shallWait:kDZMinPreloadSize]
        && self->_status == DZPlayerStatusPlay) {
        self->_status = DZPlayerStatusPauseWait;
        self->_player->pause();
    } else if (![self->_stream shallWait:kDZMinPreloadSize]
               && self->_status == DZPlayerStatusPauseWait) {
        self->_status = DZPlayerStatusPlay;
        self->_player->start();
    }
}

- (void)playPause
{
    switch (self->_status) {
        case DZPlayerStatusPlay:
            self->_player->pause();
        case DZPlayerStatusPauseWait:
            self->_status = DZPlayerStatusUserPause;
            break;
        case DZPlayerStatusStop:
            if (self->_url != nil) {
                [self prepareForURL:self->_url];
            }
        case DZPlayerStatusUserPause:
            self->_status = DZPlayerStatusPauseWait;
            break;
        default:
            break;
    }
}

- (void)updatePlayProgress
{
    unsigned int playerTime = (unsigned int)round(self->_player->getCurrentTime());
    unsigned int playerRemainTime = self->audioDuration > playerTime ? (unsigned int)round(self->audioDuration - playerTime) : 0;
    if (self.isDraggingSlider == NO) {
        self.playSlider.value = playerTime / self.audioDuration;
    }
    self.playTimeLabel.text = [NSString stringWithFormat:@"%02u:%02u", playerTime / 60, playerTime % 60];
    self.remainTimeLabel.text = [NSString stringWithFormat:@"-%02u:%02u", playerRemainTime / 60, playerRemainTime % 60];
    self.bufferProgressView.progress = (float)self->_stream.numByteDownloaded / self->_stream.numByteFileLength;
    if (self->_status == DZPlayerStatusStop || self->_status == DZPlayerStatusUserPause) {
        [self setPlayButtonImageWithName:@"play"];
    } else {
        [self setPlayButtonImageWithName:@"pause"];
    }
}

- (void)setPlayButtonImageWithName:(NSString *)name
{
    [self.playButton setImage:[[UIImage imageNamed:[name stringByAppendingString:@"-button"]]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateNormal];
    [self.playButton setImage:[[UIImage imageNamed:[name stringByAppendingString:@"-button-highlight"]]
                               imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                     forState:UIControlStateHighlighted];
}

- (void)seekTo:(NSTimeInterval)time
{
    if (self->_player == NULL || self->_stream == NULL || self->_status == DZPlayerStatusStop) {
        return;
    }
    Float64 oldTime = self->_player->getCurrentTime();
    SInt64 byteOffset = self->_player->seek(time);
    if (byteOffset >= 0) {
        if (![self->_stream seek:(NSUInteger)byteOffset]) {
            byteOffset = self->_player->seek(oldTime);
            [self->_stream seek:(NSUInteger)byteOffset];
        }
        if (self->_status == DZPlayerStatusPlay) {
            self->_status = DZPlayerStatusPauseWait;
        }
    }
}


@end
