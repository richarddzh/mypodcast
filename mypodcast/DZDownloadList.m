//
//  DZDownload.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-2.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZDownloadList.h"
#import "DZItem.h"
#import "DZCache.h"
#import "DZPlayList.h"
#import "DZFileStream.h"

@implementation DZDownloadList

+ (void)startDownloadItem:(DZItem *)item
{
    [DZFileStream streamWithFeedItem:item];
}

+ (void)stopDownloadItem:(DZItem *)item
{
    if (item == [[DZPlayList sharedInstance]currentItem]) {
        return;
    }
    DZFileStream * stream = [DZFileStream existingStreamWithFeedItem:item];
    [stream close];
}

+ (DZDownloadInfo)downloadInfoWithItem:(DZItem *)item
{
    DZDownloadInfo info = {DZDownloadStatus_None, 0.0f};
    if (item == nil || item.url == nil) {
        return info;
    }
    DZFileStream * stream = [DZFileStream existingStreamWithFeedItem:item];
    if (stream != nil) {
        if (stream.numByteDownloaded < stream.numByteFileLength) {
            info.progress = (float)stream.numByteDownloaded / stream.numByteFileLength;
            info.status = DZDownloadStatus_Downloading;
        } else {
            info.progress = 1.0f;
            info.status = DZDownloadStatus_Complete;
        }
        return info;
    }
    NSFileManager * fmgr = [NSFileManager defaultManager];
    NSURL * url = [NSURL URLWithString:item.url];
    if ([fmgr fileExistsAtPath:[[DZCache sharedInstance]getDownloadFilePathWithURL:url]]) {
        info.progress = 1.0f;
        info.status = DZDownloadStatus_Complete;
        return info;
    }
    if ([fmgr fileExistsAtPath:[[DZCache sharedInstance]getTemporaryFilePathWithURL:url]]) {
        NSDictionary * fileInfo = [fmgr attributesOfItemAtPath:[[DZCache sharedInstance]getTemporaryFilePathWithURL:url] error:NULL];
        NSNumber * fileSize = [fileInfo objectForKey:NSFileSize];
        info.progress = (float)[fileSize integerValue] / [item.fileSize integerValue];
        info.status = DZDownloadStatus_Paused;
        return info;
    }
    return info;
}

@end