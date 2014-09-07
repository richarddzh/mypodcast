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
    
    if (self.status == DZDownloadStatus_Complete || self.status == DZDownloadStatus_None) {
        return;
    }
    if (self.progress < 0 || self.progress > 1) {
        return;
    }
    
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
                                                       endAngle:M_PI * (2 * self.progress - 0.5)
                                                      clockwise:YES];
    path.lineWidth = lineWidth;
    [path stroke];
}

- (void)setStatus:(DZDownloadStatus)status
{
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
    self->_status = status;
}

- (void)update
{
    DZDownloadInfo info = [DZDownloadList downloadInfoWithItem:self.feedItem];
    self.status = info.status;
    self.progress = info.progress;
    [self setNeedsDisplay];
}

@end
