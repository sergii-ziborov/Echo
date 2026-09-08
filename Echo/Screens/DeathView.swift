import SwiftUI

struct DeathView: View {
    var cause: DeathCause
    var onRestart: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("COLLISION")
                    .font(.system(size: 28, weight: .ultraLight))
                    .tracking(6)
                Text(cause.headline)
                    .font(.system(size: 15))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Text("The replay showed the last seconds of your path meeting its copy. Instant restart — try a wider line.")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)

                PrimaryButton(title: "Restart", systemImage: "arrow.counterclockwise", action: onRestart)
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
