import SwiftUI

struct ResultsView: View {
    var levelName: String
    var result: SessionResult
    var bestTime: TimeInterval?
    var bestMoves: Int?
    var onReplay: () -> Void
    var onNext: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(levelName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
                Text("COMPLETE")
                    .font(.system(size: 32, weight: .ultraLight))
                    .tracking(6)
                StarRow(filled: result.stars, size: 36)
                    .padding(.vertical, 4)

                VStack(spacing: 10) {
                    ResultLine(icon: "timer", title: "Time", value: format(result.time), best: bestTime.map(format))
                    ResultLine(icon: "arrow.triangle.swap", title: "Moves", value: "\(result.moves)", best: bestMoves.map(String.init))
                }

                HStack(spacing: 10) {
                    Image(systemName: "diamond.fill")
                        .foregroundStyle(EchoTheme.magenta)
                    Text("+1 Shard")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text("Collect 9 more for a reward")
                        .font(.system(size: 12))
                        .foregroundStyle(EchoTheme.muted)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))

                HStack(spacing: 12) {
                    SecondaryButton(title: "Replay", systemImage: "arrow.counterclockwise", action: onReplay)
                    PrimaryButton(title: "Next", systemImage: "play.fill", action: onNext)
                }

                Button("Main Menu", action: onMenu)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 24)
        }
    }

    private func format(_ time: TimeInterval) -> String {
        String(format: "%.2fs", time)
    }
}

private struct ResultLine: View {
    var icon: String
    var title: String
    var value: String
    var best: String?

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(EchoTheme.cyan)
                .frame(width: 22)
            Text(title)
                .foregroundStyle(EchoTheme.muted)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            if let best {
                Text("Best \(best)")
                    .font(.system(size: 12))
                    .foregroundStyle(EchoTheme.muted)
                    .frame(width: 92, alignment: .trailing)
            }
        }
        .font(.system(size: 15))
    }
}
