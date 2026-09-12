import Combine
import SwiftUI

struct DailyChallengeView: View {
    @Environment(AppModel.self) private var model
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let remaining = max(0, LevelCatalog.nextMidnight(after: now).timeIntervalSince(now))
        let daily = LevelCatalog.daily(on: now)
        let key = LevelCatalog.dayKey(now)
        let done = model.progress.lastDailyKey == key
        let best = model.progress.progress(for: daily.id)
        let seals = LevelCatalog.seals(for: daily.number)
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    IconCircle(system: "chevron.left") { model.goHome() }
                    Spacer()
                    Text("DAILY RIFT")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(2)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundStyle(EchoTheme.muted)
                        .frame(width: 40)
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text(clock(remaining))
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                }
                .foregroundStyle(EchoTheme.cyan)
                Text("New rift in")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)

                PanelCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(key)
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(EchoTheme.cyan)
                            Spacer()
                            if done {
                                Text("STABILIZED")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1.2)
                                    .foregroundStyle(EchoTheme.gold)
                            }
                        }
                        Text(daily.subtitle)
                            .font(.system(size: 16, weight: .semibold))
                        HStack(spacing: 8) {
                            ForEach(modifiers(for: daily), id: \.self) { item in
                                Text(item)
                                    .font(.system(size: 10, weight: .semibold))
                                    .tracking(0.8)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                            }
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("YOUR BEST")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(EchoTheme.muted)
                                Text(best.bestTime.map { String(format: "%.2fs", $0) } ?? "—")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("SEALS")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(EchoTheme.muted)
                                Text("\(best.stars)/3")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLEAR · complete")
                            Text("CONTROL · \(seals.control.label)")
                            Text("PARADOX · \(seals.paradox.label)")
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(EchoTheme.muted)
                    }
                }

                if done {
                    Text("First clear already paid out. A new layout arrives at midnight.")
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                } else {
                    Text("Points only on the first clear of the day.")
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                }

                Spacer()
                PrimaryButton(title: done ? "Enter again" : "Enter Rift") {
                    model.play(level: daily, daily: true)
                }
            }
            .padding(22)
        }
        .onReceive(timer) { now = $0 }
    }

    private func modifiers(for level: LevelDefinition) -> [String] {
        var items = ["\(level.maxEchoes) ECHOES"]
        if !level.rifts.isEmpty { items.append("RIFTS") }
        if !level.movers.isEmpty { items.append("MOVERS") }
        if !level.gates.isEmpty { items.append("GATES") }
        if !level.lasers.isEmpty { items.append("LASERS") }
        if items.count < 3 { items.append("SCARS PERSIST") }
        return Array(items.prefix(3))
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}
