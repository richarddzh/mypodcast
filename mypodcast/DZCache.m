//
//  DZCache.m
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZCache.h"

static DZCache * _sharedInstance = nil;
const char * kDZRemoteHost = "richarddzh.github.io";

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
    cache.networkStatus = status;
}

@interface DZCache ()
{
    NSURLSession * _urlSession;
}
@end

@implementation DZCache

@synthesize networkStatus;

+ (DZCache *)sharedInstance
{
    if (_sharedInstance == nil) {
        _sharedInstance = [[DZCache alloc]init];
    }
    return _sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        self->networkStatus = NotReachable;
        self->_netReachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, kDZRemoteHost);
        SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(self->_netReachability, _reachabilityCallback, &context)) {
            SCNetworkReachabilityScheduleWithRunLoop(self->_netReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        }
        self->_urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void)dealloc
{
    SCNetworkReachabilityUnscheduleFromRunLoop(self->_netReachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    CFRelease(self->_netReachability);
}

- (NSString *)getDownloadFilePathWithURL:(NSURL *)url
{
    if ([url.scheme.lowercaseString compare:@"http"] == NSOrderedSame) {
        NSString * path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
                           stringByAppendingString:url.path];
        return path;
    }
    return nil;
}

- (NSString *)getTemporaryFilePathWithURL:(NSURL *)url
{
    return [[self getDownloadFilePathWithURL:url]stringByAppendingString:@".download"];
}

- (void)getFileReadyWithURL:(NSURL *)url shallAlwaysDownload:(BOOL)shallAlwaysDownload readyHandler:(void (^)(NSString *, NSError *))handler
{
    NSString * path = [self getDownloadFilePathWithURL:url];
    NSFileManager * fmgr = [NSFileManager defaultManager];
    if ([fmgr fileExistsAtPath:path] && !shallAlwaysDownload) {
        handler(path, nil);
        return;
    }
    NSURLSessionDownloadTask * task = [self->_urlSession downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error == nil && location != nil) {
            [fmgr createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
            [fmgr moveItemAtURL:location toURL:[NSURL fileURLWithPath:path] error:&error];
            if (error != nil) {
                handler(nil, error);
            } else {
                handler(path, nil);
            }
        }
    }];
    [task resume];
}

@end
