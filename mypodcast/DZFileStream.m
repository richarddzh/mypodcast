//
//  DZFileStream.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZFileStream.h"
#import "DZCache.h"

static NSURLSession * _urlSession = nil;

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

+ (DZFileStream *)streamWithURL:(NSURL *)url
{
    DZCache * cache = [DZCache sharedInstance];
    NSString * path = [cache getDownloadFilePathWithURL:url];
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if (path != nil && [fmgr fileExistsAtPath:path]) {
        return [[DZFileStreamLocal alloc]initWithFileAtPath:path];
    }
    if (path != nil) {
        return [[DZFileStreamHttp alloc]initWithURL:url downloadPath:path];
    }
    return nil;
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

- (id)initWithURL:(NSURL *)url downloadPath:(NSString *)path
{
    self = [super init];
    if (self != nil) {
        if (_urlSession == nil) {
            NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
            config.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
            NSOperationQueue * queue = [NSOperationQueue currentQueue];
            _urlSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
        }
        self->_url = url;
        self->_path = path;
        self->_tempPath = [path stringByAppendingString:@".download"];
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
        [self issueNewTask];
    }
    return self;
}

- (void)close
{
    [self->_task cancel];
    [super close];
}

- (void)issueNewTask
{
    if (self->_numByteDownloaded >= self->_numByteFileLength) {
        return;
    }
    if (self->_task != nil) {
        [self->_task cancel];
        self->_task = nil;
    }
    NSMutableURLRequest * req = [[NSURLRequest requestWithURL:self->_url]mutableCopy];
    NSString * range = [NSString stringWithFormat:@"bytes=%u-", self->_numByteDownloaded];
    [req setValue:range forHTTPHeaderField:@"Range"];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    self->_task = [_urlSession dataTaskWithRequest:req];
    [self->_task resume];
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

- (BOOL)hasBytesAvailable
{
    return self->_readPosition < self->_numByteFileLength;
}

- (BOOL)seek:(NSUInteger)offset
{
    if (offset < self->_numByteDownloaded) {
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
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        NSInteger written = fwrite(bytes, 1, byteRange.length, self->_fp);
        self->_numByteDownloaded += written;
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (self->_task == task) {
        self->_task = nil;
    }
    if (error != nil || self->_numByteDownloaded < self->_numByteFileLength) {
        [self issueNewTask];
        return;
    }
    if (self->_numByteDownloaded >= self->_numByteFileLength) {
        fclose(self->_fp);
        NSFileManager * fmgr = [NSFileManager defaultManager];
        [fmgr moveItemAtPath:self->_tempPath toPath:self->_path error:nil];
        self->_fp = fopen([self->_path UTF8String], "r");
    }
}

@end
