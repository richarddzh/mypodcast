//
//  DZItem+DZItemOperation.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-7.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem+DZItemOperation.h"
#import "DZDownloadList.h"
#import "DZCache.h"

@implementation DZItem (DZItemOperation)

- (NSURL *)urlObject
{
    return [NSURL URLWithString:self.url];
}

- (NSString *)downloadFilePath
{
    return [[DZCache sharedInstance]getDownloadFilePathWithURL:[self urlObject]];
}

- (NSString *)temporaryFilePath
{
    return [[DZCache sharedInstance]getTemporaryFilePathWithURL:[self urlObject]];
}


- (BOOL)isStored
{
    return [self.stored boolValue];
}

- (void)setIsStored:(BOOL)isStored
{
    self.stored = @(isStored);
}

- (BOOL)isRead
{
    return [self.read boolValue];
}

- (void)setIsRead:(BOOL)isRead
{
    self.read = @(isRead);
}

@end
