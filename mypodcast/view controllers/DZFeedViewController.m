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
#import "DZItem.h"
#import "DZDatabase.h"
#import "DZPlayList.h"
#import "DZDownloadButton.h"
#import "DZFileStream.h"
#import "DZItem+DZItemCellMapping.h"

@interface DZFeedViewController ()
{
    NSMutableArray * _tableItems;
    SWTableViewCell * _swipeRightCell;
}
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
    
    DZDatabase * database = [DZDatabase sharedInstance];
    NSString * url = @"http://www.ximalaya.com/album/236326.xml";
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
    DZFeedParser * parser = [[DZFeedParser alloc]init];
    [parser parseFeed:data atURL:url withObjectFactory:database];
    [database save];
    self.feedChannel = [database channelWithURL:url];
    [self filterFeedItems];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_FileStreamWillStartDownload];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_FileStreamWillReceiveDownloadData];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_FileStreamDidReceiveDownloadData];
    [[DZEventCenter sharedInstance]addHandler:self forEventID:DZEventID_FileStreamDidCompleteDownload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_PlayerWillStartPlaying];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_FileStreamWillStartDownload];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_FileStreamWillReceiveDownloadData];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_FileStreamDidReceiveDownloadData];
    [[DZEventCenter sharedInstance]removeHandler:self forEventID:DZEventID_FileStreamDidCompleteDownload];
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
        DZFeedItemCell * itemCell = (DZFeedItemCell *)cell;
        itemCell.feedItem = (DZItem *)[self->_tableItems objectAtIndex:indexPath.row];
        itemCell.delegate = self;
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
    return NO;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        DZPlayList * playList = [DZPlayList sharedInstance];
        NSIndexPath * selection = [self.tableView indexPathForSelectedRow];
        if (selection != nil && self->_tableItems != nil) {
            playList.feedItemList = self->_tableItems;
            playList.currentItemIndex = selection.row;
            [self.tableView deselectRowAtIndexPath:selection animated:YES];
        }
    }
}

// Have to trigger the segue manually after replacing UITableViewCell with SWTableViewCell.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.swipeRightCell != nil) {
        [self.swipeRightCell hideUtilityButtonsAnimated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"DZSeguePlayItem" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
}

# pragma mark - My methods

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
            pred = [NSPredicate predicateWithFormat:@"read == 0"];
            break;
        case DZFeedItemFilterDownload:
            pred = [NSPredicate predicateWithFormat:@"downloadProgress != 0"];
            break;
        default:
            pred = [NSPredicate predicateWithValue:YES];
            break;
    }
    NSSet * set = [self.feedChannel.items filteredSetUsingPredicate:pred];
    NSSortDescriptor * sorter = [NSSortDescriptor sortDescriptorWithKey:@"pubDate" ascending:NO];
    self->_tableItems = [[set sortedArrayUsingDescriptors:@[sorter]]mutableCopy];
}

#pragma mark - DZEventHandler

- (void)handleEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source
{
    DZPlayList * playList = [DZPlayList sharedInstance];
    switch (eID) {
        case DZEventID_PlayerWillStartPlaying:
            for (DZFeedItemCell * cell in playList.lastItem.tableViewCells) {
                [cell setNeedsDisplay];
            }
            for (DZFeedItemCell * cell in playList.currentItem.tableViewCells) {
                [cell setNeedsDisplay];
            }
            break;
        case DZEventID_FileStreamDidReceiveDownloadData:
        case DZEventID_FileStreamWillStartDownload:
        case DZEventID_FileStreamWillReceiveDownloadData:
        case DZEventID_FileStreamDidCompleteDownload:
        {
            DZFileStream * stream = source;
            for (DZFeedItemCell * cell in stream.feedItem.tableViewCells) {
                [cell setNeedsDisplay];
            }
            break;
        }
        default:
            break;
    }
}

- (IBAction)onRefresh:(id)sender
{
    [self.refreshControl endRefreshing];
}

@end
