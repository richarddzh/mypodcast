//
//  DZFeedItemCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedItemCell.h"
#import "DZItem.h"
#import "DZDownloadButton.h"
#import "UIImage+DZImagePool.h"
#import "NSString+DZFormatter.h"
#import "DZItem+DZItemOperation.h"
#import "DZItem+DZItemCellMapping.h"

@interface DZFeedItemCell ()
- (void)updateWithFeedItem:(DZItem *)item;
@end

@implementation DZFeedItemCell

- (void)setFeedItem:(DZItem *)feedItem
{
    self.actionDelegate = self;
    if (self->_feedItem != feedItem) {
        [self->_feedItem removeMappingToCell:self];
        [feedItem addMappingToCell:self];
        self->_feedItem = feedItem;
        [self setNeedsDisplay];
    }
}

- (void)updateWithFeedItem:(DZItem *)item
{
    self.titleLabel.text = item.title;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@",
                                  [NSString stringFromTime:item.duration.doubleValue]];
    DZDownloadInfo downloadInfo = item.downloadInfo;
    self.downloadButton.progress = downloadInfo.progress;
    self.downloadButton.status = downloadInfo.status;
    [self removeAllActions];
    if (item.isPlaying) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"play-bullet"];
    } else if (downloadInfo.status != DZDownloadStatus_None) {
        [self addActionWithIdentifier:DZFeedItemAction_Delete
                                 text:NSLocalizedString(@"Delete", nil)
                          destructive:YES];
    }
    if (item.isRead) {
        if (!item.isPlaying) self.bulletImageView.image = nil;
        [self addActionWithIdentifier:DZFeedItemAction_MarkUnplayed
                                 text:NSLocalizedString(@"Mark as unplayed", nil)
                          destructive:NO];
    } else {
        [self addActionWithIdentifier:DZFeedItemAction_MarkPlayed
                                 text:NSLocalizedString(@"Mark as played", nil)
                          destructive:NO];
        if (!item.isPlaying) {
            if (item.lastPlay.doubleValue > 0) {
                self.bulletImageView.image = [UIImage templateImageWithName:@"half-bullet"];
            } else {
                self.bulletImageView.image = [UIImage templateImageWithName:@"new-bullet"];
            }
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
            if (![self.feedItem isPlaying]) {
                [self.feedItem removeDownload];
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

- (void)onDownloadButtonTapped:(id)sender
{
    DZItem * feedItem = self->_feedItem;
    DZDownloadInfo info = feedItem.downloadInfo;
    switch (info.status) {
        case DZDownloadStatus_None:
        case DZDownloadStatus_Paused:
            [feedItem startDownload];
            break;
        case DZDownloadStatus_Downloading:
            [feedItem stopDownload];
            break;
        default:
            break;
    }
    [sender setNeedsDisplay];
}

@end
