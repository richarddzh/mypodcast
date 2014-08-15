//
//  DZFeedParser.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-15.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZChannel;
@class DZItem;

@protocol DZObjectFactory <NSObject>

- (DZChannel *)channelWithURL:(NSString *)url;
- (DZItem *)itemInChannel:(DZChannel *)channel withGuid:(NSString *)guid;

@end

@interface DZFeedParser : NSObject

+ (DZChannel *)parseFeed:(NSData *)data
                   atURL:(NSString *)url
       withObjectFactory:(id<DZObjectFactory>)factory;

@end
