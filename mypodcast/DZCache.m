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
        return [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
                stringByAppendingString:url.path];
    }
    return nil;
}

@end
