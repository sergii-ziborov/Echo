import SwiftUI

/// Keep the recovery pass readable even when Russian words and large balances
/// cannot share one row. A second row is preferable to splitting a word.
struct HomeTopBar: View {
    @Environment(AppModel.self) private var model
    let reduceMotion: Bool

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                settings
                signalStatus
                Spacer(minLength: 6)
                balances
            }
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 10) {
                    settings
                    signalStatus
                    Spacer(minLength: 0)
                }
                balances.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var settings: some View {
        IconCircle(system: "gearshape") { model.openSettings() }
    }

    private var signalStatus: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.progress.difficulty.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.5)
                .lineLimit(1)
                .accessibilityIdentifier("home.recoveryPass")
            HStack(spacing: 5) {
                HomePulseDot(tint: .green, reduceMotion: reduceMotion)
                Text(Copy.text("home.online"))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .lineLimit(1)
                    .foregroundStyle(EchoTheme.cyan)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var balances: some View {
        HStack(spacing: 8) {
            ResourcePill(value: model.progress.totalStars, systemImage: "checkmark.seal.fill", tint: EchoTheme.gold)
            ResourcePill(value: model.progress.points, systemImage: "diamond.fill", tint: EchoTheme.magenta)
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
