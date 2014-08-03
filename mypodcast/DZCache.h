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

typedef void (^DZCacheDataHandler)(NSData * data, NSError * error);

@interface DZCache : NSObject <NSURLSessionDataDelegate>
{
    SCNetworkReachabilityRef _netReachability;
    NSURLCache * _urlCache;
    NSURLSession * _cacheDataSession;
    NSOperationQueue * _backgroundQueue;
}

@property (nonatomic, assign) BOOL shouldOnlyUseWIFI;
@property (nonatomic, assign, readonly) NetworkStatus networkStatus;

+ (DZCache *)sharedInstance;

- (id)initWithRemoteHost:(NSString *)host;
- (void)dealloc;

- (NSString *)getDownloadFilePathWithURL:(NSString *)url;
- (void)getAllDataWithURL:(NSString *)url shouldDownload:(BOOL)download handler:(DZCacheDataHandler)handler;


@end
