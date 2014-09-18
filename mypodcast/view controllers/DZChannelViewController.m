//
//  DZChannelViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-16.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZChannelViewController.h"
#import "DZFeedViewController.h"
#import "DZChannelCell.h"
#import "DZPlayList.h"
#import "DZDatabase.h"
#import "DZChannel.h"
#import "DZItem.h"
#import "DZChannel+DZChannelOperation.h"

@interface DZChannelViewController ()
{
    NSMutableArray * _channels;
}
@end

@implementation DZChannelViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self->_channels = [[[DZDatabase sharedInstance]fetchAll:@"DZChannel"]mutableCopy];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"DZSegueChannel"]) {
        DZFeedViewController * vc = [segue destinationViewController];
        NSIndexPath * selection = [self.tableView indexPathForSelectedRow];
        if (selection != nil && self->_channels != nil) {
            vc.feedChannel = [self->_channels objectAtIndex:selection.row];
            [vc beginRefresh];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"DZSegueChannel"
                              sender:[tableView cellForRowAtIndexPath:indexPath]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)cell:(DZTableViewCell *)cell didTriggerAction:(NSInteger)actionID
{
    DZChannelCell * channelCell = (DZChannelCell *)cell;
    switch (actionID) {
        case DZChannelAction_Remove:
            if ([[[DZPlayList sharedInstance]currentItem]channel] != channelCell.channel) {
                [channelCell.channel deleteSelf];
                [self->_channels removeObject:channelCell.channel];
                NSIndexPath * indexPath = [self.tableView indexPathForCell:cell];
                [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            break;
        default:
            break;
    }
}

#pragma mark - UI table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self->_channels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DZChannelCell * cell = (DZChannelCell *)[tableView dequeueReusableCellWithIdentifier:@"DZChannel"];
    cell.delegate = self;
    cell.channel = [self->_channels objectAtIndex:indexPath.row];
    cell.actionDelegate = self;
    [cell removeAllActions];
    [cell addActionWithIdentifier:DZChannelAction_Remove
                             text:NSLocalizedString(@"Delete", nil)
                      destructive:YES];
    return cell;
}

@end
