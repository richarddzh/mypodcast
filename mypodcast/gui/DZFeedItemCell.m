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

static NSMutableDictionary * _mapURLToCell;

@interface DZFeedItemCell ()
{
    DZItem * _feedItem;
    DZFeedItemCellAction _utilityButtonActions[2];
    DZFeedItemCellAction _sheetActions[3];
}
- (void)updateWithFeedItem:(DZItem *)item;
+ (NSMutableDictionary *)mapURLToCell;
- (UIActionSheet *)actionSheet;
- (void)performAction:(DZFeedItemCellAction)action;
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
        if (self->_feedItem.url != nil && self == [map objectForKey:self->_feedItem.url]) {
            [map removeObjectForKey:self->_feedItem.url];
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
    DZPlayList * playList = [DZPlayList sharedInstance];
    if (playList.currentItem == item) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"play-bullet"];
    } else if (item.read.boolValue == YES) {
        self.bulletImageView.image = nil;
    } else if (item.lastPlay.doubleValue > 0) {
        self.bulletImageView.image = [UIImage templateImageWithName:@"half-bullet"];
    } else {
        self.bulletImageView.image = [UIImage templateImageWithName:@"new-bullet"];
    }
    self.downloadButton.feedItem = item;
    [self.downloadButton update];
}

- (void)update
{
    [self updateWithFeedItem:self->_feedItem];
}

- (NSArray *)utilityButtons
{
    NSMutableArray * buttons = [NSMutableArray array];
    
    [buttons sw_addUtilityButtonWithColor:[UIColor lightGrayColor]
                                    title:NSLocalizedString(@"More", nil)];
    self->_utilityButtonActions[0] = DZFeedItemAction_More;
    
    DZDownloadInfo downloadInfo = [DZDownloadList downloadInfoWithItem:self.feedItem];
    if (downloadInfo.status != DZDownloadStatus_None) {
        [buttons sw_addUtilityButtonWithColor:[UIColor redColor]
                                        title:NSLocalizedString(@"Delete", nil)];
        self->_utilityButtonActions[1] = DZFeedItemAction_Delete;
    } else if ([self.feedItem.read boolValue]) {
        [buttons sw_addUtilityButtonWithColor:[self.contentView tintColor]
                                        title:NSLocalizedString(@"Mark as unplayed", nil)];
        self->_utilityButtonActions[1] = DZFeedItemAction_MarkUnplayed;
    } else {
        [buttons sw_addUtilityButtonWithColor:[self.contentView tintColor]
                                        title:NSLocalizedString(@"Mark as played", nil)];
        self->_utilityButtonActions[1] = DZFeedItemAction_MarkPlayed;
    }
    return buttons;
}

- (UIActionSheet *)actionSheet
{
    NSString * markPlayed = nil;
    NSString * moveSaved = nil;
    if ([self.feedItem.read boolValue]) {
        markPlayed = NSLocalizedString(@"Mark as unplayed", nil);
        self->_sheetActions[0] = DZFeedItemAction_MarkUnplayed;
    } else {
        markPlayed = NSLocalizedString(@"Mark as played", nil);
        self->_sheetActions[0] = DZFeedItemAction_MarkPlayed;
    }
    if ([self.feedItem.stored boolValue]) {
        moveSaved = NSLocalizedString(@"Remove from saved", nil);
        self->_sheetActions[1] = DZFeedItemAction_RemoveFromSaved;
    } else {
        moveSaved = NSLocalizedString(@"Move to saved", nil);
        self->_sheetActions[1] = DZFeedItemAction_MoveToSaved;
    }
    self->_sheetActions[2] = DZFeedItemAction_Cancel;
    UIActionSheet * sheet = [[UIActionSheet alloc]initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:markPlayed, moveSaved, nil];
    return sheet;
}

- (void)performUtilityButtonActionAtIndex:(NSInteger)index
{
    [self performAction:self->_utilityButtonActions[index]];
}

- (void)performAction:(DZFeedItemCellAction)action
{
    switch (action) {
        case DZFeedItemAction_More:
            [[self actionSheet]showInView:self];
            break;
        case DZFeedItemAction_Cancel:
        default:
            break;
    }
}

#pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self performAction:self->_sheetActions[buttonIndex]];
}

@end
