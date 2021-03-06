//
//  DZFileStream.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFileStream.h"
#import "DZItem.h"
#import "DZEventCenter.h"
#import "DZItem+DZItemOperation.h"
#import "DZItem+DZItemDownload.h"

@interface DZURLSessionDelegate : NSObject <NSURLSessionDataDelegate>
@end

static NSURLSession * _urlSession = nil;
static NSMutableDictionary * _urlTaskMap = nil; // Map task identifier to DZFileStreamHttp instance.
static DZURLSessionDelegate * _urlDelegate = nil;

@interface DZFileStream ()
{
    @protected
    FILE * _fp;
    NSURL * _url;
    NSInteger _numByteDownloaded;
    NSInteger _numByteFileLength;
}
@end

@implementation DZFileStream

@synthesize feedItem = _feedItem;

+ (DZFileStream *)streamWithFeedItem:(DZItem *)item
{
    NSURL * url = item.urlObject;
    NSString * path = item.downloadFilePath;
    NSString * tempPath = item.temporaryFilePath;
    if (item == nil || item.url == nil || url == nil || path == nil || tempPath == nil) {
        return nil;
    }
    NSFileManager * fmgr = [NSFileManager defaultManager];
    DZFileStream * stream = nil;
    if ([fmgr fileExistsAtPath:path]) {
        stream = [[DZFileStreamLocal alloc]initWithFileAtPath:path];
        stream->_url = url;
        stream->_feedItem = item;
    } else {
        stream = [[DZFileStreamHttp alloc]initWithURL:url downloadPath:path temporaryPath:tempPath];
        stream->_feedItem = item;
    }
    return stream;
}

- (NSInteger)read:(uint8_t *)dataBuffer maxLength:(NSUInteger)len
{
    if (self->_fp == NULL) {
        return 0;
    }
    return fread(dataBuffer, 1, len, self->_fp);
}

- (BOOL)hasBytesAvailable
{
    if (self->_fp == NULL) {
        return false;
    }
    return !feof(self->_fp);
}

- (BOOL)seek:(NSUInteger)offset
{
    if (self->_fp == NULL) {
        return false;
    }
    return 0 == fseek(self->_fp, offset, SEEK_SET);
}

- (BOOL)shallWait:(NSUInteger)len
{
    if (self->_fp == NULL) {
        return YES;
    }
    return NO;
}

- (void)close
{
    if (self->_fp != NULL) {
        fclose(self->_fp);
        self->_fp = NULL;
    }
}

- (NSInteger)numByteFileLength
{
    return self->_numByteFileLength;
}

- (NSInteger)numByteDownloaded
{
    return self->_numByteDownloaded;
}

- (NSURL *)url
{
    return self->_url;
}

@end


#pragma mark File Stream of Local File

@implementation DZFileStreamLocal

- (id)initWithFileAtPath:(NSString *)path
{
    self = [super init];
    if (self != nil) {
        NSFileManager * fmgr = [NSFileManager defaultManager];
        NSDictionary * info = [fmgr attributesOfItemAtPath:path error:nil];
        NSNumber * fileSize = [info objectForKey:NSFileSize];
        self->_numByteDownloaded = [fileSize integerValue];
        self->_numByteFileLength = [fileSize integerValue];
        self->_fp = fopen([path UTF8String], "r");
    }
    return self;
}

@end


#pragma mark File Stream over HTTP

@interface DZFileStreamHttp ()
{
    NSInteger _readPosition;
    NSURLSessionDataTask * _task;
    NSString * _path;
    NSString * _tempPath;
}

- (void)issueNewTask;

@end

@implementation DZFileStreamHttp

