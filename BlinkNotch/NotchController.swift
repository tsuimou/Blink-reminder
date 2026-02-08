import SwiftUI
import Cocoa
import CoreGraphics
import DynamicNotchKit

final class NotchController {
    private let model: BlinkModel
    private let notch: DynamicNotch<EyesView, EmptyView, EmptyView>
    private var loopTask: Task<Void, Never>?

    init() {
        let model = BlinkModel()
        self.model = model
        self.notch = DynamicNotch(
            hoverBehavior: [.keepVisible],
            style: .notch
        ) {
            EyesView(model: model)
        }
    }

    func start() {
        loopTask?.cancel()
        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                let waitSeconds = self?.randomWaitSeconds() ?? 600
                await self?.sleepWithPauseCheck(totalSeconds: waitSeconds)

                guard let self else { continue }
                if PauseManager.isPaused {
                    continue
                }
                let disableWhenCameraInUse = UserDefaults.standard.bool(forKey: SettingsKeys.disableWhenCameraInUse)
                if disableWhenCameraInUse && CameraUsageMonitor.isCameraInUse() {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    continue
                }
                let screen = self.builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
                if let screen {
                    await self.notch.expand(on: screen)
                }
                await self.model.playOnce()
                await self.notch.hide()
            }
        }
    }

    private func sleepWithPauseCheck(totalSeconds: UInt64) async {
        var remaining = totalSeconds
        while remaining > 0 && !Task.isCancelled {
            if PauseManager.isPaused {
                let pauseRemaining = PauseManager.remainingSeconds
                let step = max(1, min(60, Int(pauseRemaining.rounded(.up))))
                try? await Task.sleep(nanoseconds: UInt64(step) * 1_000_000_000)
                continue
            }
            let step = min(remaining, 5)
            try? await Task.sleep(nanoseconds: step * 1_000_000_000)
            remaining -= step
        }
    }

    private func randomWaitSeconds() -> UInt64 {
        // TEMP: test mode (5 seconds). Change back to 600...900 for real use.
        UInt64(Int.random(in: 5...5))
    }

    private func builtInScreen() -> NSScreen? {
        return NSScreen.screens.first { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return false
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            return CGDisplayIsBuiltin(displayID) != 0
        }
    }
}
