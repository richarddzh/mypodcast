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

@interface DZAudioPlayer ()
{
    uint8_t _buffer[kDZBufferSize];
    DZAudioQueuePlayer * _player;
    DZFileStream * _stream;
    BOOL _isPlaying;
}
- (void)playStream:(NSTimer *)timer;
- (void)configureAudioSession;
- (void)updatePlayProgress;
@end

@implementation DZAudioPlayer

@synthesize playSlider, bufferProgress, playTime, remainTime, timer, audioDuration;

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
    }
    return self;
}

- (void)playStreamWithURL:(NSString *)url
{
    if (self->_player != NULL) {
        delete self->_player;
    }
    if (self->_stream != nil) {
        [self->_stream close];
    }
    self.bufferProgress.progress = 0;
    self->_player = new DZAudioQueuePlayer(0);
    self->_stream = [DZFileStream streamWithURL:[NSURL URLWithString:url]];
    self->_isPlaying = false;
    [self updatePlayProgress];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(playStream:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)playStream:(NSTimer *)timer
{
    [self updatePlayProgress];
    if (self->_player->getNumByteQueued() > kDZMaxQueueDataSize) {
        if (self->_isPlaying == false) {
            self->_player->prime();
            self->_player->start();
            self->_isPlaying = true;
        }
        return;
    }
    if ([self->_stream hasBytesAvailable] == NO) {
        self->_player->flush();
        self->_player->stop(false);
        self->_isPlaying = false;
        [self.timer invalidate];
    }
    NSInteger read = [self->_stream read:self->_buffer maxLength:kDZBufferSize];
    if (read > 0) {
        self->_player->parse(self->_buffer, (UInt32)read);
    }
}

- (void)updatePlayProgress
{
    unsigned int playerTime = (unsigned int)round(self->_player->getCurrentTime());
    unsigned int playerRemainTime = self->audioDuration > playerTime ? (unsigned int)round(self->audioDuration - playerTime) : 0;
    self.playSlider.value = playerTime / self.audioDuration;
    self.playTime.text = [NSString stringWithFormat:@"%02u:%02u",
                          playerTime / 60, playerTime % 60];
    self.remainTime.text = [NSString stringWithFormat:@"-%02u:%02u",
                            playerRemainTime / 60, playerRemainTime % 60];
    self.bufferProgress.progress = (float)self->_stream.numByteDownloaded / self->_stream.numByteFileLength;
}

@end
