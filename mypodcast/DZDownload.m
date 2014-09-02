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
#import "DZFileStream.h"

@interface DZDownload ()
{
    DZItem * _feedItem;
    DZFileStream * _stream;
    NSURL * _url;
    NSString * _path;
    NSString * _tempPath;
}
- (id)initWithFeedItem:(DZItem *)item;
@end

@implementation DZDownload

+ (DZDownload *)downloadWithFeedItem:(DZItem *)item
{
    if (item == nil || item.url == nil) {
        return nil;
    }
    return [[self alloc]init];
}

- (id)initWithFeedItem:(DZItem *)item
{
    self = [super init];
    if (self != nil) {
        self->_feedItem = item;
        self->_url = [NSURL URLWithString:item.url];
        self->_path = [[DZCache sharedInstance]getDownloadFilePathWithURL:self->_url];
        self->_tempPath = [[DZCache sharedInstance]getTemporaryFilePathWithURL:self->_url];
        self->_stream = nil;
    }
    return self;
}

- (NSURL *)url
{
    return self->_url;
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

- (void)start
{
    if (self.status == DZDownloadStatus_Complete || self->_stream != nil) {
        return;
    }
    self->_stream = [DZFileStream streamWithURL:self->_url];
}

- (void)stop
{
    [self->_stream close];
    self->_stream = nil;
}

@end
