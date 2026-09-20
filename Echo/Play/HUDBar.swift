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
                .accessibilityLabel("Sparks \(session.sparksCollected) of \(session.sparksTotal)")

                HUDChip(icon: "circle.dotted", tint: EchoTheme.magenta) {
                    Text("\(session.echoCount)/\(session.maxEchoes)")
                }
                .accessibilityLabel("Echoes \(session.echoCount) of \(session.maxEchoes)")

                HUDChip(icon: "clock.arrow.circlepath", tint: EchoTheme.cyan) {
                    Text("\(session.sim.rewindCharges)")
                }
                .accessibilityLabel("\(session.sim.rewindCharges) rewind charges")

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
                .accessibilityLabel("Pause")
            }

            if hasActiveStatus {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        Text("STATUS")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.44))
                            .padding(.leading, 3)

                        if session.effects.shieldCharges > 0 {
                            HUDEffectBadge(
                                title: "SHIELD",
                                icon: "shield.fill",
                                value: "×\(session.effects.shieldCharges)",
                                tint: .green,
                                accessibilityText: "Shield, \(session.effects.shieldCharges) charges"
                            )
                        }
                        if session.effects.isFrozen {
                            HUDEffectBadge(
                                title: "FREEZE",
                                icon: "snowflake",
                                value: seconds(session.effects.freezeRemaining),
                                tint: EchoTheme.cyan,
                                accessibilityText: "Freeze, \(seconds(session.effects.freezeRemaining)) remaining"
                            )
                        }
                        if session.effects.isSurging {
                            HUDEffectBadge(
                                title: "SPEED",
                                icon: "hare.fill",
                                value: seconds(session.effects.surgeRemaining),
                                tint: EchoTheme.gold,
                                accessibilityText: "Speed, \(seconds(session.effects.surgeRemaining)) remaining"
                            )
                        }
                        if session.effects.isMagnet {
                            HUDEffectBadge(
                                title: "MAGNET",
                                icon: "magnet.fill",
                                value: seconds(session.effects.magnetRemaining),
                                tint: EchoTheme.magenta,
                                accessibilityText: "Magnet, \(seconds(session.effects.magnetRemaining)) remaining"
                            )
                        }
                        if session.effects.isPhasing {
                            HUDEffectBadge(
                                title: "PHASE",
                                icon: "sparkles",
                                value: seconds(session.effects.phaseRemaining),
                                tint: .white,
                                accessibilityText: "Phase, \(seconds(session.effects.phaseRemaining)) remaining"
                            )
                        }
                        if session.effects.isAnchored {
                            HUDEffectBadge(
                                title: "SLOW",
                                icon: "hourglass.bottomhalf.filled",
                                value: seconds(session.effects.anchorRemaining),
                                tint: EchoTheme.cyan,
                                accessibilityText: "Anchor, \(seconds(session.effects.anchorRemaining)) remaining"
                            )
                        }
                        if session.effects.isPrismatic {
                            HUDEffectBadge(
                                title: "PRISM",
                                icon: "triangle.fill",
                                value: seconds(session.effects.prismRemaining),
                                tint: .green,
                                accessibilityText: "Prism, \(seconds(session.effects.prismRemaining)) remaining"
                            )
                        }
                        if session.resonanceChain >= 2 {
                            HUDEffectBadge(
                                icon: "link",
                                value: "×\(session.resonanceChain)",
                                tint: EchoTheme.gold,
                                progress: max(0, min(1, session.resonanceRemaining / 3.25)),
                                accessibilityText: "Resonance chain \(session.resonanceChain)"
                            )
                        }
                        if session.reality != .normal {
                            HUDEffectBadge(
                                icon: session.reality == .candy ? "birthday.cake.fill" : "arrow.left.and.right.righttriangle.left.righttriangle.right.fill",
                                value: seconds(session.realityRemaining),
                                tint: session.reality == .candy ? EchoTheme.magenta : EchoTheme.cyan,
                                accessibilityText: "\(session.reality.rawValue) reality, \(seconds(session.realityRemaining)) remaining"
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
        "\(max(1, Int(ceil(value))))s"
    }
}
