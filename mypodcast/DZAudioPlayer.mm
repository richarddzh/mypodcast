//
//  DZAudioPlayer.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZAudioPlayer.h"
#import "DZAudioQueuePlayer.h"
#import "DZURLSessionForAudioStream.h"
#import <AVFoundation/AVFoundation.h>

static AVAudioSession * _sharedAudioSession = nil;

@interface DZAudioPlayer ()
{
    DZAudioQueuePlayer * _player;
    DZURLSessionForAudioStream * _session;
}
- (void)playFile:(NSTimer *)timer;
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
        self->_session = [[DZURLSessionForAudioStream alloc]initWithBufferSize:kDZStreamSize
                                                                operationQueue:[NSOperationQueue currentQueue]];
    }
    return self;
}

- (void)playFileAtPath:(NSString *)path
{
    if (self->_player != NULL) {
        delete self->_player;
    }
    if (self->_fstream != nil) {
        [self->_fstream close];
    }
    self.bufferProgress.progress = 1;
    self->_player = new DZAudioQueuePlayer(0);
    self->_fstream = [[NSInputStream alloc]initWithFileAtPath:path];
    [self->_fstream open];
    [self updatePlayProgress];
    for (int i = 0; i < kDZNumPreloadBuffer; ++i) {
        NSInteger read = [self->_fstream read:self->_buffer maxLength:kDZBufferSize];
        if (read > 0) {
            self->_player->parse(self->_buffer, (UInt32)read);
        }
    }
    self->_player->prime();
    self->_player->start();
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                  target:self
                                                selector:@selector(playFile:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)playFile:(NSTimer *)timer
{
    [self updatePlayProgress];
    self.playSlider.value = self->_player->getCurrentTime() / self.audioDuration;
    if (self->_player->isBufferOverloaded()) {
        return;
    }
    if ([self->_fstream hasBytesAvailable] == NO) {
        self->_player->flush();
        self->_player->stop(false);
        [self.timer invalidate];
    }
    NSInteger read = [self->_fstream read:self->_buffer maxLength:kDZBufferSize];
    if (read > 0) {
        self->_player->parse(self->_buffer, (UInt32)read);
    }
}

- (void)playStreamWithURL:(NSString *)url
{
    if (self->_player != NULL) {
        delete self->_player;
    }
    if (self->_fstream != nil) {
        [self->_fstream close];
    }
    self.bufferProgress.progress = 0;
    self->_player = new DZAudioQueuePlayer(0);
    self->_session.readySize = kDZBufferSize * kDZNumPreloadBuffer;
    self->_session.bufferProgressView = self.bufferProgress;
    [self updatePlayProgress];
    [self->_session prepareForURL:[NSURL URLWithString:url] handler:^{
        for (int i = 0; i < kDZNumPreloadBuffer; ++i) {
            NSInteger read = [self->_session read:self->_buffer maxLength:kDZBufferSize];
            if (read > 0) {
                self->_player->parse(self->_buffer, (UInt32)read);
            }
        }
        self->_player->prime();
        self->_player->start();
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                      target:self
                                                    selector:@selector(playStream:)
                                                    userInfo:nil
                                                     repeats:YES];
    }];
}

- (void)playStream:(NSTimer *)timer
{
    [self updatePlayProgress];
    if (self->_player->isBufferOverloaded()) {
        return;
    }
    if ([self->_session hasBytesAvailable] == NO) {
        self->_player->flush();
        self->_player->stop(false);
        [self.timer invalidate];
    }
    NSInteger read = [self->_session read:self->_buffer maxLength:kDZBufferSize];
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
}

@end
