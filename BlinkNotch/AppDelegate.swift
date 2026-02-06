import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let showDockIcon = UserDefaults.standard.bool(forKey: SettingsKeys.showDockIcon)
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
        notchController = NotchController()
        notchController?.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsWindowController.shared.show()
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettingsFromDock), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit Blink Reminder", action: #selector(quitFromDock), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    @objc private func openSettingsFromDock() {
        SettingsWindowController.shared.show()
    }

    @objc private func quitFromDock() {
        NSApp.terminate(nil)
    }
}
