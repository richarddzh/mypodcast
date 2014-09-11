//
//  DZFileStream.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZItem;

@interface DZFileStream : NSObject <NSURLSessionDataDelegate>

+ (DZFileStream *)streamWithFeedItem:(DZItem *)item;

@property (nonatomic,weak,readonly) DZItem * feedItem;
@property (nonatomic,retain,readonly) NSURL * url;
@property (nonatomic,assign,readonly) NSInteger numByteDownloaded;
@property (nonatomic,assign,readonly) NSInteger numByteFileLength;

- (NSInteger)read:(uint8_t *)dataBuffer maxLength:(NSUInteger)len;
- (BOOL)hasBytesAvailable;
- (BOOL)seek:(NSUInteger)offset;
- (BOOL)shallWait:(NSUInteger)len;
- (void)close;

@end


@interface DZFileStreamLocal : DZFileStream

- (id)initWithFileAtPath:(NSString *)path;

@end


@interface DZFileStreamHttp : DZFileStream

- (id)initWithURL:(NSURL *)url downloadPath:(NSString *)path temporaryPath:(NSString *)tempPath;

@end