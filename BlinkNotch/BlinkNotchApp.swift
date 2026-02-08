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
    @AppStorage(SettingsKeys.pauseUntil) private var pauseUntil: Double = 0.0

    private var isPaused: Bool {
        pauseUntil > Date().timeIntervalSince1970
    }

    var body: some Scene {
        MenuBarExtra("Blink Reminder", image: "MenuBarIcon") {
            Button("Settings…") {
                SettingsWindowController.shared.show()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Menu("Pause For") {
                Button("15 minutes") {
                    PauseManager.pause(for: 15 * 60)
                }
                Button("1 hour") {
                    PauseManager.pause(for: 60 * 60)
                }
                Button("Rest of today") {
                    PauseManager.pauseUntilEndOfDay()
                }
            }

            if isPaused {
                Button("Resume") {
                    PauseManager.resume()
                }
            }

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
