import SpriteKit
import UIKit

@MainActor
enum GlowTextures {
    static let player: SKTexture = named("PlayerOrb") ?? orb(color: UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 1), size: 256)
    static let echo: SKTexture = named("EchoOrb") ?? orb(color: UIColor(red: 0.75, green: 0.35, blue: 1, alpha: 1), size: 256)
    static let spark: SKTexture = named("SparkGem") ?? named("SparkOrb") ?? orb(color: UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 1), size: 192)
    static let blob: SKTexture = named("GlowBlob") ?? orb(color: UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 1), size: 128)
    static let spawnRing: SKTexture = named("SpawnRing") ?? orb(color: UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 1), size: 160)
    static let asteroid: SKTexture = named("Asteroid") ?? orb(color: UIColor(red: 0.32, green: 0.48, blue: 0.65, alpha: 1), size: 256)
    static let laserEmitter: SKTexture = named("LaserEmitter") ?? orb(color: UIColor(red: 1, green: 0.28, blue: 0.48, alpha: 1), size: 256)
    static let dimensionalRift: SKTexture = named("DimensionalRift") ?? spawnRing
    static let blackHole: SKTexture = named("BlackHole") ?? orb(color: UIColor(red: 0.25, green: 0.15, blue: 0.55, alpha: 1), size: 256)
    static let candyTimeline: SKTexture = named("CandyTimeline") ?? blob

    static func bonus(_ kind: BonusKind) -> SKTexture {
        named(kind.assetName) ?? orb(color: color(for: kind), size: 160)
    }

    static func color(for kind: BonusKind) -> UIColor {
        UIColor(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b, alpha: 1)
    }

    static func named(_ name: String) -> SKTexture? {
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func orb(color: UIColor, size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                color.withAlphaComponent(0.0).cgColor,
                color.withAlphaComponent(0.15).cgColor,
                color.withAlphaComponent(0.55).cgColor,
                UIColor.white.withAlphaComponent(0.95).cgColor,
            ] as CFArray
            let locations: [CGFloat] = [0, 0.35, 0.7, 1]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size / 2,
                    options: [.drawsAfterEndLocation]
                )
            }
        }
        return SKTexture(image: image)
    }
}
