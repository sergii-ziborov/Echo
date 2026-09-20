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
}

enum VisualStyle {
    static var useLegacyRenderer: Bool {
        ProcessInfo.processInfo.arguments.contains("-echo-old-gfx")
    }

    static let glowAlpha: CGFloat = 0.16
    static let glowRadiusMul: CGFloat = 1.72
    static let actorBodyScale: CGFloat = 1.35
    static let trailLifetime: TimeInterval = 0.85
    static let trailCapacity = 128
    static let trailStepFactor: CGFloat = 0.22
    static let teleportGap: CGFloat = 72
    static let trailPlayerWidth: CGFloat = 14
    static let trailSurgeWidth: CGFloat = 19
    static let trailEchoWidth: CGFloat = 11
    static let trailGhostWidth: CGFloat = 9
    static let trailTaper: CGFloat = 1.55
    static let trailBloomZ: CGFloat = 0
    static let trailBandZ: CGFloat = 0.01
    static let trailCoreZ: CGFloat = 0.02
}

struct VisualTrailPoint {
    var position: CGPoint
    var time: TimeInterval
    var breakBefore: Bool = false
}
