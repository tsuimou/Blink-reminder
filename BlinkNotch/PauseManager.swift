import Foundation

enum PauseManager {
    static func pause(for seconds: TimeInterval) {
        let until = Date().addingTimeInterval(seconds).timeIntervalSince1970
        UserDefaults.standard.set(until, forKey: SettingsKeys.pauseUntil)
    }

    static func pauseUntilEndOfDay() {
        let calendar = Calendar.current
        let now = Date()
        let startOfTomorrow = calendar.startOfDay(for: now.addingTimeInterval(60 * 60 * 24))
        UserDefaults.standard.set(startOfTomorrow.timeIntervalSince1970, forKey: SettingsKeys.pauseUntil)
    }

    static func resume() {
        UserDefaults.standard.set(0.0, forKey: SettingsKeys.pauseUntil)
    }

    static var pauseUntil: TimeInterval {
        UserDefaults.standard.double(forKey: SettingsKeys.pauseUntil)
    }

    static var isPaused: Bool {
        pauseUntil > Date().timeIntervalSince1970
    }

    static var remainingSeconds: TimeInterval {
        max(0, pauseUntil - Date().timeIntervalSince1970)
    }
}
