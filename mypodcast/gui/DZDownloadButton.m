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

@synthesize progress, status;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.progress = 0.7;
        self.status = DZDownloadStatus_Complete;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        self.progress = 0.7;
        self.status = DZDownloadStatus_Complete;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    [super drawRect:rect];
    
    UIColor * color = [self tintColor];
    [color set];
    CGRect bounds = [self bounds];
    CGPoint point = CGPointMake(bounds.origin.x + bounds.size.width / 2,
                                bounds.origin.y + bounds.size.height / 2);
    CGFloat lineWidth = 1;
    CGFloat radius = 11 - lineWidth / 2;
    UIBezierPath * path = [UIBezierPath bezierPathWithArcCenter:point
                                                         radius:radius
                                                     startAngle:0.0f - M_PI / 2
                                                       endAngle:M_PI * (2 * self.progress - 0.5)
                                                      clockwise:YES];
    path.lineWidth = lineWidth;
    [path stroke];
}

- (void)setStatus:(DZDownloadStatus)_status
{
    self->status = _status;
    switch (_status) {
        case DZDownloadStatus_Complete:
            self.progress = 1;
            [self setImageWithName:@"complete-button"];
            break;
        case DZDownloadStatus_Downloading:
            [self setImageWithName:@"pause-download"];
            break;
        case DZDownloadStatus_None:
            self.progress = 0;
        case DZDownloadStatus_Paused:
        default:
            [self setImageWithName:@"download-button"];
            break;
    }
}

@end
