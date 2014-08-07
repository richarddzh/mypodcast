//
//  DZURLSessionForAudioStream.h
//  mypodcast
//
//  Created by Richard Dong on 14-8-4.
//  Copyright (c) 2014年 Richard Dong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DZURLSessionForAudioStream : NSObject <NSURLSessionDataDelegate>

- (id)initWithBufferSize:(UInt32)size operationQueue:(NSOperationQueue *)queue;
- (void)prepareForURL:(NSURL *)url handler:(void(^)())handler;
- (NSInteger)read:(uint8_t *)dataBuffer maxLength:(NSUInteger)len;
- (BOOL)hasBytesAvailable;

@property (nonatomic, assign) UInt32 readySize;
@property (nonatomic, weak) UIProgressView * bufferProgressView;

@end
