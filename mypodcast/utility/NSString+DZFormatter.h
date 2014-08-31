//
//  NSString+DZFormatter.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (DZFormatter)

+ (NSString *)stringFromTime:(NSTimeInterval)time;
+ (NSString *)stringFromReadableByteSize:(NSUInteger)size;

@end
