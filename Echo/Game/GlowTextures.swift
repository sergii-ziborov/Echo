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
    static let frostVignette: SKTexture = frostVignetteTexture(size: 640)
    static let snowflakeParticle: SKTexture = snowflakeTexture(size: 96)
    static let shieldBubble: SKTexture = shieldBubbleTexture(size: 256)

    static func bonus(_ kind: BonusKind) -> SKTexture {
        switch kind {
        case .anchor, .repulse, .prism, .blink:
            abilityGlyph(systemName: kind.icon, color: color(for: kind), size: 160)
        default:
            named(kind.assetName) ?? abilityGlyph(systemName: kind.icon, color: color(for: kind), size: 160)
        }
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

    static func abilityGlyph(systemName: String, color: UIColor, size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let cg = context.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                color.withAlphaComponent(0).cgColor,
                color.withAlphaComponent(0.42).cgColor,
                color.withAlphaComponent(0.88).cgColor,
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.58, 1]
            ) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size * 0.47,
                    options: []
                )
            }
            let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.34, weight: .bold)
            if let symbol = UIImage(systemName: systemName, withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let rect = CGRect(
                    x: (size - symbol.size.width) / 2,
                    y: (size - symbol.size.height) / 2,
                    width: symbol.size.width,
                    height: symbol.size.height
                )
                symbol.draw(in: rect)
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func frostVignetteTexture(size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            let cg = context.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                UIColor.clear.cgColor,
                UIColor(red: 0.42, green: 0.76, blue: 1, alpha: 0.04).cgColor,
                UIColor(red: 0.72, green: 0.93, blue: 1, alpha: 0.30).cgColor,
                UIColor.white.withAlphaComponent(0.58).cgColor,
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0.0, 0.56, 0.84, 1.0]
            ) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: size * 0.12,
                    endCenter: center,
                    endRadius: size * 0.53,
                    options: [.drawsAfterEndLocation]
                )
            }

            cg.setLineCap(.round)
            for index in 0..<30 {
                let angle = CGFloat(index) / 30 * .pi * 2 + sin(CGFloat(index * 17)) * 0.08
                let edge = CGPoint(
                    x: center.x + cos(angle) * size * 0.52,
                    y: center.y + sin(angle) * size * 0.52
                )
                let length = size * (0.075 + CGFloat(index % 5) * 0.009)
                let inward = CGVector(dx: -cos(angle), dy: -sin(angle))
                let end = CGPoint(x: edge.x + inward.dx * length, y: edge.y + inward.dy * length)
                cg.setStrokeColor(
                    (index.isMultiple(of: 3) ? UIColor.white : UIColor(red: 0.58, green: 0.86, blue: 1, alpha: 1))
                        .withAlphaComponent(0.22 + CGFloat(index % 4) * 0.045).cgColor
                )
                cg.setLineWidth(index.isMultiple(of: 4) ? 1.6 : 0.9)
                cg.move(to: edge)
                cg.addLine(to: end)
                for branch in 1...2 {
                    let amount = CGFloat(branch) / 3
                    let joint = CGPoint(
                        x: edge.x + (end.x - edge.x) * amount,
                        y: edge.y + (end.y - edge.y) * amount
                    )
                    let branchLength = length * (0.20 + CGFloat(branch) * 0.05)
                    for side: CGFloat in [-1, 1] {
                        let branchAngle = angle + .pi + side * 0.72
                        cg.move(to: joint)
                        cg.addLine(to: CGPoint(
                            x: joint.x + cos(branchAngle) * branchLength,
                            y: joint.y + sin(branchAngle) * branchLength
                        ))
                    }
                }
                cg.strokePath()
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func snowflakeTexture(size: CGFloat) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let image = renderer.image { context in
            let configuration = UIImage.SymbolConfiguration(pointSize: size * 0.58, weight: .thin)
            guard let symbol = UIImage(systemName: "snowflake", withConfiguration: configuration)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) else { return }
            let rect = CGRect(
                x: (size - symbol.size.width) / 2,
                y: (size - symbol.size.height) / 2,
                width: symbol.size.width,
                height: symbol.size.height
            )
            context.cgContext.setShadow(
                offset: .zero,
                blur: size * 0.10,
                color: UIColor(red: 0.42, green: 0.82, blue: 1, alpha: 0.90).cgColor
            )
            symbol.draw(in: rect)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func shieldBubbleTexture(size: CGFloat) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                UIColor.white.withAlphaComponent(0.12).cgColor,
                UIColor(red: 0.30, green: 1, blue: 0.72, alpha: 0.015).cgColor,
                UIColor(red: 0.30, green: 1, blue: 0.72, alpha: 0.08).cgColor,
                UIColor(red: 0.44, green: 1, blue: 0.84, alpha: 0.72).cgColor,
                UIColor.clear.cgColor,
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.34, 0.76, 0.92, 1]
            ) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: size * 0.39, y: size * 0.38),
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size * 0.48,
                    options: []
                )
            }

            let inset = size * 0.075
            let circle = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
            cg.setShadow(offset: .zero, blur: size * 0.045, color: UIColor(red: 0.28, green: 1, blue: 0.73, alpha: 0.75).cgColor)
            cg.setStrokeColor(UIColor(red: 0.56, green: 1, blue: 0.88, alpha: 0.72).cgColor)
            cg.setLineWidth(size * 0.009)
            cg.strokeEllipse(in: circle)

            cg.setShadow(offset: .zero, blur: size * 0.025, color: UIColor.white.withAlphaComponent(0.8).cgColor)
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.78).cgColor)
            cg.setLineWidth(size * 0.015)
            cg.setLineCap(.round)
            cg.addArc(
                center: center,
                radius: size * 0.405,
                startAngle: .pi * 1.10,
                endAngle: .pi * 1.55,
                clockwise: false
            )
            cg.strokePath()
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}
