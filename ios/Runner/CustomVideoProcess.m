//
//  CustomVideoProcess.m
//  Runner
//
//  Created by 27 on 2023/2/10.
//

#import <Foundation/Foundation.h>
#import "CustomVideoProcess.h"

#include <ZegoCustomVideoProcessManager.h>

#import "FURenderKitManager.h"

@interface CustomVideoProcess()<ZegoFlutterCustomVideoProcessHandler>

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
    int a = 0;
}


- (void)onStop:(ZGFlutterPublishChannel)channel {
    int a = 0;
}


- (void)onCapturedUnprocessedCVPixelBuffer:(CVPixelBufferRef)buffer
                                 timestamp:(CMTime)timestamp
                                   channel:(ZGFlutterPublishChannel)channel {
    
    if (fuIsLibraryInit() > 0) {
        [FURenderKitManager updateBeautyBlurEffect];
        FURenderInput *input = [[FURenderInput alloc] init];
        input.renderConfig.imageOrientation = FUImageOrientationUP;
        input.renderConfig.readBackToPixelBuffer = YES;
        input.renderConfig.gravityEnable = YES;
//        input.renderConfig.isFromFrontCamera = NO;
//        input.renderConfig.isFromMirroredCamera = NO;
        input.pixelBuffer = buffer;
        [[FURenderKit shareRenderKit] renderWithInput:input];
        
        NSLog(@"----%d", fuHumanProcessorGetNumResults());
    }
    [[ZegoCustomVideoProcessManager sharedInstance] sendProcessedCVPixelBuffer:buffer timestamp:timestamp channel:channel];
}

@end
