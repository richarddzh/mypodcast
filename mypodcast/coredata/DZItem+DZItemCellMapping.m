//
//  DZItem+DZItemCellMapping.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-11.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem+DZItemCellMapping.h"
#import "DZItem+DZItemOperation.h"

static NSMutableDictionary * _map;

@implementation DZItem (DZItemCellMapping)

- (void)addMappingToCell:(DZFeedItemCell *)cell
{
    if (cell == nil || self.urlObject == nil) {
        return;
    }
    if (_map == nil) {
        _map = [NSMutableDictionary dictionary];
    }
    NSMutableSet * set = [_map objectForKey:self.urlObject];
    if (set == nil) {
        set = [NSMutableSet set];
        [_map setObject:set forKey:self.urlObject];
    }
    [set addObject:cell];
}

- (void)removeMappingToCell:(DZFeedItemCell *)cell
{
    if (cell == nil || self.urlObject == nil || _map == nil) {
        return;
    }
    NSMutableSet * set = [_map objectForKey:self.urlObject];
    [set removeObject:cell];
}

- (NSSet *)tableViewCells
{
    if (self.urlObject == nil || _map == nil) {
        return [NSSet set];
    }
    NSSet * set = [_map objectForKey:self.urlObject];
    if (set == nil) {
        set = [NSSet set];
    }
    return set;
}

@end
