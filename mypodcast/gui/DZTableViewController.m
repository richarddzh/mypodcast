//
//  DZTableViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZTableViewController.h"
#import "DZTableViewCell.h"

@interface DZTableViewController ()

@end

@implementation DZTableViewController

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell
{
    return YES;
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index
{
    if ([cell isKindOfClass:[DZTableViewCell class]]) {
        DZTableViewCell * dzCell = (DZTableViewCell *)cell;
        [dzCell triggerRightUtilityButtonWithIndex:index];
    }
}

- (void)swipeableTableViewCell:(SWTableViewCell *)cell scrollingToState:(SWCellState)state
{
    switch (state) {
        case kCellStateRight:
            self->_swipeRightCell = cell;
            break;
        case kCellStateCenter:
            if (cell == self->_swipeRightCell) {
                self->_swipeRightCell = nil;
            }
            break;
        default:
            break;
    }
}

- (void)showAlert:(NSString *)message
{
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:nil message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alert show];
}

@end
