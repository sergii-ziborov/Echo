import SwiftUI

struct DeathView: View {
    var cause: DeathCause
    var rewindCharges: Int
    var rewindSeconds: TimeInterval = 3
    var onRewind: () -> Void
    var onRestart: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("TIMELINE BROKEN")
                    .font(.system(size: 22, weight: .ultraLight))
                    .tracking(4)
                Text(cause.headline)
                    .font(.system(size: 15))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                if rewindCharges > 0 {
                    Text("The failed branch stays as an unstable echo.")
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                        .multilineTextAlignment(.center)
                    PrimaryButton(
                        title: String(format: "REWIND %.1fs", rewindSeconds),
                        systemImage: "clock.arrow.circlepath",
                        action: onRewind
                    )
                    GhostButton(title: "Restart", action: onRestart)
                } else {
                    Text("No rewind left on this timeline.")
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                    PrimaryButton(title: "Restart", systemImage: "arrow.counterclockwise", action: onRestart)
                }
                GhostButton(title: "Main Menu", action: onMenu)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(EchoTheme.danger.opacity(0.25), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }
}
