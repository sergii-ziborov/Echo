import SwiftUI

struct HUDBar: View {
    var session: GameSession
    var onPause: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                HUDChip(icon: "sparkle", tint: EchoTheme.cyan) {
                    Text("\(session.sparksCollected)/\(session.sparksTotal)")
                }
                .accessibilityLabel(Copy.format("hud.a11y.sparks", session.sparksCollected, session.sparksTotal))

                HUDChip(icon: "circle.dotted", tint: EchoTheme.magenta) {
                    Text("\(session.echoCount)/\(session.maxEchoes)")
                }
                .accessibilityLabel(Copy.format("hud.a11y.echoes", session.echoCount, session.maxEchoes))

                HUDChip(icon: "clock.arrow.circlepath", tint: EchoTheme.cyan) {
                    Text("\(session.sim.rewindCharges)")
                }
                .accessibilityLabel(Copy.format("hud.a11y.rewinds", session.sim.rewindCharges))

                if PhoneWatchLink.shared.isSteering {
                    HUDChip(icon: "applewatch", tint: EchoTheme.gold) {
                        Text(Copy.text("hud.watch"))
                    }
                    .accessibilityLabel(Copy.text("hud.a11y.watch"))
                }

                Spacer(minLength: 4)

                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Copy.text("hud.a11y.pause"))
            }
        }
    }
}
