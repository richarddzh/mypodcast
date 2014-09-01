//
//  DZFeedHeaderCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZFeedViewController.h"

@class DZChannel;

@interface DZFeedHeaderCell : UITableViewCell

@property (nonatomic,weak) IBOutlet DZFeedViewController * feedViewController;
@property (nonatomic,retain) IBOutlet UIImageView * albumArtView;
@property (nonatomic,retain) IBOutlet UILabel * titleLabel;
@property (nonatomic,retain) IBOutlet UILabel * descriptionLabel;
@property (nonatomic,retain) IBOutlet UISegmentedControl * filterControl;
@property (nonatomic,retain) DZChannel * channel;

- (IBAction)onSegmentedControlValueChanged:(id)sender;

@end
