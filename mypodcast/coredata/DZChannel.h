//
//  DZChannel.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DZItem;

@interface DZChannel : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * descriptions;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSSet *items;
@end

@interface DZChannel (CoreDataGeneratedAccessors)

- (void)addItemsObject:(DZItem *)value;
- (void)removeItemsObject:(DZItem *)value;
- (void)addItems:(NSSet *)values;
- (void)removeItems:(NSSet *)values;

@end
