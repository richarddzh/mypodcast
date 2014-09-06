//
//  DZFileStream.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-8.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DZFileStream;
@class DZItem;

@protocol DZFileStreamDelegate <NSObject>

- (void)fileStreamWillStartDownload:(DZFileStream *)stream;
- (void)fileStreamWillReceiveDownloadData:(DZFileStream *)stream;
- (void)fileStreamDidCompleteDownload:(DZFileStream *)stream;
- (void)fileStreamDidReceiveDownloadData:(DZFileStream *)stream;

@end

@interface DZFileStream : NSObject <NSURLSessionDataDelegate>

+ (DZFileStream *)existingStreamWithFeedItem:(DZItem *)item;
+ (DZFileStream *)streamWithFeedItem:(DZItem *)item;
+ (DZFileStream *)streamWithURL:(NSURL *)url;

@property (nonatomic,weak,readonly) DZItem * feedItem;
@property (nonatomic,retain,readonly) NSURL * url;
@property (nonatomic,weak,readwrite) id<DZFileStreamDelegate> delegate;
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

- (id)initWithURL:(NSURL *)url downloadPath:(NSString *)path;

@end