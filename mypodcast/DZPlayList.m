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
        self->_lastItem = nil;
        self->_feedItemList = nil;
        self->_currentItemIndex = 0;
        [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
    }
    return self;
}

- (void)dealloc
{
    [self->_player close];
    self->_player = nil;
    self->_lastItem = nil;
    self->_feedItemList = nil;
    self->_currentItemIndex = 0;
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerDidFinishPlaying];
}

- (void)setCurrentItemIndex:(NSInteger)currentItemIndex
{
    if (self->_feedItemList == nil || currentItemIndex < 0 || currentItemIndex + 1 > [self->_feedItemList count]) {
        return;
    }
    if ([self->_feedItemList objectAtIndex:currentItemIndex] == self->_player.currentItem) {
        return;
    }
    self->_lastItem = self->_player.currentItem;
    self->_currentItemIndex = currentItemIndex;
    [self->_player playItem:[self->_feedItemList objectAtIndex:currentItemIndex]];
}

- (DZItem *)currentItem
{
    return self->_player.currentItem;
}

- (void)handleEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source
{
    switch (eID) {
        case DZEventID_PlayerDidFinishPlaying:
            if (source == self->_player) {
                [self setCurrentItemIndex:self->_currentItemIndex + 1];
            }
            break;
        default:
            break;
    }
}

@end
