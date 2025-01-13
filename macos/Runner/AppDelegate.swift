import Cocoa
import FlutterMacOS
import zego_express_engine

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

    override func applicationWillFinishLaunching(_ notification: Notification) {
        ZGInit();
    }
 
}
