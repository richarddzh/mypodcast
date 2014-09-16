//
//  DZChannelCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-16.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZTableViewCell.h"

typedef enum _dz_channel_action_ {
    DZChannelAction_Remove,
} DZChannelAction;

@class DZChannel;

@interface DZChannelCell : DZTableViewCell

@property (nonatomic,retain) IBOutlet UIImageView * albumArtView;
@property (nonatomic,retain) IBOutlet UILabel * titleLabel;
@property (nonatomic,retain) IBOutlet UILabel * descriptionLabel;
@property (nonatomic,retain) DZChannel * channel;

@end
