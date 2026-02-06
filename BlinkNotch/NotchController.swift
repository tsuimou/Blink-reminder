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
                try? await Task.sleep(nanoseconds: waitSeconds * 1_000_000_000)

                guard let self else { continue }
                let screen = self.builtInScreen() ?? NSScreen.main ?? NSScreen.screens.first
                if let screen {
                    await self.notch.expand(on: screen)
                }
                await self.model.playOnce()
                await self.notch.hide()
            }
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
