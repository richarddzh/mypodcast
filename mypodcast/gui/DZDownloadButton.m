//
//  DZDownloadButton.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-2.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <math.h>
#import "DZDownloadButton.h"
#import "UIButton+DZImagePool.h"

@implementation DZDownloadButton

@synthesize downloadTask = _downloadTask;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [super drawRect:rect];
    
    if (self->_downloadTask == nil
        || self->_downloadTask.status == DZDownloadStatus_Complete
        || self->_downloadTask.status == DZDownloadStatus_None) {
        return;
    }
    float progress = (float)(self->_downloadTask.numByteDownloaded) / self->_downloadTask.numByteFileLength;
    
    UIColor * color = [self tintColor];
    [color set];
    CGRect bounds = [self bounds];
    CGPoint point = CGPointMake(bounds.origin.x + bounds.size.width / 2,
                                bounds.origin.y + bounds.size.height / 2);
    CGFloat lineWidth = 1;
    CGFloat radius = 11 - lineWidth / 2;
    UIBezierPath * path = [UIBezierPath bezierPathWithArcCenter:point
                                                         radius:radius
                                                     startAngle:M_PI * (-0.5)
                                                       endAngle:M_PI * (2 * progress - 0.5)
                                                      clockwise:YES];
    path.lineWidth = lineWidth;
    [path stroke];
}

- (void)update
{
    DZDownloadStatus status = self->_downloadTask.status;
    switch (status) {
        case DZDownloadStatus_Complete:
            [self setImageWithName:nil];
            break;
        case DZDownloadStatus_Downloading:
            [self setImageWithName:@"pause-download"];
            break;
        case DZDownloadStatus_None:
        case DZDownloadStatus_Paused:
        default:
            [self setImageWithName:@"download-button"];
            break;
    }
    [self setNeedsDisplay];
}

- (void)pressButton
{
    DZDownloadStatus status = self->_downloadTask.status;
    switch (status) {
        case DZDownloadStatus_Downloading:
            [self->_downloadTask stop];
            break;
        case DZDownloadStatus_None:
        case DZDownloadStatus_Paused:
            [self->_downloadTask start];
            break;
        default:
            break;
    }
    [self update];
}

@end
