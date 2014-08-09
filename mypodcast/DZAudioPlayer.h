//
//  DZAudioPlayer.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

const UInt32 kDZBufferSize = 40000;         //40K
const UInt32 kDZMaxQueueDataSize = 100000;  //100K

@interface DZAudioPlayer : NSObject

@property (nonatomic, retain) NSTimer * timer;
@property (nonatomic, assign) NSTimeInterval audioDuration;
@property (nonatomic, weak) UILabel * playTime;
@property (nonatomic, weak) UILabel * remainTime;
@property (nonatomic, weak) UIProgressView * bufferProgress;
@property (nonatomic, weak) UISlider * playSlider;

- (void)playStreamWithURL:(NSString *)url;

@end
