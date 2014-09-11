//
//  DZTableViewController.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "SWTableViewCell.h"

@interface DZTableViewController : UITableViewController <SWTableViewCellDelegate>

@property (nonatomic,weak,readonly) SWTableViewCell * swipeRightCell;

@end
