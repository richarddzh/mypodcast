//
//  DZFeedHeaderCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedHeaderCell.h"
#import "DZChannel.h"
#import "DZCache.h"

@interface DZFeedHeaderCell ()
{
    DZChannel * _channel;
}
@end

@implementation DZFeedHeaderCell

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

- (DZChannel *)channel
{
    return self->_channel;
}

- (void)setChannel:(DZChannel *)channel
{
    DZCache * cache = [DZCache sharedInstance];
    if (self->_channel != channel) {
        self->_channel = channel;
    }
    if (channel != nil) {
        self.descriptionLabel.text = channel.descriptions;
        self.titleLabel.text = channel.title;
        if (channel.image != nil) {
            [cache getDataWithURL:[NSURL URLWithString:channel.image] shallAlwaysDownload:YES dataHandler:^(NSData * data, NSError * error) {
                if (data != nil && error == nil) {
                    self.albumArtView.image = [UIImage imageWithData:data];
                }
            }];
        }
    }
}

- (IBAction)onSegmentedControlValueChanged:(id)sender
{
    self.feedViewController.feedItemFilter = (DZFeedItemFilterType)(self.filterControl.selectedSegmentIndex);
}

@end
