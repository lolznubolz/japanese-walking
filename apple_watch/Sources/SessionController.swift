import SwiftUI
import WatchKit

enum Phase {
    case fast, slow
}

/// IWT session state machine for the watch: fast/slow phases, haptic
/// metronome (one tap per step) and phase-change haptics.
final class SessionController: ObservableObject {
    @Published var phase: Phase = .fast
    @Published var cycle = 0
    @Published var remaining = 180
    @Published var finished = false

    let phaseSeconds = 180
    let cycles = 5
    let fastBpm = 135
    let slowBpm = 100

    private var timer: Timer?
    private var metro: Timer?

    let age = 40

    var currentBpm: Int { phase == .fast ? fastBpm : slowBpm }
    var progress: Double {
        1.0 - Double(remaining) / Double(phaseSeconds)
    }

    /// Max HR by the Tanaka formula.
    var hrMax: Int { Int((208.0 - 0.7 * Double(age)).rounded()) }

    /// Target HR zone for the current phase (fast 70–80%, slow 50–65%).
    var zone: (lo: Int, hi: Int) {
        phase == .fast
            ? (Int(Double(hrMax) * 0.70), Int(Double(hrMax) * 0.80))
            : (Int(Double(hrMax) * 0.50), Int(Double(hrMax) * 0.65))
    }

    func start() {
        announce()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        startMetronome()
    }

    private func tick() {
        guard !finished else { return }
        remaining -= 1
        if remaining <= 0 { nextPhase() }
    }

    private func nextPhase() {
        if phase == .fast {
            phase = .slow
        } else {
            phase = .fast
            cycle += 1
            if cycle >= cycles {
                finish()
                return
            }
        }
        remaining = phaseSeconds
        startMetronome()
        announce()
    }

    private func announce() {
        // Distinct haptic per direction.
        WKInterfaceDevice.current().play(phase == .fast ? .start : .stop)
    }

    private func startMetronome() {
        metro?.invalidate()
        let interval = 60.0 / Double(currentBpm)
        metro = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func finish() {
        finished = true
        timer?.invalidate()
        metro?.invalidate()
        WKInterfaceDevice.current().play(.success)
    }

    func stop() {
        timer?.invalidate()
        metro?.invalidate()
    }
}
