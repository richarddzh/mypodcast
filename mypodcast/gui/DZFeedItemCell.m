//
//  DZFeedItemCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedItemCell.h"
#import "DZItem.h"
#import "DZAudioPlayer.h"
#import "UIImage+DZImagePool.h"
#import "NSString+DZFormatter.h"

static NSMutableDictionary * _mapURLToCell;

@interface DZFeedItemCell ()
{
    DZItem * _feedItem;
}
- (void)updateWithFeedItem:(DZItem *)item;
+ (NSMutableDictionary *)mapURLToCell;
@end

@implementation DZFeedItemCell

+ (NSMutableDictionary *)mapURLToCell;
{
    if (_mapURLToCell == nil) {
        _mapURLToCell = [NSMutableDictionary dictionary];
    }
    return _mapURLToCell;
}

+ (DZFeedItemCell *)cellWithURL:(NSURL *)url
{
    return [[DZFeedItemCell mapURLToCell]objectForKey:url];
}

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
    NSMutableDictionary * map = [DZFeedItemCell mapURLToCell];
    if (self->_feedItem != feedItem) {
        if (self->_feedItem.url != nil) {
            [map removeObjectForKey:[NSURL URLWithString:self->_feedItem.url]];
        }
        if (feedItem != nil && feedItem.url != nil) {
            [map setObject:self forKey:[NSURL URLWithString:feedItem.url]];
        }
        [self updateWithFeedItem:feedItem];
    }
}

- (void)updateWithFeedItem:(DZItem *)item
{
    self->_feedItem = item;
    self.titleLabel.text = item.title;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@",
                                  [NSString stringFromTime:item.duration.doubleValue]];
    DZAudioPlayer * player = [DZAudioPlayer sharedInstance];
    if (player.feedItem == item) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"play-bullet"];
    } else if (item.read.boolValue == YES) {
        self.bulletImageView.image = nil;
    } else if (item.lastPlay.doubleValue > 0) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"half-bullet"];
    } else {
        self.bulletImageView.image = [UIImage templateImageWithName:@"new-bullet"];
    }
}

- (void)update{
    [self updateWithFeedItem:self->_feedItem];
}

@end
