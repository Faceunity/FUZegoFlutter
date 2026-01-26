//
//  CustomVideoProcess.m
//  Runner
//
//  Created by 27 on 2023/2/10.
//

#import <Foundation/Foundation.h>
#import "CustomVideoProcess.h"

@interface CustomVideoProcess()

@end

@implementation CustomVideoProcess

+ (instancetype)sharedInstance {
    static CustomVideoProcess *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CustomVideoProcess alloc] init];
    });
    return instance;
}


- (void)onStart:(ZGFlutterPublishChannel)channel {
    
}


- (void)onStop:(ZGFlutterPublishChannel)channel {
    
}


- (void)onCapturedUnprocessedCVPixelBuffer:(CVPixelBufferRef)buffer
                                 timestamp:(CMTime)timestamp
                                   channel:(ZGFlutterPublishChannel)channel {
    [[ZegoCustomVideoProcessManager sharedInstance] sendProcessedCVPixelBuffer:buffer timestamp:timestamp channel:channel];
}

@end
