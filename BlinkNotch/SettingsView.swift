import SwiftUI

private let SUPPORT_URL = "https://example.com/support"

struct SettingsView: View {
    @AppStorage(SettingsKeys.reminderFrequencyMinutes) private var reminderFrequencyMinutes: Int = 15
    @AppStorage(SettingsKeys.exerciseEnabled) private var exerciseEnabled: Bool = false
    @AppStorage(SettingsKeys.exerciseClosedSeconds) private var exerciseClosedSeconds: Int = 2
    @AppStorage(SettingsKeys.exerciseSoundEnabled) private var exerciseSoundEnabled: Bool = false
    @AppStorage(SettingsKeys.intensity) private var intensity: String = "subtle"
    @AppStorage(SettingsKeys.runAtLogin) private var runAtLogin: Bool = false
    @AppStorage(SettingsKeys.disableInFullscreen) private var disableInFullscreen: Bool = true
    @AppStorage(SettingsKeys.disableDuringScreenShare) private var disableDuringScreenShare: Bool = true
    @AppStorage(SettingsKeys.showDockIcon) private var showDockIcon: Bool = false

    @State private var showDockRelaunchNote = false

    var body: some View {
        Form {
            Section(header: Text("Timing").font(.headline)) {
                Picker("Reminder frequency", selection: $reminderFrequencyMinutes) {
                    Text("Every 10 minutes").tag(10)
                    Text("Every 15 minutes").tag(15)
                    Text("Every 20 minutes").tag(20)
                }
                .accessibilityLabel("Reminder frequency")

                Picker("Eye-closed duration", selection: $exerciseClosedSeconds) {
                    Text("1 second").tag(1)
                    Text("2 seconds").tag(2)
                    Text("3 seconds").tag(3)
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Eye-closed duration")

                Text("Longer closures can help express protective oil from the eyelids. No squeezing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Toggle("Play a soft sound when eyes close", isOn: $exerciseSoundEnabled)
                    .accessibilityLabel("Play a soft sound when eyes close")

                Text("Optional cue for longer eye closure. No alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Appearance").font(.headline)) {
                Picker("Intensity", selection: $intensity) {
                    Text("Subtle").tag("subtle")
                    Text("Standard").tag("standard")
                }
                .accessibilityLabel("Intensity")

                Text("Adjust how noticeable the blink feels in your peripheral vision.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                BlinkPreview(intensity: intensity)
                    .padding(.top, 6)
            }

            Section(header: Text("Behavior").font(.headline)) {
                Toggle("Run at login (not yet functional)", isOn: $runAtLogin)
                    .accessibilityLabel("Run at login")

                Toggle("Disable during full-screen apps", isOn: $disableInFullscreen)
                    .accessibilityLabel("Disable during full-screen apps")

                Toggle("Disable during screen sharing", isOn: $disableDuringScreenShare)
                    .accessibilityLabel("Disable during screen sharing")

                Toggle("Show Dock icon", isOn: $showDockIcon)
                    .accessibilityLabel("Show Dock icon")
                    .onChange(of: showDockIcon) { _, newValue in
                        showDockRelaunchNote = !DockIconManager.apply(showDockIcon: newValue)
                    }

                Text("Shows Blink in the Dock for quicker access to settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if showDockRelaunchNote {
                    HStack {
                        Text("May require relaunch")
                            .font(.caption)
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
        .padding(4)
        .frame(minWidth: 520, minHeight: 520)
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

private struct BlinkPreview: View {
    let intensity: String
    @State private var isBlinking = false

    private var blinkOpacity: Double {
        intensity == "standard" ? 0.85 : 0.45
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )

            HStack(spacing: 16) {
                Circle().fill(Color.primary.opacity(0.15))
                    .frame(width: 18, height: 18)
                Circle().fill(Color.primary.opacity(0.15))
                    .frame(width: 18, height: 18)
            }

            Rectangle()
                .fill(Color.primary.opacity(blinkOpacity))
                .frame(height: 20)
                .scaleEffect(y: isBlinking ? 1 : 0.05, anchor: .center)
                .opacity(isBlinking ? 1 : 0)
                .animation(.easeInOut(duration: 0.12), value: isBlinking)
        }
        .frame(width: 220, height: 60)
        .accessibilityLabel("Blink preview")
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                isBlinking = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    isBlinking = false
                }
            }
        }
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .frame(width: 520, height: 520)
    }
}
#endif
