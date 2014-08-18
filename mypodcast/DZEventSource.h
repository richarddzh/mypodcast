//
//  DZEventSource.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-18.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZEventSource;

@interface DZEvent : NSObject

@property (nonatomic,retain) DZEventSource * source;
@property (nonatomic,retain) id userInfo;

@end

@protocol DZEventHandler <NSObject>

- (void)handleEvent:(DZEvent *)event;

@end

@interface DZEventSource : NSObject

- (void)addEventTarget:(id<DZEventHandler>)target;
- (void)removeEventTarget:(id<DZEventHandler>)target;
- (void)fireEventWithInfo:(id)userInfo;

@end
