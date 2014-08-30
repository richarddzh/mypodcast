//
//  DZDownloadButton.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-28.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DZDownloadButtonDelegate <NSObject>

@end

@interface DZDownloadButton : UIView

@property (nonatomic,retain) id<DZDownloadButtonDelegate> downloadDelegate;

@end
