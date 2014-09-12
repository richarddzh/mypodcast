//
//  DZItem+DZItemDownload.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-11.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZItem.h"

@class DZFileStream;

typedef enum _dz_download_status_ {
    DZDownloadStatus_None = 0,
    DZDownloadStatus_Downloading,
    DZDownloadStatus_Paused,
    DZDownloadStatus_Complete,
} DZDownloadStatus;

typedef struct _dz_download_info_ {
    DZDownloadStatus status;
    float progress;
} DZDownloadInfo;

@interface DZItem (DZItemDownload)

@property (nonatomic,readonly) DZDownloadInfo downloadInfo;
@property (nonatomic,readonly) float downloadProgress;
@property (nonatomic,readonly) DZDownloadStatus downloadStatus;
@property (nonatomic,readonly) NSString * downloadDescription;

- (void)startDownload;
- (void)stopDownload;
- (void)removeDownload;
- (DZFileStream *)openFileStream;
- (DZFileStream *)fileStream;
- (void)closeFileStream;

@end
