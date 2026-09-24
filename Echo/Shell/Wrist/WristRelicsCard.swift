import SwiftUI

/// Home-screen card for the Apple Watch campaign: how far the wrist timeline
/// has come and which relics it has unlocked in the iPhone game.
struct WristRelicsCard: View {
    @Environment(AppModel.self) private var model
    let appeared: Bool
    let reduceMotion: Bool

    private var wrist: WristProgress { model.progress.wrist }
    private var cleared: Int { wrist.cleared.count }
    private var total: Int { WristCatalog.maps.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("APPLE WATCH", systemImage: "applewatch")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(EchoTheme.gold)
                Spacer()
                Text("\(cleared)/\(total) WRIST MAPS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(EchoTheme.muted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Wrist Timeline")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(status)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HomeProgressBar(
                value: Double(cleared) / Double(max(total, 1)),
                tint: EchoTheme.gold,
                animate: appeared,
                reduceMotion: reduceMotion
            )

            VStack(spacing: 9) {
                ForEach(WristRelic.allCases) { relic in
                    relicRow(relic)
                }
            }
        }
        .padding(17)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.97), EchoTheme.gold.opacity(0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [EchoTheme.gold.opacity(0.34), Color.white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .contain)
    }

    private var status: String {
        let link = PhoneWatchLink.shared
        if !link.isPaired {
            return "Pair an Apple Watch to play twelve wrist maps. Every new clear pays \(WristProgress.shardsPerMap) research points here."
        }
        if !link.isWatchAppInstalled {
            return "Install ECHO on your Apple Watch from the Watch app to open the wrist timeline."
        }
        return "Every new wrist clear pays \(WristProgress.shardsPerMap) research points. Open Remote on the watch to steer this orb from your wrist."
    }

    private func relicRow(_ relic: WristRelic) -> some View {
        let unlocked = wrist.isUnlocked(relic)
        return HStack(spacing: 12) {
            Image(systemName: relic.symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(unlocked ? EchoTheme.navyDeep : EchoTheme.gold)
                .frame(width: 36, height: 36)
                .background(unlocked ? EchoTheme.gold : EchoTheme.gold.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(EchoTheme.gold.opacity(unlocked ? 0 : 0.35), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text(relic.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(relic.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            if relic == .tourbillonTail, unlocked {
                Toggle("Tourbillon Tail", isOn: Binding(
                    get: { model.progress.wristTrailEnabled },
                    set: { model.progress.setWristTrail($0) }
                ))
                .labelsHidden()
                .tint(EchoTheme.gold)
            } else {
                Text(unlocked ? "ACTIVE" : "\(relic.requiredClears) MAPS")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(unlocked ? EchoTheme.gold : EchoTheme.muted)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(unlocked ? 0.10 : 0.05), in: Capsule())
            }
        }
        .opacity(unlocked ? 1 : 0.72)
        .accessibilityElement(children: .combine)
    }
}
