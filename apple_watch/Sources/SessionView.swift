import SwiftUI

struct SessionView: View {
    @StateObject private var c = SessionController()

    var body: some View {
        Group {
            if c.finished {
                VStack(spacing: 6) {
                    Text("🏆").font(.system(size: 40))
                    Text("Готово!").font(.headline)
                    Text("Отличная работа")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
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
                            .font(.system(size: 34, weight: .semibold))
                            .monospacedDigit()
                        Text("Цикл \(c.cycle + 1)/\(c.cycles) · \(c.currentBpm)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(6)
            }
        }
        .onAppear { c.start() }
        .onDisappear { c.stop() }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
