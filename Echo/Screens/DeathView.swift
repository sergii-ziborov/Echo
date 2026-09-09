import SwiftUI

struct DeathView: View {
    var cause: DeathCause
    var lives: Int
    var onContinue: () -> Void
    var onShop: () -> Void
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

                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(lives > 0 ? EchoTheme.danger : EchoTheme.muted)
                    Text("\(lives) life\(lives == 1 ? "" : "s")")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }

                Text(lives > 0
                     ? "Spend a life to try this arena again."
                     : "No lives left. Buy more in the shop, or leave to the menu.")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)

                if lives > 0 {
                    PrimaryButton(title: "Continue", systemImage: "heart.fill", action: onContinue)
                } else {
                    PrimaryButton(title: "Shop", systemImage: "bag.fill", action: onShop)
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
