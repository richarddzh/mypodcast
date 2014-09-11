//
//  DZFeedItemCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedItemCell.h"
#import "DZItem.h"
#import "DZPlayList.h"
#import "DZDownloadButton.h"
#import "UIImage+DZImagePool.h"
#import "NSString+DZFormatter.h"
#import "DZItem+DZItemOperation.h"

static NSMutableDictionary * _mapURLToCell;

@interface DZFeedItemCell ()
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

- (void)setFeedItem:(DZItem *)feedItem
{
    self.actionDelegate = self;
    NSMutableDictionary * map = [DZFeedItemCell mapURLToCell];
    if (self->_feedItem != feedItem) {
        if (self->_feedItem.url != nil && self == [map objectForKey:self->_feedItem.url]) {
            [map removeObjectForKey:self->_feedItem.url];
        }
        if (feedItem != nil && feedItem.url != nil) {
            [map setObject:self forKey:[NSURL URLWithString:feedItem.url]];
        }
        self->_feedItem = feedItem;
        [self setNeedsDisplay];
    }
}

- (void)updateWithFeedItem:(DZItem *)item
{
    self.titleLabel.text = item.title;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@",
                                  [NSString stringFromTime:item.duration.doubleValue]];
    DZDownloadInfo downloadInfo = [DZDownloadList downloadInfoWithItem:item];
    self.downloadButton.progress = downloadInfo.progress;
    self.downloadButton.status = downloadInfo.status;
    [self removeAllActions];
    DZPlayList * playList = [DZPlayList sharedInstance];
    if (playList.currentItem == item) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"play-bullet"];
    } else if (downloadInfo.status != DZDownloadStatus_None) {
        [self addActionWithIdentifier:DZFeedItemAction_Delete
                                 text:NSLocalizedString(@"Delete", nil)
                          destructive:YES];
    }
    if (item.isRead) {
        self.bulletImageView.image = nil;
        [self addActionWithIdentifier:DZFeedItemAction_MarkUnplayed
                                 text:NSLocalizedString(@"Mark as unplayed", nil)
                          destructive:NO];
    } else {
        [self addActionWithIdentifier:DZFeedItemAction_MarkPlayed
                                 text:NSLocalizedString(@"Mark as played", nil)
                          destructive:NO];
        if (item.lastPlay.doubleValue > 0) {
            self.bulletImageView.image = [UIImage templateImageWithName:@"half-bullet"];
        } else {
            self.bulletImageView.image = [UIImage templateImageWithName:@"new-bullet"];
        }
    }
    if (item.isStored) {
        [self addActionWithIdentifier:DZFeedItemAction_RemoveFromSaved
                                 text:NSLocalizedString(@"Remove from saved", nil)
                          destructive:NO];
    } else {
        [self addActionWithIdentifier:DZFeedItemAction_MoveToSaved
                                 text:NSLocalizedString(@"Move to saved", nil)
                          destructive:NO];
    }
}

- (void)setNeedsDisplay
{
    if (self.feedItem != nil) {
        [self updateWithFeedItem:self.feedItem];
    }
    [super setNeedsDisplay];
}

- (void)cell:(DZTableViewCell *)cell didTriggerAction:(NSInteger)actionID
{
    switch (actionID) {
        case DZFeedItemAction_Delete:
            if (self.feedItem != [[DZPlayList sharedInstance]currentItem]) {
                [DZDownloadList removeDownloadWithItem:self.feedItem];
            }
            break;
        case DZFeedItemAction_MarkPlayed:
            self.feedItem.isRead = YES;
            break;
        case DZFeedItemAction_MarkUnplayed:
            self.feedItem.isRead = NO;
            break;
        case DZFeedItemAction_MoveToSaved:
            self.feedItem.isStored = YES;
            break;
        case DZFeedItemAction_RemoveFromSaved:
            self.feedItem.isStored = NO;
            break;
        case DZFeedItemAction_More:
        case DZFeedItemAction_Cancel:
        default:
            break;
    }
    [cell setNeedsDisplay];
}

@end
