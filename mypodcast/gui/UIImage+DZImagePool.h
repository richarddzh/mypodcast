//
//  UIImage+DZImagePool.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-30.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DZImagePool)

+ (UIImage *)templateImageWithName:(NSString *)name;
+ (UIImage *)transparentTemplateImageWithName:(NSString *)name;

@end


@interface UIButton (DZImagePool)

- (void)setImageWithName:(NSString *)name;

@end