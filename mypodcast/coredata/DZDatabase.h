//
//  DZDatabase.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DZFeedParser.h"

@interface DZDatabase : NSObject <DZObjectFactory>

@property (nonatomic,retain,readonly) NSManagedObjectModel * model;
@property (nonatomic,retain,readonly) NSPersistentStoreCoordinator * storeCoordinator;
@property (nonatomic,retain,readonly) NSManagedObjectContext * context;

+ (DZDatabase *)sharedInstance;
- (void)save;
- (id)insert:(NSString *)type;
- (id)fetch:(NSString *)type withKey:(NSString *)key value:(id)value;

@end
