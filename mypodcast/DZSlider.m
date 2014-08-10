//
//  DZSlider.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-7.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "DZSlider.h"

@interface DZSlider ()
{
    UIImage * _thumbImage;
}

@end

@implementation DZSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        UIImage * thumbImage = [[UIImage imageNamed:@"slide-thumb"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setThumbImage:thumbImage forState:UIControlStateDisabled];
        [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        [self setThumbImage:thumbImage forState:UIControlStateSelected];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        UIImage * thumbImage = [[UIImage imageNamed:@"slide-thumb"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setThumbImage:thumbImage forState:UIControlStateDisabled];
        [self setThumbImage:thumbImage forState:UIControlStateHighlighted];
        [self setThumbImage:thumbImage forState:UIControlStateNormal];
        [self setThumbImage:thumbImage forState:UIControlStateSelected];
    }
    return self;
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    float ratio = (value - self.minimumValue) / (self.maximumValue - self.minimumValue);
    CGRect thumbRect = CGRectMake(round(ratio * (rect.size.width - 2)) + rect.origin.x - 15,
                                  rect.origin.y - 15, 32, 32);
    return thumbRect;
}

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.origin.x + 2, bounds.origin.y + 16, bounds.size.width - 4, 1);
}

@end
