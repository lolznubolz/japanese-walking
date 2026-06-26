import SwiftUI

struct SessionView: View {
    @StateObject private var c = SessionController()
    @StateObject private var hr = HeartRateManager()

    var body: some View {
        Group {
            if c.finished {
                VStack(spacing: 6) {
                    Text("🏆").font(.system(size: 40))
                    Text("Готово!").font(.headline)
                    if hr.bpm > 0 {
                        Text("♥ ср. \(hr.bpm)")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: c.progress)
                        .stroke(
                            c.phase == .fast ? Color.orange : Color.teal,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.3), value: c.progress)
                    VStack(spacing: 1) {
                        Text(c.phase == .fast ? "БЫСТРО" : "СПОКОЙНО")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(c.phase == .fast ? .orange : .teal)
                        Text(timeString(c.remaining))
                            .font(.system(size: 32, weight: .semibold))
                            .monospacedDigit()
                        if hr.bpm > 0 {
                            Text("♥ \(hr.bpm)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.red)
                            Text("зона \(c.zone.lo)–\(c.zone.hi)")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Цикл \(c.cycle + 1)/\(c.cycles) · \(c.currentBpm)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(6)
            }
        }
        .onAppear {
            c.start()
            hr.requestAndStart()
        }
        .onDisappear {
            c.stop()
            hr.stop()
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
