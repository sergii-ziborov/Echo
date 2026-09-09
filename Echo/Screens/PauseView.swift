import SwiftUI

struct PauseView: View {
    var levelName: String
    var rewindCharges: Int
    var onResume: () -> Void
    var onRestart: () -> Void
    var onShop: () -> Void
    var onSettings: () -> Void
    var onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(levelName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
                Text("PAUSED")
                    .font(.system(size: 36, weight: .ultraLight))
                    .tracking(8)
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(EchoTheme.cyan)
                    Text("\(rewindCharges) rewind")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .padding(.bottom, 4)

                PrimaryButton(title: "Resume", systemImage: "play.fill", action: onResume)
                SecondaryButton(title: "Restart", systemImage: "arrow.counterclockwise", action: onRestart)
                SecondaryButton(title: "Shop", systemImage: "bag.fill", action: onShop)
                SecondaryButton(title: "Settings", systemImage: "gearshape", action: onSettings)
                GhostButton(title: "Main Menu", action: onMenu)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }
}
