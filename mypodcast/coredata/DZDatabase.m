//
//  DZDatabase.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZDatabase.h"
#import "DZChannel.h"
#import "DZItem.h"

@interface DZDatabase ()
{
    NSManagedObjectModel * _model;
    NSPersistentStoreCoordinator * _storeCoordinator;
    NSManagedObjectContext * _context;
}
- (NSURL *)applicationDocumentsDirectory;
@end

@implementation DZDatabase

+ (DZDatabase *)sharedInstance
{
    static DZDatabase * _sharedInstance = nil;
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZDatabase alloc]init];
    }
    return _sharedInstance;
}

- (NSManagedObjectModel *)model
{
    if (self->_model == nil) {
        NSURL * url = [[NSBundle mainBundle]URLForResource:@"Model" withExtension:@"momd"];
        self->_model = [[NSManagedObjectModel alloc]initWithContentsOfURL:url];
    }
    return self->_model;
}

- (NSPersistentStoreCoordinator *)storeCoordinator
{
    if (self->_storeCoordinator == nil) {
        self->_storeCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.model];
        NSURL * url = [[self applicationDocumentsDirectory]URLByAppendingPathComponent:@"Model.sqlite"];
        NSError * err = nil;
        if (![self->_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&err]) {
            NSLog(@"[ERROR] unresolved error adding persistent store: %@, %@", err, err.userInfo);
        }
    }
    return self->_storeCoordinator;
}

- (NSManagedObjectContext *)context
{
    if (self->_context == nil) {
        NSPersistentStoreCoordinator * psc = self.storeCoordinator;
        if (psc != nil) {
            self->_context = [[NSManagedObjectContext alloc]init];
            [self->_context setPersistentStoreCoordinator:psc];
        }
    }
    return self->_context;
}

- (void)save
{
    NSManagedObjectContext * context = self.context;
    if (context != nil && [context hasChanges]) {
        NSError * err = nil;
        if (![context save:&err]) {
            NSLog(@"[ERROR] unresolved error saving managed object context: %@, %@", err, err.userInfo);
        }
    }
}

- (void)rollback
{
    NSManagedObjectContext * context = self.context;
    if (context != nil && [context hasChanges]) {
        [context rollback];
    }
}

- (id)insert:(NSString *)type
{
    NSManagedObjectContext * context = self.context;
    if (context == nil) {
        return nil;
    }
    self.numInsertedObjects = self.numInsertedObjects + 1;
    return [NSEntityDescription insertNewObjectForEntityForName:type inManagedObjectContext:context];
}

- (id)fetch:(NSString *)type withKey:(NSString *)key value:(id)value
{
    NSManagedObjectContext * context = self.context;
    if (context == nil) {
        return nil;
    }
    NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:type];
    [req setFetchLimit:1];
    [req setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", key, value]];
    NSError * err = nil;
    NSArray * result = [context executeFetchRequest:req error:&err];
    if (err != nil) {
        NSLog(@"[ERROR] unresolved error fetching object: %@, %@", err, err.userInfo);
    }
    if (result == nil || result.count < 1) {
        return nil;
    }
    if (result.count > 1) {
        NSLog(@"[WARNING] fetch one from result of %lu objects.", (unsigned long)result.count);
    }
    return result.firstObject;
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (DZChannel *)channelWithURL:(NSString *)url
{
    if (url == nil) {
        return nil;
    }
    DZChannel * channel = [self fetch:@"DZChannel" withKey:@"url" value:url];
    if (channel == nil) {
        channel = [self insert:@"DZChannel"];
        channel.url = url;
    }
    return channel;
}

- (DZItem *)itemInChannel:(DZChannel *)channel withGuid:(NSString *)guid
{
    if (channel == nil || guid == nil) {
        return nil;
    }
    NSPredicate * pred = [NSPredicate predicateWithFormat:@"%K = %@", @"guid", guid];
    NSSet * items = [channel.items filteredSetUsingPredicate:pred];
    DZItem * item = [items anyObject];
    if (item != nil) {
        return item;
    }
    item = [self insert:@"DZItem"];
    if (item != nil) {
        [channel addItemsObject:item];
        item.channel = channel;
        item.guid = guid;
        item.stored = @(NO);
        item.read = @(NO);
        item.lastPlay = @(0.0f);
    }
    return item;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [self.context deleteObject:object];
}

- (NSArray *)fetchAll:(NSString *)type
{
    NSManagedObjectContext * context = self.context;
    if (context == nil) {
        return nil;
    }
    NSFetchRequest * req = [NSFetchRequest fetchRequestWithEntityName:type];
    NSError * err = nil;
    NSArray * result = [context executeFetchRequest:req error:&err];
    if (err != nil) {
        NSLog(@"[ERROR] unresolved error fetching object: %@, %@", err, err.userInfo);
    }
    return result;
}

@end
