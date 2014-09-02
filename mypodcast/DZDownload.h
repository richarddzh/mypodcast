//
//  DZDownload.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-2.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZItem;

typedef enum _dz_download_status_ {
    DZDownloadStatus_None = 0,
    DZDownloadStatus_Downloading,
    DZDownloadStatus_Paused,
    DZDownloadStatus_Complete,
} DZDownloadStatus;

@interface DZDownload : NSObject

@property (nonatomic,readonly) NSURL * url;
@property (nonatomic,readonly) DZDownloadStatus status;

+ (DZDownload *)downloadWithFeedItem:(DZItem *)item;
- (void)start;
- (void)stop;

@end
