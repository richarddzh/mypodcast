//
//  DZItem.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DZChannel;

@interface DZItem : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * guid;
@property (nonatomic) NSTimeInterval pubDate;
@property (nonatomic) float duration;
@property (nonatomic) float read;
@property (nonatomic) BOOL stored;
@property (nonatomic) BOOL feed;
@property (nonatomic, retain) DZChannel *channel;

@end
