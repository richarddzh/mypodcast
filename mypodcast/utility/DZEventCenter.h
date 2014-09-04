//
//  DZEventSource.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-18.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _dz_event_id_type_ {
    DZEventID_PlayerWillStartPlaying,
    DZEventID_PlayerDidFinishPlaying,
    DZEventID_PlayerIsPlaying,
    DZEventID_PlayerWillAbortPlaying,
} DZEventIDType;

@protocol DZEventHandler <NSObject>
- (void)handleEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source;
@end

@interface DZEventCenter : NSObject

+ (DZEventCenter *)sharedInstance;
- (void)addHandler:(id<DZEventHandler>)handler forEventID:(NSInteger)eID;
- (void)removeHandler:(id<DZEventHandler>)handler forEventID:(NSInteger)eID;
- (void)fireEventWithID:(NSInteger)eID userInfo:(id)userInfo fromSource:(id)source;

@end
