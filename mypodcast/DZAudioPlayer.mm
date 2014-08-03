//
//  DZAudioPlayer.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZAudioPlayer.h"
#import "DZAudioQueuePlayer.h"

@interface DZAudioPlayer ()
{
    DZAudioQueuePlayer * _player;
}
- (void)playFile:(NSTimer *)timer;
@end

@implementation DZAudioPlayer

- (void)playFileAtPath:(NSString *)path
{
    if (self->_player != NULL) {
        delete self->_player;
    }
    if (self->_fstream != nil) {
        [self->_fstream close];
    }
    self->_player = new DZAudioQueuePlayer(0);
    self->_fstream = [[NSInputStream alloc]initWithFileAtPath:path];
    [self->_fstream open];
    for (int i = 0; i < kDZNumPreloadBuffer; ++i) {
        NSInteger read = [self->_fstream read:self->_buffer maxLength:kDZBufferSize];
        self->_player->parse(self->_buffer, read);
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
    NSInteger read = [self->_fstream read:self->_buffer maxLength:20009];
    self->_player->parse(self->_buffer, read);
}

@end
