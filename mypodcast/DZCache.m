//
//  DZCache.m
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZCache.h"

#define MEM_CACHE_SIZE 10000000
#define DISK_CACHE_SIZE 100000000

@interface DZCache ()

- (void)networkReachabilityChangeWithStatus:(NetworkStatus)status;
- (void)prepareURLSession;

@end

static DZCache * _sharedInstance = nil;

static void _reachabilityCallback(SCNetworkReachabilityRef target,
                                  SCNetworkReachabilityFlags flags,
                                  void * info)
{
    DZCache * cache = (__bridge DZCache *)info;
    NetworkStatus status = NotReachable;
    if (flags & kSCNetworkReachabilityFlagsReachable) {
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            status = ReachableViaWiFi;
        }
        if (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand)
            || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic))
            && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0){
            status = ReachableViaWiFi;
        }
    }
    if (flags & kSCNetworkReachabilityFlagsIsWWAN) {
        status = ReachableViaWWAN;
    }
    [cache networkReachabilityChangeWithStatus:status];
}

@implementation DZCache

@synthesize shouldOnlyUseWIFI, networkStatus;

+ (DZCache *)sharedInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZCache alloc]init];
    }
    return _sharedInstance;
}

- (id)init
{
    return [self initWithRemoteHost:@"richarddzh.github.io"];
}

- (id)initWithRemoteHost:(NSString *)host
{
    self = [super init];
    if (self != nil) {
        self.shouldOnlyUseWIFI = YES;
        self->networkStatus = ReachableViaWiFi;
        self->_netReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [host UTF8String]);
        SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(self->_netReachability, _reachabilityCallback, &context)) {
            SCNetworkReachabilityScheduleWithRunLoop(self->_netReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        }
        self->_cacheDataSession = nil;
        NSString * cachePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"]
                                stringByAppendingPathComponent:host];
        self->_urlCache = [[NSURLCache alloc]initWithMemoryCapacity:MEM_CACHE_SIZE
                                                       diskCapacity:DISK_CACHE_SIZE
                                                           diskPath:cachePath];
        self->_backgroundQueue = [[NSOperationQueue alloc]init];
    }
    return self;
}

- (void)dealloc
{
    [self->_backgroundQueue cancelAllOperations];
    SCNetworkReachabilityUnscheduleFromRunLoop(self->_netReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(self->_netReachability);
}

- (void)networkReachabilityChangeWithStatus:(NetworkStatus)status
{
    NSLog(@"Network reachability status: %@", status == NotReachable ? @"NotReachable"
          : (status == ReachableViaWiFi ? @"ReachableViaWiFi" : @"ReachableViaWWAN"));
    self->networkStatus = status;
}

- (void)prepareURLSession
{
    if (self->_cacheDataSession != nil)
        return;
    NSURLSessionConfiguration * cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    cfg.URLCache = self->_urlCache;
    cfg.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    if (self.networkStatus == NotReachable
        || (self.networkStatus == ReachableViaWWAN && self.shouldOnlyUseWIFI)) {
        cfg.requestCachePolicy = NSURLRequestReturnCacheDataDontLoad;
        NSLog(@"Use offline cache");
    }
    self->_cacheDataSession = [NSURLSession sessionWithConfiguration:cfg
                                                            delegate:self
                                                       delegateQueue:[NSOperationQueue mainQueue]];
}

- (NSString *)getDownloadFilePathWithURL:(NSString *)urlString
{
    NSURL * url = [NSURL URLWithString:urlString];
    return [[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
             stringByAppendingPathComponent:url.host]
            stringByAppendingString:url.path];
}

- (void)getAllDataWithURL:(NSString *)url shouldDownload:(BOOL)download handler:(DZCacheDataHandler)handler
{
    NSString * downloadPath = [self getDownloadFilePathWithURL:url];
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if ([fmgr fileExistsAtPath:downloadPath]) {
        handler([NSData dataWithContentsOfFile:downloadPath], nil);
        return;
    }
    [self prepareURLSession];
    NSURLSessionDataTask * task = [self->_cacheDataSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self->_backgroundQueue addOperationWithBlock:^{
            if (download) {
                NSString * downloadDir = [downloadPath stringByDeletingLastPathComponent];
                [fmgr createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:NULL];
                [fmgr createFileAtPath:downloadPath contents:data attributes:nil];
            }
        }];
        handler(data, error);
    }];
    [task resume];
}


@end
