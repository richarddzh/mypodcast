//
//  DZFeedHeaderCell.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedHeaderCell.h"
#import "DZFeedViewController.h"

@interface DZFeedHeaderCell ()
{
    DZChannel * _channel;
}
@end

@implementation DZFeedHeaderCell

- (IBAction)onSegmentedControlValueChanged:(id)sender
{
    self.feedViewController.feedItemFilter = (DZFeedItemFilterType)(self.filterControl.selectedSegmentIndex);
}

@end
