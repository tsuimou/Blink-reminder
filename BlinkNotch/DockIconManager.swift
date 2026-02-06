import AppKit

enum DockIconManager {
    static func apply(showDockIcon: Bool) -> Bool {
        let target: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        if NSApp.activationPolicy() == target {
            return true
        }
        return NSApp.setActivationPolicy(target)
    }

    static func relaunch() {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.2; open -a \"Blink Reminder\""]
        task.launch()
        NSApp.terminate(nil)
    }
}
