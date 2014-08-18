//
//  DZItem.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DZChannel;

@interface DZItem : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * feed;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic, retain) NSDate * pubDate;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * stored;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * lastPlay;
@property (nonatomic, retain) DZChannel *channel;

@end
