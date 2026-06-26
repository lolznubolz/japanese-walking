import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                Text("🚶")
                    .font(.system(size: 30))
                Text("WalkBeat")
                    .font(.headline)
                Text("3 мин быстро · 3 мин спокойно")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                NavigationLink {
                    SessionView()
                } label: {
                    Text("Старт")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .padding(.top, 4)
            }
            .padding(.horizontal, 6)
        }
    }
}

#Preview {
    ContentView()
}
