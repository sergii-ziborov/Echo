import SpriteKit
import UIKit

@MainActor
enum GlowTextures {
    static let player: SKTexture = named("PlayerOrb") ?? orb(color: UIColor(red: 0.45, green: 0.9, blue: 1, alpha: 1), size: 256)
    static let echo: SKTexture = named("EchoOrb") ?? orb(color: UIColor(red: 0.75, green: 0.35, blue: 1, alpha: 1), size: 256)
    static let spark: SKTexture = named("SparkOrb") ?? orb(color: UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 1), size: 192)
    static let blob: SKTexture = named("GlowBlob") ?? orb(color: UIColor(red: 0.4, green: 0.9, blue: 1, alpha: 1), size: 128)

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
