//
//  DZDownloadButton.h
//  mypodcast
//
//  Created by Richard Dong on 14-9-2.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DZItem+DZItemDownload.h"

@interface DZDownloadButton : UIButton

@property (nonatomic,assign) DZDownloadStatus status;
@property (nonatomic,assign) float progress;

@end
