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
            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        countdownCard(remaining)
                        challengeCard(
                            daily: daily,
                            key: key,
                            done: done,
                            best: best,
                            control: seals.control,
                            paradox: seals.paradox
                        )
                        payoutBanner(done: done)
                    }
                    .padding(.bottom, 8)
                }

                PrimaryButton(title: done ? "Enter again" : "Enter Rift") {
                    model.play(level: daily, daily: true)
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .onReceive(timer) { now = $0 }
    }

    private var header: some View {
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") {
                model.audio.play(.tap)
                model.goHome()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("DAILY RIFT")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.5)
                Text("ONE SHARED TIMELINE · ONE REWARD")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(EchoTheme.gold)
                .frame(width: 38, height: 38)
                .background(EchoTheme.gold.opacity(0.10), in: Circle())
                .overlay(Circle().stroke(EchoTheme.gold.opacity(0.18), lineWidth: 1))
        }
    }

    private func countdownCard(_ remaining: TimeInterval) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(EchoTheme.cyan.opacity(0.12))
                    .frame(width: 56, height: 56)
                Circle()
                    .stroke(EchoTheme.cyan.opacity(0.28), lineWidth: 1)
                    .frame(width: 43, height: 43)
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(EchoTheme.cyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("NEXT RIFT IN")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(EchoTheme.muted)
                Text(clock(remaining))
                    .font(.system(size: 25, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("RESETS")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(EchoTheme.gold)
                Text("AT MIDNIGHT")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [EchoTheme.cyan.opacity(0.11), EchoTheme.panel.opacity(0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(EchoTheme.cyan.opacity(0.20), lineWidth: 1))
    }

    private func challengeCard(
        daily: LevelDefinition,
        key: String,
        done: Bool,
        best: LevelProgress,
        control: SealKind,
        paradox: SealKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("RIFT \(key)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(EchoTheme.cyan)
                    Text("EPOCH \(String(format: "%02d", daily.number)) · \(daily.name)")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer()

                Text(done ? "STABILIZED" : "LIVE")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(done ? EchoTheme.gold : .green)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background((done ? EchoTheme.gold : Color.green).opacity(0.10), in: Capsule())
            }

            Text(daily.subtitle)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(modifiers(for: daily), id: \.self) { item in
                    Text(item)
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.76))
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(Color.white.opacity(0.07), in: Capsule())
                }
            }

            HStack(spacing: 8) {
                DailyMetric(title: "YOUR BEST", value: best.bestTime.map { String(format: "%.2fs", $0) } ?? "—", tint: EchoTheme.cyan)
                DailyMetric(title: "SEALS", value: "\(best.stars)/3", tint: EchoTheme.gold)
            }

            VStack(spacing: 0) {
                DailyObjective(icon: "checkmark.seal.fill", title: "CLEAR", detail: "Complete the rift", tint: .green)
                objectiveDivider
                DailyObjective(icon: "scope", title: "CONTROL", detail: control.label, tint: EchoTheme.cyan)
                objectiveDivider
                DailyObjective(icon: "circle.dotted", title: "PARADOX", detail: paradox.label, tint: EchoTheme.magenta)
            }
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(16)
        .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(EchoTheme.cyan.opacity(0.17), lineWidth: 1))
    }

    private var objectiveDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.055))
            .frame(height: 1)
            .padding(.leading, 42)
    }

    private func payoutBanner(done: Bool) -> some View {
        HStack(spacing: 11) {
            Image(systemName: done ? "checkmark.seal.fill" : "diamond.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(done ? EchoTheme.gold : EchoTheme.magenta)
                .frame(width: 36, height: 36)
                .background((done ? EchoTheme.gold : EchoTheme.magenta).opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(done ? "TODAY'S REWARD CLAIMED" : "FIRST CLEAR PAYS OUT")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(0.9)
                Text(done ? "A new layout arrives at midnight." : "Replay freely; fragments are awarded once today.")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer(minLength: 0)
        }
        .padding(13)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

private struct DailyMetric: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(EchoTheme.muted)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .frame(height: 58)
        .background(tint.opacity(0.075), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct DailyObjective: View {
    let icon: String
    let title: String
    let detail: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(tint)
                .frame(width: 60, alignment: .leading)
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .frame(height: 45)
    }
}
