//
//  DZAudioPlayer.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DZEventSource.h"

FOUNDATION_EXTERN NSString * const kDZPlayerIsPlaying;
FOUNDATION_EXTERN NSString * const kDZPlayerDidFinishPlaying;
FOUNDATION_EXTERN NSString * const kDZPlayerWillStartPlaying;

typedef enum _dz_player_status_ {
    DZPlayerStatus_Stop = 0,
    DZPlayerStatus_Play,
    DZPlayerStatus_PauseWait,
    DZPlayerStatus_UserPause,
} DZPlayerStatus;

@class DZItem;
@class DZAudioPlayer;
@class DZFileStream;

@interface DZAudioPlayer : DZEventSource

@property (nonatomic,retain) DZItem * feedItem;

+ (DZAudioPlayer *)sharedInstance;

- (void)playPause;
- (void)seekTo:(NSTimeInterval)time;
- (DZPlayerStatus)status;
- (float)downloadBufferProgress;

@end
