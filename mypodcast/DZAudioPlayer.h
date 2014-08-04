//
//  DZAudioPlayer.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

const UInt32 kDZBufferSize = 40000;
const UInt32 kDZNumPreloadBuffer = 4;

@interface DZAudioPlayer : NSObject
{
    NSInputStream * _fstream;
    uint8_t _buffer[kDZBufferSize];
}

@property (nonatomic, retain) NSTimer * timer;

- (void)playFileAtPath:(NSString *)path;

@end
