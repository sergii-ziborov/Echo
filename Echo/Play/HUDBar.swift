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

            if hasActiveStatus {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        Text(Copy.text("hud.status"))
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.44))
                            .padding(.leading, 3)

                        if session.effects.shieldCharges > 0 {
                            HUDEffectBadge(
                                title: BonusKind.shield.fieldLabel,
                                icon: "shield.fill",
                                value: "×\(session.effects.shieldCharges)",
                                tint: .green,
                                accessibilityText: Copy.format("hud.a11y.shield", session.effects.shieldCharges)
                            )
                        }
                        if session.effects.isFrozen {
                            HUDEffectBadge(
                                title: BonusKind.freeze.fieldLabel,
                                icon: "snowflake",
                                value: seconds(session.effects.freezeRemaining),
                                tint: EchoTheme.cyan,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.freeze.title, seconds(session.effects.freezeRemaining))
                            )
                        }
                        if session.effects.isSurging {
                            HUDEffectBadge(
                                title: BonusKind.surge.fieldLabel,
                                icon: "hare.fill",
                                value: seconds(session.effects.surgeRemaining),
                                tint: EchoTheme.gold,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.surge.title, seconds(session.effects.surgeRemaining))
                            )
                        }
                        if session.effects.isMagnet {
                            HUDEffectBadge(
                                title: BonusKind.magnet.fieldLabel,
                                icon: "magnet.fill",
                                value: seconds(session.effects.magnetRemaining),
                                tint: EchoTheme.magenta,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.magnet.title, seconds(session.effects.magnetRemaining))
                            )
                        }
                        if session.effects.isPhasing {
                            HUDEffectBadge(
                                title: BonusKind.phase.fieldLabel,
                                icon: "sparkles",
                                value: seconds(session.effects.phaseRemaining),
                                tint: .white,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.phase.title, seconds(session.effects.phaseRemaining))
                            )
                        }
                        if session.effects.isAnchored {
                            HUDEffectBadge(
                                title: BonusKind.anchor.fieldLabel,
                                icon: "hourglass.bottomhalf.filled",
                                value: seconds(session.effects.anchorRemaining),
                                tint: EchoTheme.cyan,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.anchor.title, seconds(session.effects.anchorRemaining))
                            )
                        }
                        if session.effects.isPrismatic {
                            HUDEffectBadge(
                                title: BonusKind.prism.fieldLabel,
                                icon: "triangle.fill",
                                value: seconds(session.effects.prismRemaining),
                                tint: .green,
                                accessibilityText: Copy.format("hud.a11y.remaining", BonusKind.prism.title, seconds(session.effects.prismRemaining))
                            )
                        }
                        if session.resonanceChain >= 2 {
                            HUDEffectBadge(
                                icon: "link",
                                value: "×\(session.resonanceChain)",
                                tint: EchoTheme.gold,
                                progress: max(0, min(1, session.resonanceRemaining / session.sim.resonanceWindow)),
                                accessibilityText: Copy.format("hud.a11y.chain", session.resonanceChain)
                            )
                        }
                        if session.reality != .normal {
                            HUDEffectBadge(
                                icon: session.reality == .candy ? "birthday.cake.fill" : "arrow.left.and.right.righttriangle.left.righttriangle.right.fill",
                                value: seconds(session.realityRemaining),
                                tint: session.reality == .candy ? EchoTheme.magenta : EchoTheme.cyan,
                                accessibilityText: Copy.format("hud.a11y.remaining", Copy.text(session.reality == .candy ? "hud.a11y.candy" : "hud.a11y.mirror"), seconds(session.realityRemaining))
                            )
                        }
                    }
                    .padding(5)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: hasActiveStatus)
    }

    private var hasActiveStatus: Bool {
        session.effects.shieldCharges > 0
            || session.effects.isFrozen
            || session.effects.isSurging
            || session.effects.isMagnet
            || session.effects.isPhasing
            || session.effects.isAnchored
            || session.effects.isPrismatic
            || session.resonanceChain >= 2
            || session.reality != .normal
    }

    private func seconds(_ value: TimeInterval) -> String {
        Copy.format("unit.seconds", "\(max(1, Int(ceil(value))))")
    }
}
