import SwiftUI

struct ResultsView: View {
    var levelName: String
    var result: SessionResult
    var controlSeal: SealKind
    var paradoxSeal: SealKind
    var bestTime: TimeInterval?
    var bestMoves: Int?
    var onWatch: () -> Void
    var onNext: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(levelName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
                Text("STABLE TIMELINE")
                    .font(.system(size: 26, weight: .ultraLight))
                    .tracking(4)

                VStack(spacing: 8) {
                    ResultLine(icon: "timer", title: "Time", value: format(result.time), best: bestTime.map(format))
                    ResultLine(icon: "circle.dotted", title: "Echoes survived", value: "\(result.echoesFaced)", best: nil)
                    ResultLine(
                        icon: "waveform.path.ecg",
                        title: "Closest paradox",
                        value: result.closest.isFinite ? String(format: "%.2f", result.closest) : "—",
                        best: nil
                    )
                    ResultLine(icon: "bolt.horizontal", title: "Scars created", value: "\(result.scars)", best: nil)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SealRow(title: "CLEAR", detail: "Complete", met: true)
                    SealRow(title: "CONTROL", detail: controlSeal.label, met: result.control)
                    SealRow(title: "PARADOX", detail: paradoxSeal.label, met: result.paradox)
                }

                HStack(spacing: 10) {
                    Image(systemName: "diamond.fill")
                        .foregroundStyle(EchoTheme.magenta)
                    Text("+\(result.points) points")
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Text(format(result.time))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(EchoTheme.muted)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))

                HStack(spacing: 12) {
                    SecondaryButton(title: "Watch", systemImage: "play.fill", action: onWatch)
                    PrimaryButton(title: "Next", systemImage: "arrow.right", action: onNext)
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

private struct SealRow: View {
    var title: String
    var detail: String
    var met: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? EchoTheme.cyan : EchoTheme.muted)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.2)
            Spacer()
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(EchoTheme.muted)
        }
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
