//
//  DZEventSource.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-18.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZEventCenter.h"

static DZEventCenter * _sharedInstance;

@interface DZEventCenter ()
{
    NSMutableDictionary * _mapEventIDtoHandlerSet;
}
@end

@implementation DZEventCenter

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_mapEventIDtoHandlerSet = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (DZEventCenter *)sharedInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZEventCenter alloc]init];
    }
    return _sharedInstance;
}

- (void)addHandler:(id<DZEventHandler>)handler forEventID:(NSInteger)eID
{
    NSMutableSet * set = [self->_mapEventIDtoHandlerSet objectForKey:@(eID)];
    if (set == nil) {
        set = [NSMutableSet set];
        [self->_mapEventIDtoHandlerSet setObject:set forKey:@(eID)];
    }
    [set addObject:handler];
}

- (void)removeHandler:(id<DZEventHandler>)handler forEventID:(NSInteger)eID
{
    NSMutableSet * set = [self->_mapEventIDtoHandlerSet objectForKey:@(eID)];
    [set removeObject:handler];
}

- (void)fireEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source
{
    NSMutableSet * set = [self->_mapEventIDtoHandlerSet objectForKey:@(eID)];
    if (set != nil) {
        for (id<DZEventHandler> handler in set) {
            [handler handleEventWithID:eID userInfo:userInfo fromSource:source];
        }
    }
}

@end