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
#import "DZChannel+DZChannelOperation.h"

@interface DZFeedViewController ()
{
    NSMutableArray * _tableItems;
    NSMutableArray * _searchResultIndexes;
    NSString * _searchString;
    SWTableViewCell * _swipeRightCell;
}
- (void)filterFeedItems;
- (void)scrollToTop;
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

- (void)setFeedChannel:(DZChannel *)aFeedChannel
{
    if (self->feedChannel != aFeedChannel) {
        self->feedChannel = aFeedChannel;
        [self filterFeedItems];
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

- (void)setFeedItemFilter:(DZFeedItemFilterType)filter
{
    if (self->feedItemFilter != filter) {
        self->feedItemFilter = filter;
        [self filterFeedItems];
        [self.tableView reloadData];
        [self scrollToTop];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self->_searchResultIndexes count];
    }
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        static NSString * cellId = @"DZSearchResult";
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault
                                         reuseIdentifier:cellId];
        }
        NSInteger rowId = [[self->_searchResultIndexes objectAtIndex:indexPath.row]integerValue];
        DZItem * item = [self->_tableItems objectAtIndex:rowId];
        cell.textLabel.text = item.title;
        return cell;
    }
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [self.searchDisplayController setActive:NO animated:YES];
        NSInteger rowId = [[self->_searchResultIndexes objectAtIndex:indexPath.row]integerValue];
        NSIndexPath * path = [NSIndexPath indexPathForRow:rowId inSection:1];
        [self.tableView scrollToRowAtIndexPath:path
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
        return;
    }
    if (self.swipeRightCell != nil) {
        [self.swipeRightCell hideUtilityButtonsAnimated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    if (indexPath.section == 0) {
        [self scrollToTop];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    self->_searchResultIndexes = nil;
    self->_searchString = nil;
}

- (IBAction)onRefresh:(id)sender
{
    [self.feedChannel updateWithCompletionHandler:^(NSError * error) {
        if (error != nil) {
            NSLog(@"update channel failed with error: %@, %@", error, error.debugDescription);
            [self showAlert:NSLocalizedString(@"Refresh failed, try again later.", nil)];
        } else {
            [self filterFeedItems];
            [self.tableView reloadData];
            [self scrollToTop];
        }
        if (sender != nil) {
            [self.refreshControl endRefreshing];
        }
    }];
}

- (void)beginRefresh
{
    [self onRefresh:nil];
}

- (void)scrollToTop
{
    NSIndexPath * path = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionTop animated:YES];
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

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    if (searchString == nil || [searchString isEqualToString:@""]) {
        return NO;
    }
    searchString = [[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]lowercaseString];
    if ([searchString isEqualToString:self->_searchString]) {
        return NO;
    }
    self->_searchString = searchString;
    self->_searchResultIndexes = [NSMutableArray array];
    for (int i = 0; i < self->_tableItems.count; ++i) {
        DZItem * item = [self->_tableItems objectAtIndex:i];
        if ([item.title rangeOfString:searchString].location != NSNotFound) {
            [self->_searchResultIndexes addObject:@(i)];
        }
    }
    return YES;
}

@end
