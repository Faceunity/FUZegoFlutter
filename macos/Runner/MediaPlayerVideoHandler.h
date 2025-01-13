//
//  MediaPlayerVideoHandle.h
//  Runner
//
//  Created by 27 on 2023/2/8.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

#ifndef MediaPlayerVideoHandler_h
#define MediaPlayerVideoHandler_h

#import <Foundation/Foundation.h>
#import <ZegoMediaPlayerVideoManager.h>

@interface MediaPlayerVideoHandler<ZegoFlutterMediaPlayerVideoHandler> : NSObject

/// Get the custom video capture manager instance
+ (instancetype)sharedInstance;

@end



#endif /* MediaPlayerVideoHandler_h */
