import SwiftUI

private let SUPPORT_URL = "https://example.com/support"

struct SettingsView: View {
    @AppStorage(SettingsKeys.reminderFrequencyMinutes) private var reminderFrequencyMinutes: Int = 15
    @AppStorage(SettingsKeys.exerciseClosedSeconds) private var exerciseClosedSeconds: Int = 2
    @AppStorage(SettingsKeys.intensity) private var intensity: String = "subtle"
    @AppStorage(SettingsKeys.runAtLogin) private var runAtLogin: Bool = false
    @AppStorage(SettingsKeys.disableInFullscreen) private var disableInFullscreen: Bool = true
    @AppStorage(SettingsKeys.disableDuringScreenShare) private var disableDuringScreenShare: Bool = true
    @AppStorage(SettingsKeys.disableWhenCameraInUse) private var disableWhenCameraInUse: Bool = true
    @AppStorage(SettingsKeys.showDockIcon) private var showDockIcon: Bool = false
    @AppStorage(SettingsKeys.pauseUntil) private var pauseUntil: Double = 0.0

    @State private var showDockRelaunchNote = false

    private var isPaused: Bool {
        pauseUntil > Date().timeIntervalSince1970
    }

    private var pauseStatusText: String {
        guard isPaused else { return "Not paused" }
        let date = Date(timeIntervalSince1970: pauseUntil)
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Paused until \(formatter.string(from: date))"
    }

    var body: some View {
        HStack(spacing: 20) {
            Form {
                Section(header: Text("Timing").font(.headline)) {
                    Picker("Reminder frequency", selection: $reminderFrequencyMinutes) {
                        Text("Every 15 minutes").tag(15)
                        Text("Every 20 minutes").tag(20)
                        Text("Every 30 minutes").tag(30)
                    }
                    .accessibilityLabel("Reminder frequency")

                    Picker("Eye-closed duration", selection: $exerciseClosedSeconds) {
                        Text("2 seconds").tag(2)
                        Text("3 seconds").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Eye-closed duration")

                    Text("Longer closures can help express protective oil from the eyelids. No squeezing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("Pause reminders")
                        Spacer()
                        if isPaused {
                            Button("Resume") {
                                PauseManager.resume()
                            }
                        } else {
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
                        }
                    }

                    Text(pauseStatusText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("Appearance").font(.headline)) {
                    Picker("Intensity", selection: $intensity) {
                        Text("Subtle").tag("subtle")
                        Text("Standard").tag("standard")
                    }
                    .accessibilityLabel("Intensity")

                    Text("Adjust how noticeable the blink feels in your peripheral vision.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text("Behavior").font(.headline)) {
                    Toggle("Run at login", isOn: $runAtLogin)
                        .accessibilityLabel("Run at login")
                        .onChange(of: runAtLogin) { _, newValue in
                            RunAtLoginManager.apply(isEnabled: newValue)
                        }

                    Toggle("Disable during full-screen apps", isOn: $disableInFullscreen)
                        .accessibilityLabel("Disable during full-screen apps")

                    Toggle("Disable during screen sharing", isOn: $disableDuringScreenShare)
                        .accessibilityLabel("Disable during screen sharing")

                    Toggle("Disable when camera is in use", isOn: $disableWhenCameraInUse)
                        .accessibilityLabel("Disable when camera is in use")

                    Text("Pauses Blink when another app uses the camera.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Show Dock icon", isOn: $showDockIcon)
                        .accessibilityLabel("Show Dock icon")
                        .onChange(of: showDockIcon) { _, newValue in
                            showDockRelaunchNote = !DockIconManager.apply(showDockIcon: newValue)
                        }

                    Text("Shows Blink in the Dock for quicker access to settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if showDockRelaunchNote {
                        HStack {
                            Text("May require relaunch")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button("Relaunch Blink Reminder") {
                                DockIconManager.relaunch()
                            }
                        }
                    }
                }

                Section(header: Text("Privacy").font(.headline)) {
                    Text("Blink does not use the camera, track activity, or collect data.")
                        .font(.callout)
                }

                Section(header: Text("About").font(.headline)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersionString)
                            .foregroundStyle(.secondary)
                    }

                    Button("Support this project") {
                        openSupportURL()
                    }
                    .accessibilityLabel("Support this project")
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 440, idealWidth: 480, maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                Text("Preview")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LiveBlinkPreview(intensity: intensity, closedSeconds: exerciseClosedSeconds)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
            }
            .frame(minWidth: 220, idealWidth: 240)
        }
        .padding(12)
        .frame(minWidth: 740, minHeight: 520)
        .onAppear {
            showDockRelaunchNote = !DockIconManager.apply(showDockIcon: showDockIcon)
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func openSupportURL() {
        guard let url = URL(string: SUPPORT_URL) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct LiveBlinkPreview: View {
    let intensity: String
    let closedSeconds: Int

    @StateObject private var model = BlinkModel()
    @State private var loopTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black)

            EyesView(model: model)
        }
        .frame(width: 240, height: 120)
        .accessibilityLabel("Blink preview")
        .onAppear {
            loopTask?.cancel()
            loopTask = Task { @MainActor in
                while !Task.isCancelled {
                    await model.playPreview(holdSeconds: Double(closedSeconds))
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }
        }
        .onDisappear {
            loopTask?.cancel()
            loopTask = nil
        }
    }

}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .previewLayout(.sizeThatFits)
    }
}
#endif
