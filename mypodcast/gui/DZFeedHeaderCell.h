//
//  DZFeedHeaderCell.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZChannelCell.h"

@class DZChannel;
@class DZFeedViewController;

@interface DZFeedHeaderCell : DZChannelCell

@property (nonatomic,weak) IBOutlet DZFeedViewController * feedViewController;
@property (nonatomic,retain) IBOutlet UISegmentedControl * filterControl;

- (IBAction)onSegmentedControlValueChanged:(id)sender;

@end
