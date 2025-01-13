#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

#import <ZegoCustomVideoRenderManager.h>
#import <ZegoMediaPlayerVideoManager.h>
#import <ZegoCustomVideoProcessManager.h>
#import "MediaPlayerVideoHandler.h"
#import "CustomVideoProcess.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];
    
    [[ZegoMediaPlayerVideoManager sharedInstance] setVideoHandler:[MediaPlayerVideoHandler sharedInstance]];
    [[ZegoCustomVideoProcessManager sharedInstance] setCustomVideoProcessHandler:[CustomVideoProcess sharedInstance]];
}

@end
