//
//  DZChannel+DZChannelOperation.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZChannel+DZChannelOperation.h"
#import "DZCache.h"
#import "DZFeedParser.h"
#import "DZDatabase.h"
#import "DZItem+DZItemOperation.h"
#import "DZItem+DZItemDownload.h"

@implementation DZChannel (DZChannelOperation)

- (void)updateWithCompletionHandler:(void (^)(NSError *))handler
{
    [[DZDatabase sharedInstance]save];
    for (DZItem * item in self.items) {
        item.isFeed = NO;
    }
    [[DZCache sharedInstance]getFileReadyWithURL:[NSURL URLWithString:self.url] shallAlwaysDownload:YES readyHandler:^(NSString * path, NSError * error) {
        if (path != nil && error == nil) {
            DZFeedParser * parser = [[DZFeedParser alloc]init];
            NSError * parseError = nil;
            [parser parseFeed:[NSData dataWithContentsOfFile:path]
                        atURL:self.url
            withObjectFactory:[DZDatabase sharedInstance]
                        error:&parseError];
            if (parseError != nil) {
                error = parseError;
                [[DZDatabase sharedInstance]rollback];
            } else {
                for (DZItem * item in self.items) {
                    if (!item.isFeed && !item.isStored) {
                        [item removeDownload];
                    }
                }
            }
        }
        handler(error);
    }];
}

- (void)deleteSelf
{
    for (DZItem * item in self.items) {
        [item removeDownload];
    }
    [[DZDatabase sharedInstance]deleteObject:self];
}

@end
