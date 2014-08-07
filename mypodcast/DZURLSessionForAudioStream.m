//
//  DZURLSessionForAudioStream.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-4.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZURLSessionForAudioStream.h"

typedef void (^DZReadyHandler)();

@interface DZURLSessionForAudioStream ()
{
    NSURLSession * _session;
    NSURLSessionDataTask * _task;
    NSURL * _url;
    UInt32 _bufferSize;
    uint8_t * _buffer;
    UInt32 _totalBuffered;
    UInt32 _totalConsumed;
    UInt32 _totalDataLength;
    DZReadyHandler _readyHandler;
}
- (NSURLSessionDataTask *)makeNewTask;
@end

@implementation DZURLSessionForAudioStream

@synthesize readySize, bufferProgressView;

- (id)initWithBufferSize:(UInt32)size operationQueue:(NSOperationQueue *)queue
{
    self = [super init];
    if (self != nil) {
        NSURLSessionConfiguration * config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.requestCachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        self->_session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:queue];
        self->_task = nil;
        self->_bufferSize = size;
        self->_buffer = (uint8_t *)malloc(size);
        self->_totalBuffered = 0;
        self->_totalConsumed = 0;
        self->_totalDataLength = 0;
        self->_readyHandler = nil;
    }
    return self;
}

- (void)dealloc
{
    [self->_session finishTasksAndInvalidate];
}

- (NSURLSessionDataTask *)makeNewTask
{
    NSInteger freeLength = self->_bufferSize + self->_totalConsumed - self->_totalBuffered;
    if (freeLength * 2 < self->_bufferSize ||
        (self->_task != nil && self->_task.state == NSURLSessionTaskStateRunning &&
         freeLength < self->_bufferSize)) {
        return self->_task;
    }
    [self->_task cancel];
    if (self->_url == nil) {
        self->_task = nil;
    } else {
        NSMutableURLRequest * req = [[NSURLRequest requestWithURL:self->_url]mutableCopy];
        NSString * range = [NSString stringWithFormat:@"bytes=%u-%lu",
                            (unsigned int)self->_totalBuffered,
                            self->_totalBuffered + freeLength - 1];
        [req setValue:range forHTTPHeaderField:@"Range"];
        req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        self->_task = [self->_session dataTaskWithRequest:req];
        [self->_task resume];
    }
    return self->_task;
}

- (void)prepareForURL:(NSURL *)url handler:(void (^)())handler
{
    self->_url = url;
    self->_readyHandler = handler;
    [self makeNewTask];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse * httpRes = (NSHTTPURLResponse *) response;
    NSString * contentRange = [httpRes.allHeaderFields valueForKey:@"Content-Range"];
    NSRange dilim = [contentRange rangeOfString:@"/"];
    if (dilim.location != NSNotFound) {
        self->_totalDataLength = [[contentRange substringFromIndex:dilim.location + 1]intValue];
    } else {
        self->_totalDataLength = 0;
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (self->_task != dataTask) return;
    if (data == nil) return;
    NSRange range[2], dataRange = NSMakeRange(0, data.length);
    int numRange = 1;
    NSInteger freeLength = self->_bufferSize + self->_totalConsumed - self->_totalBuffered;
    range[0] = NSMakeRange(self->_totalBuffered, freeLength < data.length ? freeLength : data.length);
    if (range[0].length > 0) {
        NSUInteger idx1 = range[0].location / self->_bufferSize;
        NSUInteger pre1 = range[0].location % self->_bufferSize;
        NSUInteger idx2 = (range[0].location + range[0].length - 1) / self->_bufferSize;
        NSUInteger pre2 = (range[0].location + range[0].length - 1) % self->_bufferSize;
        if (range[0].length > 0 && idx1 != idx2) {
            range[0].length = self->_bufferSize - pre1;
            range[1] = NSMakeRange(idx1 * self->_bufferSize + 1, pre2 + 1);
            numRange = 2;
        }
        for (int i = 0; i < numRange; ++i) {
            range[i].location %= self->_bufferSize;
            [data getBytes:self->_buffer + range[i].location range:NSMakeRange(dataRange.location, range[i].length)];
            dataRange.location += range[i].length;
            dataRange.length -= range[i].length;
            self->_totalBuffered += range[i].length;
        }
    }
    if (dataRange.length > 0) {
        [self->_task cancel];
        self->_task = nil;
    }
    if ((self->_totalBuffered >= self->_totalDataLength || self->_totalBuffered > self.readySize)
        && self->_readyHandler != nil) {
        self->_readyHandler();
        self->_readyHandler = nil;
    }
    if (self->_totalDataLength > 0) {
        self.bufferProgressView.progress = (float)(self->_totalBuffered) / self->_totalDataLength;
    }
}

- (NSInteger)read:(uint8_t *)dataBuffer maxLength:(NSUInteger)len
{
    NSRange range[2];
    NSInteger dataOffset = 0;
    NSInteger bufferLength = self->_totalBuffered - self->_totalConsumed;
    int numRange = 1;
    range[0] = NSMakeRange(self->_totalConsumed, bufferLength < len ? bufferLength : len);
    if (range[0].length > 0) {
        NSUInteger idx1 = range[0].location / self->_bufferSize;
        NSUInteger pre1 = range[0].location % self->_bufferSize;
        NSUInteger idx2 = (range[0].location + range[0].length - 1) / self->_bufferSize;
        NSUInteger pre2 = (range[0].location + range[0].length - 1) % self->_bufferSize;
        if (range[0].length > 0 && idx1 != idx2) {
            range[0].length = self->_bufferSize - pre1;
            range[1] = NSMakeRange(idx1 * self->_bufferSize + 1, pre2 + 1);
            numRange = 2;
        }
        for (int i = 0; i < numRange; ++i) {
            range[i].location %= self->_bufferSize;
            memcpy(dataBuffer + dataOffset, self->_buffer + range[i].location, range[i].length);
            self->_totalConsumed += range[i].length;
            dataOffset += range[i].length;
        }
    }
    if (self->_totalBuffered >= self->_totalDataLength) {
        self->_url = nil;
        [self->_task cancel];
        self->_task = nil;
    }
    [self makeNewTask];
    return dataOffset;
}

- (BOOL)hasBytesAvailable
{
    return self->_totalDataLength > self->_totalConsumed;
}

@end
