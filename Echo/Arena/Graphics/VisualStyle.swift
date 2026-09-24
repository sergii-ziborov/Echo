import SpriteKit
import UIKit

enum VisualLayer {
    static let background: CGFloat = 0
    static let floor: CGFloat = 1.5
    static let walls: CGFloat = 2.2
    static let trails: CGFloat = 6
    static let pickups: CGFloat = 7
    static let hazards: CGFloat = 10
    static let actors: CGFloat = 14
    static let shells: CGFloat = 15.2
    static let events: CGFloat = 22
}

enum VisualPalette {
    static let playerCore = UIColor(white: 0.97, alpha: 1)
    static let playerRim = UIColor(red: 0.62, green: 0.92, blue: 1, alpha: 1)
    static let playerGlow = UIColor(red: 0.45, green: 0.90, blue: 1, alpha: 1)
    static let echoCore = UIColor(red: 0.90, green: 0.72, blue: 1, alpha: 1)
    static let echoRim = UIColor(red: 0.78, green: 0.40, blue: 1, alpha: 1)
    static let ghostCore = UIColor(red: 1, green: 0.70, blue: 0.68, alpha: 1)
    static let ghostRim = UIColor(red: 1, green: 0.40, blue: 0.46, alpha: 1)
    static let spark = UIColor(red: 0.55, green: 0.92, blue: 1, alpha: 1)
    static let timedSpark = UIColor(red: 1, green: 0.84, blue: 0.38, alpha: 1)
    static let shield = UIColor(red: 0.38, green: 0.96, blue: 0.68, alpha: 1)
    /// The ember-gold comet unlocked by the Tourbillon wrist relic.
    static let tourbillon = UIColor(red: 1, green: 0.58, blue: 0.22, alpha: 1)
}

/// How the player's comet is coloured when no ability overrides it.
enum CometStyle: Equatable, Sendable {
    case classic
    case tourbillon

    var glow: UIColor {
        switch self {
        case .classic: VisualPalette.playerGlow
        case .tourbillon: VisualPalette.tourbillon
        }
    }
}

enum VisualStyle {
    static var useLegacyRenderer: Bool {
        ProcessInfo.processInfo.arguments.contains("-echo-old-gfx")
    }

    static let glowAlpha: CGFloat = 0.24
    static let glowRadiusMul: CGFloat = 2.0
    static let actorBodyScale: CGFloat = 1.62
    static let trailLifetime: TimeInterval = 0.8
    static let trailCapacity = 160
    static let trailStepFactor: CGFloat = 0.22
    static let teleportGap: CGFloat = 72
    /// Comet widths as a share of the actor's own diameter, so the tail joins
    /// the head without a neck on every screen size.
    static let cometPlayerWidth: CGFloat = 1.0
    static let cometSurgeWidth: CGFloat = 1.2
    static let cometEchoWidth: CGFloat = 0.95
    static let cometGhostWidth: CGFloat = 0.85
    static let cometPuffSpacing: CGFloat = 0.2
    static let cometStreakReach: CGFloat = 0.55
    static let cometPuffCap = 72
    static let cometStreakCap = 40
    static let cometMoteCap = 36
    static let trailPuffZ: CGFloat = 0
    static let trailStreakZ: CGFloat = 0.01
    static let trailMoteZ: CGFloat = 0.02
}

struct VisualTrailPoint {
    var position: CGPoint
    var time: TimeInterval
    var breakBefore: Bool = false
}

extension UIColor {
    func blended(with other: UIColor, amount: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = min(max(amount, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }
}
