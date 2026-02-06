import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        notchController = NotchController()
        notchController?.start()
    }
}
