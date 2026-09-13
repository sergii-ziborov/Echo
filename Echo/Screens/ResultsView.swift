import SwiftUI

struct ResultsView: View {
    var levelName: String
    var result: SessionResult
    var controlSeal: SealKind
    var paradoxSeal: SealKind
    var bestTime: TimeInterval?
    var bestMoves: Int?
    var cycleComplete: Bool
    var nextDifficulty: DifficultyProfile
    var onWatch: () -> Void
    var onNext: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GameModalShell(tint: EchoTheme.gold) {
            VStack(spacing: 15) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(EchoTheme.gold)
                    .frame(width: 70, height: 70)
                    .background(EchoTheme.gold.opacity(0.13), in: Circle())
                    .overlay(Circle().stroke(EchoTheme.gold.opacity(0.45), lineWidth: 1))

                VStack(spacing: 4) {
                    Text("EPOCH STABILIZED")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(EchoTheme.gold)
                    Text("STABLE TIMELINE")
                        .font(.system(size: 25, weight: .ultraLight))
                        .tracking(3)
                        .multilineTextAlignment(.center)
                    Text(levelName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CLEAR TIME")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(EchoTheme.cyan)
                        Text(format(result.time))
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                        if let bestTime {
                            Text("BEST \(format(bestTime))")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(EchoTheme.muted)
                        }
                    }
                    Spacer(minLength: 0)
                    VStack(spacing: 4) {
                        HStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { index in
                                Image(systemName: index < result.stars ? "checkmark.seal.fill" : "seal")
                                    .foregroundStyle(index < result.stars ? EchoTheme.gold : EchoTheme.muted)
                            }
                        }
                        .font(.system(size: 18))
                        Text("\(result.stars)/3 SEALS")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(EchoTheme.gold)
                    }
                }
                .padding(15)
                .background(EchoTheme.cyan.opacity(0.08), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

                if cycleComplete {
                    HStack(spacing: 9) {
                        Image(systemName: "infinity.circle.fill")
                            .foregroundStyle(EchoTheme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("77 EPOCHS COMPLETE")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Next: \(nextDifficulty.shortTitle) · +777 research points")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(EchoTheme.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .background(EchoTheme.gold.opacity(0.09), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ResultMetric(icon: "arrow.triangle.branch", title: "MOVES", value: "\(result.moves)", detail: bestMoves.map { "BEST \($0)" })
                    ResultMetric(icon: "circle.dotted", title: "ECHOES", value: "\(result.echoesFaced)", detail: nil)
                    ResultMetric(icon: "waveform.path.ecg", title: "CLOSEST", value: result.closest.isFinite ? String(format: "%.2f", result.closest) : "—", detail: nil)
                    ResultMetric(icon: "bolt.horizontal", title: "SCARS", value: "\(result.scars)", detail: nil)
                }

                VStack(spacing: 0) {
                    ResultSealRow(title: "CLEAR", detail: "Complete", met: true)
                    Divider().overlay(Color.white.opacity(0.08))
                    ResultSealRow(title: "CONTROL", detail: controlSeal.label, met: result.control)
                    Divider().overlay(Color.white.opacity(0.08))
                    ResultSealRow(title: "PARADOX", detail: paradoxSeal.label, met: result.paradox)
                }
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 9) {
                    Image(systemName: "diamond.fill")
                        .foregroundStyle(EchoTheme.magenta)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("+\(result.points) RESEARCH POINTS")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(rewardDetail)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                    }
                    Spacer(minLength: 0)
                }
                .padding(13)
                .background(EchoTheme.magenta.opacity(0.10), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

                HStack(spacing: 10) {
                    SecondaryButton(title: "Watch", systemImage: "play.fill", action: onWatch)
                    PrimaryButton(title: "Next", systemImage: "arrow.right", action: onNext)
                }
                GhostButton(title: "Main Menu", action: onMenu)
            }
            .foregroundStyle(.white)
        }
    }

    private var rewardDetail: String {
        var parts = ["\(result.stars) seals"]
        if result.timeCrystals > 0 { parts.append("\(result.timeCrystals) crystals") }
        if result.resonance >= 2 { parts.append("×\(result.resonance) resonance") }
        return parts.joined(separator: " · ")
    }

    private func format(_ time: TimeInterval) -> String {
        String(format: "%.2fs", time)
    }
}

private struct ResultMetric: View {
    var icon: String
    var title: String
    var value: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(title, systemImage: icon)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(EchoTheme.cyan)
            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            if let detail {
                Text(detail)
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 61, alignment: .leading)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ResultSealRow: View {
    var title: String
    var detail: String
    var met: Bool

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(met ? EchoTheme.gold : EchoTheme.muted)
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.9)
            Spacer(minLength: 6)
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(EchoTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(height: 38)
    }
}
