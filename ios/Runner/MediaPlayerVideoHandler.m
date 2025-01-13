//
//  MediaPlayerVideoHandle.m
//  Runner
//
//  Created by 27 on 2023/2/8.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MediaPlayerVideoHandler.h"
#import <ZegoMediaPlayerVideoManager.h>
#include <ZegoCustomVideoCaptureManager.h>


@interface MediaPlayerVideoHandler()<ZegoFlutterMediaPlayerVideoHandler>

@end

@implementation MediaPlayerVideoHandler

+ (instancetype)sharedInstance {
    static MediaPlayerVideoHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MediaPlayerVideoHandler alloc] init];
    });
    return instance;
}


- (void)mediaPlayer:(int)mediaPlayerIndex
    videoFramePixelBuffer:(CVPixelBufferRef)buffer
              param:(ZGFlutterVideoFrameParam *)param {
//    static int64_t value = 0;
//    value += 1;
//    [[ZegoCustomVideoCaptureManager sharedInstance] sendCVPixelBuffer:buffer timestamp:CMTimeMake(value, 15) channel:PublishChannelMain];
}


- (void)mediaPlayer:(int)mediaPlayerIndex
    videoFramePixelBuffer:(CVPixelBufferRef)buffer
                    param:(ZGFlutterVideoFrameParam *)param
          extraInfo:(NSDictionary *)extraInfo {
    
    static int64_t value = 0;
    value += 1;
    [[ZegoCustomVideoCaptureManager sharedInstance] sendCVPixelBuffer:buffer timestamp:CMTimeMake(value, 15) channel:ZGFlutterPublishChannelMain];
}

@end
