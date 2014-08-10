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
const UInt32 kDZMinPreloadSize = 1000000;   //1M

@interface DZAudioPlayer : NSObject

@property (nonatomic, assign) NSTimeInterval audioDuration;
@property (nonatomic, weak) UILabel * playTimeLabel;
@property (nonatomic, weak) UILabel * remainTimeLabel;
@property (nonatomic, weak) UIProgressView * bufferProgressView;
@property (nonatomic, weak) UISlider * playSlider;
@property (nonatomic, weak) UIButton * playButton;
@property (nonatomic, assign) BOOL isDraggingSlider;

- (void)prepareForURL:(NSString *)url;
- (void)playPause;
- (void)seekTo:(NSTimeInterval)time;

@end
