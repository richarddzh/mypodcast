//
//  DZCache.h
//  mypodcast
//
//  Created by Richard Dong on 14-7-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

typedef enum : NSInteger {
    NotReachable = 0,
    ReachableViaWiFi,
    ReachableViaWWAN
} NetworkStatus;


@interface DZCache : NSObject <NSURLSessionDataDelegate>
{
    SCNetworkReachabilityRef _netReachability;
}

@property (nonatomic, assign) NetworkStatus networkStatus;

+ (DZCache *)sharedInstance;

- (NSString *)getDownloadFilePathWithURL:(NSURL *)url;
- (NSString *)getTemporaryFilePathWithURL:(NSURL *)url;
- (void)getFileReadyWithURL:(NSURL *)url shallAlwaysDownload:(BOOL)shallAlwaysDownload readyHandler:(void(^)(NSString *, NSError *))handler;

@end
