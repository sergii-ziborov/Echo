import SwiftUI

/// Home-screen entry for Deep Time, the endless mode: random arenas that
/// never repeat, each clear one depth deeper, and a crash with nothing left
/// to rewind ends the run.
struct EndlessCard: View {
    @Environment(AppModel.self) private var model
    let appeared: Bool
    let reduceMotion: Bool

    private var record: EndlessRecord { model.progress.endless }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("ENDLESS", systemImage: "infinity")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(EchoTheme.magenta)
                Spacer()
                Text(record.bestDepth > 0 ? "BEST DEPTH \(record.bestDepth)" : "NEW MODE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(EchoTheme.muted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Deep Time")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Random arenas that never repeat. Every clear goes one depth deeper, with more rocks, beams and echoes. A crash you cannot rewind ends the run.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                PrimaryButton(title: "New run", systemImage: "infinity") {
                    model.playEndless()
                }
                if let current = record.current, current.depth > 1 {
                    SecondaryButton(title: "Depth \(current.depth)", systemImage: "arrow.right") {
                        model.playEndless(resume: true)
                    }
                }
            }

            if record.runs > 0 {
                Text("\(record.runs) \(record.runs == 1 ? "RUN" : "RUNS") · \(record.depthsCleared) \(record.depthsCleared == 1 ? "DEPTH" : "DEPTHS") CLEARED")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(EchoTheme.muted)
            }
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.97), EchoTheme.magenta.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [EchoTheme.magenta.opacity(0.36), Color.white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
    }
}
