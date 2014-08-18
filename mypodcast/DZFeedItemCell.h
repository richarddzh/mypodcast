//
//  DZFeedItemCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DZItem;

@interface DZFeedItemCell : UITableViewCell

@property (nonatomic,retain) IBOutlet UIImageView * bulletImageView;
@property (nonatomic,retain) IBOutlet UILabel * titleLabel;
@property (nonatomic,retain) IBOutlet UILabel * descriptionLabel;
@property (nonatomic,retain) DZItem * feedItem;

@end