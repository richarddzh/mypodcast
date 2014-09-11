//
//  DZAudioPlayer.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZItem;

typedef enum _dz_player_status_ {
    DZPlayerStatus_Stop = 0,
    DZPlayerStatus_Play,
    DZPlayerStatus_PauseWait,
    DZPlayerStatus_UserPause,
} DZPlayerStatus;

@interface DZAudioPlayer : NSObject

@property (nonatomic,readonly) DZPlayerStatus status;
@property (nonatomic,readonly) float downloadBufferProgress;
@property (nonatomic,readonly) NSTimeInterval currentTime;
@property (nonatomic,readonly) DZItem * currentItem;

- (void)playItem:(DZItem *)item;
- (void)playPause;
- (void)seekTo:(NSTimeInterval)time;
- (void)close;

@end
