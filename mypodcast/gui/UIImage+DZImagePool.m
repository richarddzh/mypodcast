//
//  UIImage+DZImagePool.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-30.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "UIImage+DZImagePool.h"

static NSMutableDictionary * _imagePool;

@implementation UIImage (DZImagePool)

+ (UIImage *)templateImageWithName:(NSString *)name
{
    if (name == nil) {
        return nil;
    }
    if (_imagePool == nil) {
        _imagePool = [NSMutableDictionary dictionary];
    }
    UIImage * image = [_imagePool objectForKey:name];
    if (image == nil) {
        image = [[UIImage imageNamed:name]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_imagePool setObject:image forKey:name];
    }
    return image;
}

+ (UIImage *)transparentTemplateImageWithName:(NSString *)name
{
    if (name == nil) {
        return nil;
    }
    if (_imagePool == nil) {
        _imagePool = [NSMutableDictionary dictionary];
    }
    NSString * transparentName = [name stringByAppendingString:@"@transparent"];
    UIImage * image = [_imagePool objectForKey:transparentName];
    if (image == nil) {
        UIImage * oldImage = [UIImage imageNamed:name];
        CGImageRef cgImage = [oldImage CGImage];
        size_t width = CGImageGetWidth(cgImage);
        size_t height = CGImageGetHeight(cgImage);
        CGContextRef context = CGBitmapContextCreate(NULL, width, height,
                                                     CGImageGetBitsPerComponent(cgImage),
                                                     0,
                                                     CGImageGetColorSpace(cgImage),
                                                     CGImageGetBitmapInfo(cgImage));
        CGContextSetAlpha(context, 0.5);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
        CGImageRef cgTransImage = CGBitmapContextCreateImage(context);
        image = [[UIImage imageWithCGImage:cgTransImage]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_imagePool setObject:image forKey:transparentName];
        CGContextRelease(context);
        CGImageRelease(cgTransImage);
    }
    return image;
}

@end

@implementation UIButton (DZImagePool)

- (void)setImageWithName:(NSString *)name
{
    [self setImage:[UIImage templateImageWithName:name]
          forState:UIControlStateNormal];
    [self setImage:[UIImage transparentTemplateImageWithName:name]
          forState:UIControlStateHighlighted];
}

@end
