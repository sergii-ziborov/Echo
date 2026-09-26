import SwiftUI

struct DeathView: View {
    var cause: DeathCause
    var rewindCharges: Int
    var rewindSeconds: TimeInterval = 3
    var onRewind: () -> Void
    var onRestart: () -> Void
    var onMenu: () -> Void
    /// Deep Time ends the run instead of restarting the map.
    var restartTitle = Copy.text("button.restartMap")
    var note: String?

    var body: some View {
        GameModalShell(tint: EchoTheme.danger) {
            VStack(spacing: 16) {
                Image(systemName: causeIcon)
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(EchoTheme.danger)
                    .frame(width: 66, height: 66)
                    .background(EchoTheme.danger.opacity(0.13), in: Circle())
                    .overlay(Circle().stroke(EchoTheme.danger.opacity(0.42), lineWidth: 1))

                VStack(spacing: 5) {
                    Text(Copy.text("death.eyebrow"))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(2.0)
                        .foregroundStyle(EchoTheme.danger)
                    Text(Copy.text("death.title"))
                        .font(.system(size: 23, weight: .ultraLight))
                        .tracking(2.7)
                        .multilineTextAlignment(.center)
                    if let note {
                        Text(note)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text(Copy.text("death.reason"))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(EchoTheme.danger)
                    Text(cause.headline)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(recoveryTip)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(EchoTheme.danger.opacity(0.09), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(EchoTheme.danger.opacity(0.18), lineWidth: 1))

                VStack(spacing: 10) {
                    if rewindCharges > 0 {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(EchoTheme.cyan)
                            Text(Copy.format("death.rewindsLeft", rewindCharges))
                                .foregroundStyle(.white)
                            Spacer()
                            Text(Copy.format("death.rewindDepth", Copy.seconds(rewindSeconds)))
                                .foregroundStyle(EchoTheme.cyan)
                        }
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(0.7)
                        .padding(12)
                        .background(EchoTheme.cyan.opacity(0.09), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                        PrimaryButton(
                            title: Copy.format("death.rewindButton", Copy.seconds(rewindSeconds)),
                            systemImage: "clock.arrow.circlepath",
                            action: onRewind
                        )
                        SecondaryButton(title: restartTitle, systemImage: "arrow.counterclockwise", action: onRestart)
                    } else {
                        Text(Copy.text("death.noRewind"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                        PrimaryButton(title: restartTitle, systemImage: "arrow.counterclockwise", action: onRestart)
                    }
                    GhostButton(title: Copy.text("button.menu"), action: onMenu)
                }
            }
            .foregroundStyle(.white)
        }
    }

    private var causeIcon: String {
        switch cause {
        case .echo, .ghost: "person.crop.circle.badge.xmark"
        case .asteroid: "asterisk"
        case .rift, .blackHole: "hurricane"
        case .collision: "bolt.horizontal.fill"
        case .laser: "laser.burst"
        }
    }

    /// Each cause has its own advice; a rift and a field well are not the same danger.
    private var recoveryTip: String { cause.tip }
}
