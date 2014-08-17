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
- (void)getDataWithURL:(NSURL *)url shallDownload:(BOOL)shallDownload dataHandler:(void(^)(NSData *, NSError *))handler;

@end
