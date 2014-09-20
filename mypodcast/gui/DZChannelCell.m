//
//  DZChannelCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-16.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZChannelCell.h"
#import "DZCache.h"
#import "DZChannel.h"
#import "DZDatabase.h"
#import "DZPlayList.h"
#import "DZItem.h"

@implementation DZChannelCell

@synthesize channel = _channel;

- (DZChannel *)channel
{
    return self->_channel;
}

- (void)setChannel:(DZChannel *)channel
{
    if (self->_channel != channel) {
        self->_channel = channel;
        if (channel != nil) {
            self.descriptionLabel.text = channel.descriptions;
            self.titleLabel.text = channel.title;
            if (channel.image != nil) {
                [[DZCache sharedInstance]getFileReadyWithURL:[NSURL URLWithString:channel.image] shallAlwaysDownload:NO readyHandler:^(NSString * path, NSError * error) {
                    if (path != nil && error == nil) {
                        self.albumArtView.image = [UIImage imageWithContentsOfFile:path];
                    }
                }];
            }
        }
    }
}

@end
