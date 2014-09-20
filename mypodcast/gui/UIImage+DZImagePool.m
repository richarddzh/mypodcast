//
//  UIImage+DZImagePool.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-30.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "UIImage+DZImagePool.h"

static NSMutableDictionary * _imagePool;

@interface UIImage (DZImagePrivate)
- (BOOL)hasAlpha;
- (UIImage *)imageWithAlpha:(CGFloat)alpha;
@end

@implementation UIImage (DZImagePrivate)

// Returns true if the image has an alpha layer
- (BOOL)hasAlpha
{
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(self.CGImage);
    return (alpha == kCGImageAlphaFirst ||
            alpha == kCGImageAlphaLast ||
            alpha == kCGImageAlphaPremultipliedFirst ||
            alpha == kCGImageAlphaPremultipliedLast);
}

// Returns a copy of the given image, adding an alpha channel if it doesn't already have one
- (UIImage *)imageWithAlpha:(CGFloat)alpha
{
    if ([self hasAlpha]) {
        return self;
    }
    
    CGImageRef imageRef = self.CGImage;
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
    CGContextRef offscreenContext = CGBitmapContextCreate(NULL,
                                                          width,
                                                          height,
                                                          8,
                                                          0,
                                                          CGImageGetColorSpace(imageRef),
                                                          kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    // Draw the image into the context and retrieve the new image, which will now have an alpha layer
    CGContextSetAlpha(offscreenContext, alpha);
    CGContextDrawImage(offscreenContext, CGRectMake(0, 0, width, height), imageRef);
    CGImageRef imageRefWithAlpha = CGBitmapContextCreateImage(offscreenContext);
    UIImage *imageWithAlpha = [UIImage imageWithCGImage:imageRefWithAlpha];
    
    // Clean up
    CGContextRelease(offscreenContext);
    CGImageRelease(imageRefWithAlpha);
    
    return imageWithAlpha;
}

@end

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
        image = [[oldImage imageWithAlpha:0.5]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        if (image != nil) {
            [_imagePool setObject:image forKey:transparentName];
        } else {
            image = [UIImage templateImageWithName:name];
            NSLog(@"[ERROR] cannot create transparent image.");
        }
    }
    return image;
}

@end
