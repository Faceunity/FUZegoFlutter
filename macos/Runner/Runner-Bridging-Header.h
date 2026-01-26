//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "CustomVideoProcess.h"
#import "MediaPlayerVideoHandler.h"
#import <ZegoMediaPlayerVideoManager.h>
#import <ZegoCustomVideoProcessManager.h>

void ZGInit(){
    [[ZegoMediaPlayerVideoManager sharedInstance] setVideoHandler:[MediaPlayerVideoHandler sharedInstance]];
        [[ZegoCustomVideoProcessManager sharedInstance] setCustomVideoProcessHandler:[CustomVideoProcess sharedInstance]];
}
