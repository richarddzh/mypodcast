//
//  DZPlayList.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DZEventCenter.h"

@class DZItem;
@class DZAudioPlayer;

@interface DZPlayList : NSObject <DZEventHandler>

+ (DZPlayList *)sharedInstance;

@property (nonatomic,copy) NSArray * feedItemList;
@property (nonatomic,assign) NSInteger currentItemIndex;
@property (nonatomic,readonly) DZAudioPlayer * player;
@property (nonatomic,readonly) DZItem * currentItem;
@property (nonatomic,readonly) DZItem * lastItem;

@end
