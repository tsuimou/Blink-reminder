import Foundation
import ServiceManagement

enum RunAtLoginManager {
    static func apply(isEnabled: Bool) {
        if isEnabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
