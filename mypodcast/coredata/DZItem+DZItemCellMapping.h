//
//  DZItem+DZItemCellMapping.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-11.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem.h"

@class DZFeedItemCell;

@interface DZItem (DZItemCellMapping)

- (void)addMappingToCell:(DZFeedItemCell *)cell;
- (void)removeMappingToCell:(DZFeedItemCell *)cell;
- (NSSet *)tableViewCells;

@end
