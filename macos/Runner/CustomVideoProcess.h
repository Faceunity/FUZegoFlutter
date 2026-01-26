//
//  CustomVideoProcess.h
//  Runner
//
//  Created by 27 on 2023/2/10.
//

#ifndef CustomVideoProcess_h
#define CustomVideoProcess_h

#import <Foundation/Foundation.h>
#import <ZegoCustomVideoProcessManager.h>

@interface CustomVideoProcess<ZegoFlutterCustomVideoProcessHandler> : NSObject

/// Get the custom video capture manager instance
+ (instancetype)sharedInstance;

@end

#endif /* CustomVideoProcess_h */
