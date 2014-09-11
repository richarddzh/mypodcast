//
//  DZItem+DZItemDownload.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-11.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem+DZItemDownload.h"
#import "DZFileStream.h"
#import "DZPlayList.h"
#import "DZItem+DZItemOperation.h"

static NSMutableDictionary * _mapURLToStream;

@implementation DZItem (DZItemDownload)

- (DZFileStream *)openFileStream
{
    if (self.urlObject == nil) {
        return nil;
    }
    if (_mapURLToStream == nil) {
        _mapURLToStream = [NSMutableDictionary dictionary];
    }
    DZFileStream * stream = [_mapURLToStream objectForKey:self.urlObject];
    if (stream != nil) {
        return stream;
    }
    stream = [DZFileStream streamWithFeedItem:self];
    [_mapURLToStream setObject:stream forKey:self.urlObject];
    return stream;
}

- (void)closeFileStream
{
    if (_mapURLToStream == nil || self.urlObject == nil) {
        return;
    }
    DZFileStream * stream = [_mapURLToStream objectForKey:self.urlObject];
    if (stream == nil) {
        return;
    }
    [stream close];
    [_mapURLToStream removeObjectForKey:self.urlObject];
}

- (DZFileStream *)fileStream
{
    if (self.urlObject == nil) {
        return nil;
    }
    return [_mapURLToStream objectForKey:self.urlObject];
}

- (void)startDownload
{
    [self openFileStream];
}

- (void)stopDownload
{
    if ([self isPlaying]) {
        return;
    }
    [self closeFileStream];
}

- (void)removeDownload
{
    if ([self isPlaying]) {
        return;
    }
    [self closeFileStream];
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

- (DZDownloadInfo)downloadInfo
{
    DZDownloadInfo info = {DZDownloadStatus_None, 0.0f};
    if (self.urlObject == nil) {
        return info;
    }
    DZFileStream * stream = self.fileStream;
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
    if ([fmgr fileExistsAtPath:self.downloadFilePath]) {
        info.progress = 1.0f;
        info.status = DZDownloadStatus_Complete;
        return info;
    }
    NSString * tempPath = self.temporaryFilePath;
    if ([fmgr fileExistsAtPath:tempPath]) {
        NSDictionary * fileInfo = [fmgr attributesOfItemAtPath:tempPath error:NULL];
        NSNumber * fileSize = [fileInfo objectForKey:NSFileSize];
        info.progress = (float)[fileSize integerValue] / [self.fileSize integerValue];
        info.status = DZDownloadStatus_Paused;
        return info;
    }
    return info;
}

- (float)downloadProgress
{
    return self.downloadInfo.progress;
}

- (DZDownloadStatus)downloadStatus
{
    return self.downloadInfo.status;
}

@end
