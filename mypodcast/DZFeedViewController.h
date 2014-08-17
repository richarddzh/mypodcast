//
//  DZFeedViewController.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DZChannel;

typedef enum _enum_dz_feed_item_filter_ {
    DZFeedItemFilterUnplayed = 0,
    DZFeedItemFilterFeed = 1,
    DZFeedItemFilterSaved = 2
} DZFeedItemFilterType;

@interface DZFeedViewController : UITableViewController

@property (nonatomic,retain) DZChannel * feedChannel;
@property (nonatomic,assign) DZFeedItemFilterType feedItemFilter;

@end
