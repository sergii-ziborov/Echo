import Combine
import SwiftUI

struct DailyChallengeView: View {
    @Environment(AppModel.self) private var model
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let remaining = max(0, LevelCatalog.nextMidnight(after: now).timeIntervalSince(now))
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    IconCircle(system: "chevron.left") { model.goHome() }
                    Spacer()
                    Text("DAILY CHALLENGE")
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
                Text("New challenge in")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)

                PanelCard {
                    VStack(alignment: .leading, spacing: 12) {
                        EchoMark(size: 140, spinning: true)
                            .frame(maxWidth: .infinity)
                        Text("Complete the challenge to earn a special reward!")
                            .font(.system(size: 15))
                            .foregroundStyle(EchoTheme.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack {
                    Label("50", systemImage: "star.fill")
                        .foregroundStyle(EchoTheme.gold)
                    Spacer()
                    Label("1", systemImage: "diamond.fill")
                        .foregroundStyle(EchoTheme.magenta)
                }
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 8)

                if model.progress.lastDailyKey == LevelCatalog.dayKey(now) {
                    Text("Already completed today. A new layout arrives at midnight.")
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                }

                Spacer()
                PrimaryButton(title: "Play Challenge") {
                    model.play(level: LevelCatalog.daily(on: now), daily: true)
                }
            }
            .padding(22)
        }
        .onReceive(timer) { now = $0 }
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}
