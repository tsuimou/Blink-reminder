import SwiftUI
import Combine

@MainActor
final class BlinkModel: ObservableObject {
    enum BlinkState {
        case idle
        case aware
        case closing
        case closed
        case opening
        case settling
    }

    // MARK: - Tweakable Story Timing
    
    // PHASE 1: Arrival BLink 3 times
    let arrivalBlinkCount = 3
    let arrivalFirstCloseDuration: Double = 0.2
    let arrivalFirstOpenDuration: Double = 0.25
    let arrivalOtherCloseDuration: Double = 0.1
    let arrivalOtherOpenDuration: Double = 0.15
    let arrivalPauseAfterBlink: Double = 0.3
    
    // PHASE 2: Eye Sore
    let soreTransitionDuration: Double = 0.5
    let soreHoldSeconds: Double = 1.5

    // PHASE 3: Excercise
    let exerciseBlinkCount = 3
    let exerciseCloseDuration: Double = 1.5
    let exerciseHoldClosedSeconds: Double = 2.0
    let exerciseOpenDuration: Double = 1.0
    
    @Published var state: BlinkState = .idle
    /// 0 = open, 1 = sore, 2 = closed (morphs between)
    @Published var eyeMorph: CGFloat = 0.0
    /// True only during the sore phase
    @Published var isSoreActive: Bool = false
    /// 0 = open, 1 = sore (used only for Phase 2)
    @Published var soreMorph: CGFloat = 0.0
    @Published var opacity: CGFloat = 0.0
    
    @Published var islandScale: CGFloat = 0.88
    @Published var islandOffsetY: CGFloat = -10

    var blinkTotalDuration: Double {
        0.9
        + (arrivalFirstCloseDuration + arrivalFirstOpenDuration)
        + (Double(max(0, arrivalBlinkCount - 1)) * (arrivalOtherCloseDuration + arrivalOtherOpenDuration))
        + arrivalPauseAfterBlink
        + soreTransitionDuration
        + soreHoldSeconds
        + (Double(exerciseBlinkCount) * (exerciseCloseDuration + exerciseHoldClosedSeconds + exerciseOpenDuration))
        + 0.35
    }

    func playOnce() async {
        // Appear from the notch: island rises in, eyes already open
        state = .aware
        eyeMorph = 0.0
        islandScale = 0.88
        islandOffsetY = -10
        opacity = 0.0
        withAnimation(.easeOut(duration: 0.9)) {
            opacity = 1.0
            islandScale = 1.0
            islandOffsetY = 0
        }
        await sleepSeconds(0.9)

        // Arrival: natural blink(s)
        for i in 0..<arrivalBlinkCount {
            let closeDuration = (i == 0) ? arrivalFirstCloseDuration : arrivalOtherCloseDuration
            let openDuration = (i == 0) ? arrivalFirstOpenDuration : arrivalOtherOpenDuration
            state = .closing
            withAnimation(.easeInOut(duration: closeDuration)) {
                eyeMorph = 2.0
            }
            await sleepSeconds(closeDuration)

            state = .opening
            withAnimation(.easeInOut(duration: openDuration)) {
                eyeMorph = 0.0
            }
            await sleepSeconds(openDuration)
        }
        await sleepSeconds(arrivalPauseAfterBlink)

        // Sore eyes: Open -> Sore -> Open (true shape morph)
        isSoreActive = true
        soreMorph = 0.0
        withAnimation(.easeInOut(duration: soreTransitionDuration)) {
            soreMorph = 1.0
        }
        await sleepSeconds(soreHoldSeconds)
        withAnimation(.easeInOut(duration: 0.35)) {
            soreMorph = 0.0
        }
        await sleepSeconds(0.35)
        isSoreActive = false

        // Exercise blinks (open → close → hold → open), repeated
        for _ in 0..<exerciseBlinkCount {
            state = .closing
            withAnimation(.easeInOut(duration: exerciseCloseDuration)) {
                eyeMorph = 2.0
            }
            await sleepSeconds(exerciseCloseDuration)

            state = .closed
            await sleepSeconds(exerciseHoldClosedSeconds)

            state = .opening
            withAnimation(.easeInOut(duration: exerciseOpenDuration)) {
                eyeMorph = 0.0
            }
            await sleepSeconds(exerciseOpenDuration)
        }

        // End without moving up
        state = .settling
        islandOffsetY = 0

        state = .idle
    }

    private func sleepSeconds(_ seconds: Double) async {
        let nanos = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanos)
    }
}
