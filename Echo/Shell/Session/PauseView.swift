import SwiftUI

struct PauseView: View {
    var levelName: String
    var rewindCharges: Int
    var onResume: () -> Void
    var onRestart: () -> Void
    var onShop: () -> Void
    var onSettings: () -> Void
    var onMenu: () -> Void
    /// Where on the Fold Road the map lies, and what the Signal found there.
    var place: String?
    var log: String?

    var body: some View {
        GameModalShell(tint: EchoTheme.cyan) {
            VStack(spacing: 17) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(EchoTheme.cyan)
                    .frame(width: 66, height: 66)
                    .background(EchoTheme.cyan.opacity(0.13), in: Circle())
                    .overlay(Circle().stroke(EchoTheme.cyan.opacity(0.44), lineWidth: 1))

                VStack(spacing: 5) {
                    Text(Copy.text("pause.eyebrow"))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(2.3)
                        .foregroundStyle(EchoTheme.cyan)
                    Text(Copy.text("pause.title"))
                        .font(.system(size: 30, weight: .ultraLight))
                        .tracking(5)
                    Text(levelName)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if let place {
                        Text(place.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.4)
                            .foregroundStyle(EchoTheme.cyan.opacity(0.85))
                            .padding(.top, 4)
                    }
                    if let log {
                        Text(log)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.62))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(EchoTheme.cyan)
                    Text(Copy.format("pause.rewinds", rewindCharges))
                        .foregroundStyle(.white)
                }
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 39)
                .background(EchoTheme.cyan.opacity(0.10), in: Capsule())

                VStack(spacing: 10) {
                    PrimaryButton(title: Copy.text("button.resume"), systemImage: "play.fill", action: onResume)

                    HStack(spacing: 10) {
                        SecondaryButton(title: Copy.text("button.restart"), systemImage: "arrow.counterclockwise", action: onRestart)
                        SecondaryButton(title: Copy.text("button.settings"), systemImage: "gearshape", action: onSettings)
                    }

                    SecondaryButton(title: Copy.text("button.lab"), systemImage: "hexagon.fill", action: onShop)
                    GhostButton(title: Copy.text("button.menu"), action: onMenu)
                }
            }
            .foregroundStyle(.white)
        }
    }
}
