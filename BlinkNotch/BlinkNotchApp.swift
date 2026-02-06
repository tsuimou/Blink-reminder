//
//  BlinkNotchApp.swift
//  BlinkNotch
//
//  Created by Hsiao Tsui-mou on 2026/2/5.
//

import SwiftUI

@main
struct BlinkNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Blink Reminder", image: "MenuBarIcon") {
            Button("Settings…") {
                SettingsWindowController.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Blink Reminder") {
                NSApp.terminate(nil)
            }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsWindowController.shared.show()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
