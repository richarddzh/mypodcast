//
//  DZFeedItemCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedItemCell.h"
#import "DZItem.h"
#import "UIImage+DZImagePool.h"

@interface DZFeedItemCell ()
{
    DZItem * _feedItem;
}
@end

@implementation DZFeedItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (DZItem *)feedItem
{
    return self->_feedItem;
}

- (void)setFeedItem:(DZItem *)feedItem
{
    if (self->_feedItem != feedItem) {
        self->_feedItem = feedItem;
        if (feedItem != nil) {
            self.titleLabel.text = feedItem.title;
            self.bulletImageView.image = [UIImage templateImageWithName:@"half-bullet"];
        }
    }
}

@end
