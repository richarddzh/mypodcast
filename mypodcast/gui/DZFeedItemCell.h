//
//  DZFeedItemCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@class DZItem;
@class DZDownloadButton;

typedef enum _dz_feed_item_cell_action_ {
    DZFeedItemAction_Cancel = 0,
    DZFeedItemAction_More,
    DZFeedItemAction_MarkPlayed,
    DZFeedItemAction_MarkUnplayed,
    DZFeedItemAction_Delete,
    DZFeedItemAction_MoveToSaved,
    DZFeedItemAction_RemoveFromSaved,
} DZFeedItemCellAction;

@interface DZFeedItemCell : SWTableViewCell <UIActionSheetDelegate>

@property (nonatomic,retain) IBOutlet UIImageView * bulletImageView;
@property (nonatomic,retain) IBOutlet UILabel * titleLabel;
@property (nonatomic,retain) IBOutlet UILabel * descriptionLabel;
@property (nonatomic,retain) IBOutlet DZDownloadButton * downloadButton;
@property (nonatomic,retain) DZItem * feedItem;

+ (DZFeedItemCell *)cellWithURL:(NSURL *)url;
- (void)update;

// For utility buttons.
- (NSArray *)utilityButtons;
- (void)performUtilityButtonActionAtIndex:(NSInteger)index;

@end
