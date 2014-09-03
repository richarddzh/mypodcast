//
//  UIButton+DZImagePool.m
//  mypodcast
//
//  Created by Richard Dong on 14-9-3.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "UIButton+DZImagePool.h"
#import "UIImage+DZImagePool.h"

@implementation UIButton (DZImagePool)

- (void)setImageWithName:(NSString *)name
{
    [self setImage:[UIImage templateImageWithName:name]
          forState:UIControlStateNormal];
    [self setImage:[UIImage transparentTemplateImageWithName:name]
          forState:UIControlStateHighlighted];
}

@end
