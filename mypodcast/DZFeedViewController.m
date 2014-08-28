//
//  DZFeedViewController.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFeedViewController.h"
#import "DZFeedHeaderCell.h"
#import "DZFeedItemCell.h"
#import "DZChannel.h"
#import "DZDatabase.h"
#import "DZAudioPlayer.h"

@interface DZFeedViewController ()
{
    NSMutableArray * _tableItems;
}
- (void)filterFeedItems;
@end

@implementation DZFeedViewController

@synthesize feedChannel, feedItemFilter;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //DZFeedParser * parser = [[DZFeedParser alloc]init];
    DZDatabase * database = [DZDatabase sharedInstance];
    NSString * url = @"http://www.ximalaya.com/album/236326.xml";
    //NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    //[parser parseFeed:data atURL:url withObjectFactory:database];
    //[database save];
    self.feedChannel = [database channelWithURL:url];
    [self filterFeedItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return [self->_tableItems count];
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * reuseIdentifier = indexPath.section == 0 ? @"DZFeedHeader" : @"DZFeedItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        DZFeedHeaderCell * header = (DZFeedHeaderCell *)cell;
        header.channel = self.feedChannel;
    } else {
        DZFeedItemCell * item = (DZFeedItemCell *)cell;
        item.feedItem = (DZItem *)[self->_tableItems objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 ? 129 : 62;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier compare:@"DZSeguePlayItem"] == NSOrderedSame) {
        DZAudioPlayer * player = [DZAudioPlayer sharedInstance];
        NSIndexPath * selection = [self.tableView indexPathForSelectedRow];
        if (selection != nil && self->_tableItems != nil) {
            DZItem * feedItem = [self->_tableItems objectAtIndex:selection.row];
            if (player.feedItem != feedItem) {
                player.feedItem = [self->_tableItems objectAtIndex:selection.row];
                [player playPause];
            }
        }
    }
}

- (void)filterFeedItems
{
    if (self.feedChannel == nil) {
        self->_tableItems = nil;
        return;
    }
    NSPredicate * pred = nil;
    switch (self.feedItemFilter) {
        case DZFeedItemFilterFeed:
            pred = [NSPredicate predicateWithFormat:@"feed != 0"];
            break;
        case DZFeedItemFilterSaved:
            pred = [NSPredicate predicateWithFormat:@"stored != 0"];
            break;
        case DZFeedItemFilterUnplayed:
            pred = [NSPredicate predicateWithFormat:@"read < duration"];
            break;
        default:
            pred = [NSPredicate predicateWithValue:YES];
            break;
    }
    NSSet * set = [self.feedChannel.items filteredSetUsingPredicate:pred];
    NSSortDescriptor * sorter = [NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:NO];
    self->_tableItems = [[set sortedArrayUsingDescriptors:@[sorter]]mutableCopy];
}

@end
