//
//  DZChannel+DZChannelOperation.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-17.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZChannel.h"

@interface DZChannel (DZChannelOperation)

- (void)deleteSelf;
- (void)updateWithCompletionHandler:(void(^)(NSError *))handler;

@end
