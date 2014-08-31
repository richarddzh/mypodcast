//
//  NSString+DZFormatter.m
//  mypodcast
//
//  Created by Richard Dong on 14-8-31.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import "NSString+DZFormatter.h"

@implementation NSString (DZFormatter)

+ (NSString *)stringFromTime:(NSTimeInterval)time
{
    int itime = round(time);
    NSString * hour = [NSString stringWithFormat:@"%u:", itime / 3600];
    return [NSString stringWithFormat:@"%@%@%02u:%02u",
            (itime >= 0 ? @"" : @"-"),
            (itime / 3600 != 0 ? hour : @""),
            abs(itime) / 60,
            abs(itime) % 60];
}

+ (NSString *)stringFromReadableByteSize:(NSUInteger)size
{
    NSString * unit[] = {@"B", @"KB", @"MB", @"GB"};
    float fSize = size;
    int unitIdx = 0;
    while (unitIdx < 3 && fSize > 1024) {
        fSize /= 1024;
        unitIdx++;
    }
    return [NSString stringWithFormat:@"%.1f%@", fSize, unit[unitIdx]];
}

@end
