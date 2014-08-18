//
//  DZEventSource.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-18.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZEventSource.h"

@implementation DZEvent

@synthesize source, userInfo;

@end

@interface DZEventSource ()
{
    NSMutableSet * _handlers;
}
@end

@implementation DZEventSource

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->_handlers = [[NSMutableSet alloc]init];
    }
    return self;
}

- (void)dealloc
{
    self->_handlers = nil;
}

- (void)addEventTarget:(id<DZEventHandler>)target
{
    [self->_handlers addObject:target];
}

- (void)removeEventTarget:(id<DZEventHandler>)target
{
    [self->_handlers removeObject:target];
}

- (void)fireEventWithInfo:(id)userInfo
{
    for (id<DZEventHandler> handler in self->_handlers) {
        DZEvent * event = [[DZEvent alloc]init];
        event.source = self;
        event.userInfo = userInfo;
        [handler handleEvent:event];
    }
}

@end