- (id)initWithURL:(NSURL *)url downloadPath:(NSString *)path temporaryPath:(NSString *)tempPath
{
    self = [super init];
    if (self != nil) {
        if (_urlDelegate == nil) {
            _urlDelegate = [[DZURLSessionDelegate alloc]init];
        }
        if (_urlSession == nil) {
            NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            NSOperationQueue * queue = [NSOperationQueue currentQueue];
            _urlSession = [NSURLSession sessionWithConfiguration:config delegate:_urlDelegate delegateQueue:queue];
        }
        if (_urlTaskMap == nil) {
            _urlTaskMap = [NSMutableDictionary dictionary];
        }
        self->_path = path;
        self->_url = url;
        self->_tempPath = tempPath;
        self->_numByteDownloaded = 0;
        self->_numByteFileLength = NSIntegerMax;
        self->_readPosition = 0;
        self->_task = nil;
        NSFileManager * fmgr = [NSFileManager defaultManager];
        if ([fmgr fileExistsAtPath:self->_tempPath]) {
            NSError * error = nil;
            NSDictionary * info = [fmgr attributesOfItemAtPath:self->_tempPath error:&error];
            if (error != nil) {
                NSLog(@"%@", error.debugDescription);
            }
            NSNumber * fileSize = [info objectForKey:NSFileSize];
            self->_numByteDownloaded = [fileSize integerValue];
        }
        [fmgr createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        self->_fp = fopen([self->_tempPath UTF8String], "a+");
        if (self->_fp == NULL) {
            NSLog(@"[ERROR] cannot open file %@", self->_tempPath);
        }
        [self issueNewTask];
    }
    return self;
}

- (void)close
{
    [self->_task cancel];
    self->_task = nil;
    [super close];
}

- (void)issueNewTask
{
    if (self->_numByteDownloaded >= self->_numByteFileLength) {
        return;
    }
    if (self->_task != nil) {
        [self->_task cancel];
        [_urlTaskMap removeObjectForKey:@(self->_task.taskIdentifier)];
        self->_task = nil;
    }
    NSMutableURLRequest * req = [[NSURLRequest requestWithURL:self->_url]mutableCopy];
    NSString * range = [NSString stringWithFormat:@"bytes=%ld-", (long)self->_numByteDownloaded];
    [req setValue:range forHTTPHeaderField:@"Range"];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    self->_task = [_urlSession dataTaskWithRequest:req];
    [_urlTaskMap setObject:self forKey:@(self->_task.taskIdentifier)];
    [self->_task resume];
    [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_FileStreamWillStartDownload
                                          userInfo:nil
                                        fromSource:self];
}

- (NSInteger)read:(uint8_t *)dataBuffer maxLength:(NSUInteger)len
{
    NSInteger fileRemain = self->_numByteFileLength - self->_readPosition;
    NSInteger downloadRemain = self->_numByteDownloaded - self->_readPosition;
    NSInteger shallRead = len < fileRemain ? len : fileRemain;
    NSInteger canRead = len < downloadRemain ? len : downloadRemain;
    if (canRead < shallRead) {
        return 0;
    }
    if (0 == fseek(self->_fp, self->_readPosition, SEEK_SET)) {
        NSInteger read = fread(dataBuffer, 1, canRead, self->_fp);
        self->_readPosition += read;
        return read;
    }
    return 0;
}

- (BOOL)shallWait:(NSUInteger)len
{
    NSInteger fileRemain = self->_numByteFileLength - self->_readPosition;
    NSInteger downloadRemain = self->_numByteDownloaded - self->_readPosition;
    NSInteger shallRead = len < fileRemain ? len : fileRemain;
    NSInteger canRead = len < downloadRemain ? len : downloadRemain;
    return canRead < shallRead;
}

- (BOOL)hasBytesAvailable
{
    return self->_readPosition < self->_numByteFileLength;
}

- (BOOL)seek:(NSUInteger)offset
{
    // Allow to seek beyond download, then reader shall wait.
    if (offset < self->_numByteFileLength) {
        self->_readPosition = offset;
        return true;
    }
    return false;
}

#pragma mark NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse * httpRes = (NSHTTPURLResponse *) response;
    NSString * contentRange = [httpRes.allHeaderFields valueForKey:@"Content-Range"];
    NSRange dilim = [contentRange rangeOfString:@"/"];
    if (dilim.location != NSNotFound) {
        self->_numByteFileLength = [[contentRange substringFromIndex:dilim.location + 1]integerValue];
        self.feedItem.fileSizeInteger = self->_numByteFileLength;
    }
    [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_FileStreamWillReceiveDownloadData
                                          userInfo:nil
                                        fromSource:self];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (self->_fp != NULL && self->_task == dataTask) {
        [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
            if (self->_fp != NULL) {
                NSInteger written = fwrite(bytes, 1, byteRange.length, self->_fp);
                self->_numByteDownloaded += written;
            }
        }];
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_FileStreamDidReceiveDownloadData
                                              userInfo:nil
                                            fromSource:self];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self->_task == task) {
        [_urlTaskMap removeObjectForKey:@(task.taskIdentifier)];
        self->_task = nil;
    }
    if (error != nil || self->_numByteDownloaded < self->_numByteFileLength) {
        if (error != nil) {
            NSLog(@"[WARNING] download completed with error %@, %@", error, error.debugDescription);
        }
        [self issueNewTask];
        return;
    }
    if (self->_numByteDownloaded >= self->_numByteFileLength) {
        fclose(self->_fp);
        NSFileManager * fmgr = [NSFileManager defaultManager];
        [fmgr moveItemAtPath:self->_tempPath toPath:self->_path error:nil];
        self->_fp = fopen([self->_path UTF8String], "r");
        if (self->_fp == NULL) {
            NSLog(@"[ERROR] cannot open file %@", self->_path);
        }
        [self.feedItem stopDownload];
        [[DZEventCenter sharedInstance]fireEventWithID:DZEventID_FileStreamDidCompleteDownload
                                              userInfo:nil
                                            fromSource:self];
    }
}

@end


@implementation DZURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    DZFileStreamHttp * fs = [_urlTaskMap objectForKey:@(dataTask.taskIdentifier)];
    [fs URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    DZFileStreamHttp * fs = [_urlTaskMap objectForKey:@(dataTask.taskIdentifier)];
    [fs URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    DZFileStreamHttp * fs = [_urlTaskMap objectForKey:@(task.taskIdentifier)];
    [fs URLSession:session task:task didCompleteWithError:error];
}

@end
