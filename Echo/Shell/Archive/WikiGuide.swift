import SwiftUI

/// The Guide, Hazards and Skills pages. Every rule here is checked against
/// the simulation: numbers come from the rules themselves, and each article
/// says what a mechanic does not do as plainly as what it does.
extension WikiEntry {
    static var guide: [WikiEntry] {
        [
            WikiEntry("wiki.guide.goal", icon: "scope", tint: EchoTheme.gold),
            WikiEntry("wiki.guide.control", icon: "hand.draw.fill", tint: EchoTheme.primaryBlueHi),
            WikiEntry("wiki.guide.echoClock", icon: "timer", tint: .orange),
            WikiEntry(
                "wiki.guide.resonance",
                icon: "waveform.path.ecg",
                tint: EchoTheme.magenta,
                body: Copy.format("wiki.guide.resonance.body", Copy.seconds(WorldSimulation.normalResonanceWindow))
            ),
            WikiEntry("wiki.guide.echoes", icon: "person.2.wave.2.fill", tint: EchoTheme.violet),
            WikiEntry("wiki.guide.seals", icon: "seal.fill", tint: .green),
            WikiEntry("wiki.guide.deepTime", icon: "infinity", tint: EchoTheme.magenta),
        ]
    }

    static var hazards: [WikiEntry] {
        [
            WikiEntry("wiki.hazard.debris", icon: "hexagon.fill", tint: .orange, facts: 3),
            WikiEntry("wiki.hazard.materials", icon: "square.3.layers.3d", tint: EchoTheme.cyan, factLines: AsteroidMaterial.allCases.map(\.wikiLine)),
            WikiEntry("wiki.hazard.beams", icon: "laser.burst", tint: EchoTheme.danger),
            WikiEntry("wiki.hazard.rifts", icon: "hurricane", tint: EchoTheme.violet),
            WikiEntry("wiki.hazard.wells", icon: "circle.circle.fill", tint: EchoTheme.gold),
            WikiEntry("wiki.hazard.gates", icon: "rectangle.portrait.and.arrow.forward", tint: EchoTheme.cyan),
            WikiEntry("wiki.hazard.mire", icon: "circle.dotted.circle.fill", tint: EchoTheme.primaryBlueHi),
            WikiEntry(
                "wiki.hazard.crystals",
                icon: "clock.badge.exclamationmark.fill",
                tint: EchoTheme.gold,
                factLines: [
                    Copy.format("wiki.hazard.crystals.fact1", Copy.seconds(WorldSimulation.crystalFreezeReward)),
                    Copy.text("wiki.hazard.crystals.fact2"),
                ]
            ),
            WikiEntry("wiki.hazard.scars", icon: "scribble.variable", tint: EchoTheme.magenta),
            WikiEntry("wiki.hazard.ghost", icon: "figure.walk.motion", tint: EchoTheme.violet),
        ]
    }

    /// Base values from the rules; research and relics change them in the Lab.
    static var skills: [WikiEntry] {
        let order: [BonusKind] = [.freeze, .surge, .pulse, .shield, .magnet, .phase, .chrono, .anchor, .repulse, .prism, .blink]
        return order.map { kind in
            let timing = kind.duration > 0
                ? Copy.format("wiki.skill.duration", Copy.seconds(kind.duration))
                : Copy.text("wiki.skill.instant")
            let cooldown = Copy.format("wiki.skill.cooldown", Copy.seconds(kind.cooldown))
            return WikiEntry(
                id: "ability.\(kind.rawValue)",
                icon: kind.icon,
                eyebrow: [Copy.text("ability.\(kind.rawValue).category"), timing, cooldown].joined(separator: " · "),
                title: kind.title,
                detail: kind.detail,
                facts: [Copy.text("ability.\(kind.rawValue).fact1"), Copy.text("ability.\(kind.rawValue).fact2")],
                tint: kind.wikiTint
            )
        }
    }
}

extension AsteroidMaterial {
    /// Name, hits to break and breakup clock, read from the material rules.
    var wikiLine: String {
        guard let hits = wallHitsToShatter, let clock = fractureDuration else {
            return Copy.format("wiki.material.unbreakable", title)
        }
        return Copy.format("wiki.material.line", title, Copy.format("wiki.material.hits", hits), Copy.seconds(clock))
    }
}

extension BonusKind {
    var wikiTint: Color {
        switch self {
        case .freeze, .anchor: EchoTheme.cyan
        case .surge: EchoTheme.gold
        case .pulse, .repulse: EchoTheme.magenta
        case .shield, .prism: .green
        case .magnet: .pink
        case .phase: EchoTheme.cyanBright
        case .chrono, .blink: EchoTheme.violet
        case .ward: EchoTheme.gold
        }
    }
}
