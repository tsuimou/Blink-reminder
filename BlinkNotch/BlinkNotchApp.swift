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
        Settings {
            EmptyView()
        }
    }
}
