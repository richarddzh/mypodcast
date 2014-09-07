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

- (void)removeDownload
{
    [DZDownloadList stopDownloadItem:self];
    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSString * downloadPath = [self downloadFilePath];
    NSString * tempPath = [self temporaryFilePath];
    NSError * error = nil;
    if ([fmgr fileExistsAtPath:downloadPath]) {
        if (![fmgr removeItemAtPath:downloadPath error:&error]) {
            NSLog(@"[ERROR] remove download file %@. failed with error %@, %@",
                  downloadPath,
                  error,
                  error.debugDescription);
        }
    }
    if ([fmgr fileExistsAtPath:tempPath]) {
        if (![fmgr removeItemAtPath:tempPath error:&error]) {
            NSLog(@"[ERROR] remove temporary file %@. failed with error %@, %@",
                  tempPath,
                  error,
                  error.debugDescription);
        }
    }
}

@end
