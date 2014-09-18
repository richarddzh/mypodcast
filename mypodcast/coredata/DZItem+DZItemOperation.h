//
//  DZItem+DZItemOperation.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-7.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem.h"

@interface DZItem (DZItemOperation)

@property (nonatomic) BOOL isFeed;
@property (nonatomic) BOOL isRead;
@property (nonatomic) BOOL isStored;
@property (nonatomic) NSTimeInterval lastPlayTimeInterval;
@property (nonatomic) NSInteger fileSizeInteger;

- (NSURL *)urlObject;
- (NSString *)downloadFilePath;
- (NSString *)temporaryFilePath;
- (BOOL)isPlaying;

@end
