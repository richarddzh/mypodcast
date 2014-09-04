//
//  DZPlayList.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZPlayList.h"
#import "DZAudioPlayer.h"
#import "DZItem.h"

static DZPlayList * _sharedInstance;

@implementation DZPlayList

@synthesize feedItemList = _feedItemList;
@synthesize player = _player;
@synthesize currentItemIndex = _currentItemIndex;
@synthesize currentItem = _currentItem;
@synthesize lastItem = _lastItem;

+ (DZPlayList *)sharedInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZPlayList alloc]init];
    }
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_player = [[DZAudioPlayer alloc]init];
        self->_currentItem = nil;
        self->_lastItem = nil;
        self->_feedItemList = nil;
        self->_currentItemIndex = 0;
        [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
        [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
        [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerWillAbortPlaying];
    }
    return self;
}

- (void)dealloc
{
    [self->_player close];
    self->_player = nil;
    self->_currentItem = nil;
    self->_lastItem = nil;
    self->_feedItemList = nil;
    self->_currentItemIndex = 0;
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerWillAbortPlaying];
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    if (self->_feedItemList == nil || currentItemIndex < 0 || currentItemIndex + 1 > [self->_feedItemList count]) {
        return;
    }
    self->_lastItem = self->_currentItem;
    self->_currentItem = [self->_feedItemList objectAtIndex:currentItemIndex];
    [self->_player playURL:[NSURL URLWithString:self->_currentItem.url]];
}

- (void)handleEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source
{
    switch (eID) {
        case DZEventID_PlayerDidFinishPlaying:
            self->_currentItem.read = @(YES);
            self->_currentItem.lastPlay = @(0.0f);
            [self setCurrentItemIndex:self->_currentItemIndex + 1];
            break;
        case DZEventID_PlayerWillAbortPlaying:
            self->_lastItem.lastPlay = @(self->_player.currentTime);
            break;
        case DZEventID_PlayerWillStartPlaying:
            if ([self->_currentItem.lastPlay doubleValue] > 0) {
                [self->_player seekTo:[self->_currentItem.lastPlay doubleValue]];
            }
        default:
            break;
    }
}


@end
