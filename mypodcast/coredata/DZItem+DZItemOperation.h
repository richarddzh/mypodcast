//
//  DZItem+DZItemOperation.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-7.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem.h"

@interface DZItem (DZItemOperation)

@property (nonatomic) BOOL isRead;
@property (nonatomic) BOOL isStored;

- (NSURL *)urlObject;
- (NSString *)downloadFilePath;
- (NSString *)temporaryFilePath;

@end
