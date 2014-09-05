//
//  DZDownload.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-2.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZDownload.h"
#import "DZItem.h"
#import "DZCache.h"
#import "DZEventCenter.h"


// Map DZDownload from NSURL.
static NSMutableDictionary * _downloadList;

@interface DZDownload ()
{
    DZItem * _feedItem;
    DZFileStream * _stream;
    NSString * _path;
    NSString * _tempPath;
}
- (id)initWithFeedItem:(DZItem *)item;
@end

@implementation DZDownload

@synthesize url = _url;
@synthesize numByteFileLength = _numByteFileLength;

+ (DZDownload *)downloadWithFeedItem:(DZItem *)item
{
    if (item == nil || item.url == nil) {
        return nil;
    }
    if (_downloadList == nil) {
        _downloadList = [NSMutableDictionary dictionary];
    }
    DZDownload * download = [_downloadList objectForKey:[NSURL URLWithString:item.url]];
    if (download == nil) {
        download = [[self alloc]initWithFeedItem:item];
        [_downloadList setObject:download forKey:download->_url];
    }
    return download;
}

- (id)initWithFeedItem:(DZItem *)item
{
    self = [super init];
    if (self != nil) {
        self->_feedItem = item;
        self->_url = [NSURL URLWithString:item.url];
        self->_path = [[DZCache sharedInstance]getDownloadFilePathWithURL:self->_url];
        self->_tempPath = [[DZCache sharedInstance]getTemporaryFilePathWithURL:self->_url];
        self->_stream = [DZFileStream streamExistingWithURL:[NSURL URLWithString:item.url]];
        self->_stream.delegate = self;
        NSFileManager * fmgr = [NSFileManager defaultManager];
        if ([fmgr fileExistsAtPath:self->_path]) {
            NSDictionary * info = [fmgr attributesOfItemAtPath:self->_path error:NULL];
            NSNumber * size = [info objectForKey:NSFileSize];
            self->_numByteFileLength = [size integerValue];
        } else if (self->_stream != nil) {
            self->_numByteFileLength = self->_stream.numByteFileLength;
        } else {
            self->_numByteFileLength = NSIntegerMax;
        }
    }
    return self;
}

- (DZDownloadStatus)status
{
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if ([fmgr fileExistsAtPath:self->_path]) {
        return DZDownloadStatus_Complete;
    }
    if ([fmgr fileExistsAtPath:self->_tempPath]) {
        if (self->_stream != nil) {
            return DZDownloadStatus_Downloading;
        }
        return DZDownloadStatus_Paused;
    }
    return DZDownloadStatus_None;
}

- (NSInteger)numByteDownloaded
{
    if (self->_stream != nil) {
        return [self->_stream numByteDownloaded];
    }
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if ([fmgr fileExistsAtPath:self->_path]) {
        return self->_numByteFileLength;
    }
    if ([fmgr fileExistsAtPath:self->_tempPath]) {
        NSDictionary * info = [fmgr attributesOfItemAtPath:self->_tempPath error:NULL];
        NSNumber * size = [info objectForKey:NSFileSize];
        return [size integerValue];
    }
    return 0;
}

- (NSInteger)numByteFileLength
{
    if (self->_stream != nil) {
        self->_numByteFileLength = self->_stream.numByteFileLength;
    }
    return self->_numByteFileLength;
}

- (void)start
{
    if (self.status == DZDownloadStatus_Complete || self->_stream != nil) {
        return;
    }
    self->_stream = [DZFileStream streamWithURL:self->_url];
    self->_stream.delegate = self;
}

- (void)stop
{
    [self->_stream close];
    self->_stream.delegate = nil;
    self->_stream = nil;
}

- (void)fileStreamDidCompleteDownload:(DZFileStream *)stream
{
    if (stream == self->_stream) {
        [self numByteFileLength];
        [self stop];
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_DownloadDidComplete
                                              userInfo:nil
                                            fromSource:self];
    }
}

- (void)fileStreamDidReceiveData:(DZFileStream *)stream
{
    if (stream == self->_stream) {
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_DownloadDidReceiveData
                                              userInfo:nil
                                            fromSource:self];
    }
}

@end
