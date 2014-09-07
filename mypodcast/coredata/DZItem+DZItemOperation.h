//
//  DZItem+DZItemOperation.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-7.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem.h"

@interface DZItem (DZItemOperation)

- (NSURL *)urlObject;
- (NSString *)downloadFilePath;
- (NSString *)temporaryFilePath;
- (void)removeDownload;

@end
