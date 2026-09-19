import SpriteKit
import UIKit

@MainActor
enum GlowTextures {
    enum OrbPose {
        case idle, moving, dash, spawn, hit
    }

    static let glowMask: SKTexture = makeGlowMask(pixelSize: 128)
    static let player: SKTexture = assembleOrb(color: UIColor(red: 0.40, green: 0.88, blue: 1, alpha: 1))
    static let echo: SKTexture = assembleOrb(color: UIColor(red: 0.78, green: 0.36, blue: 1, alpha: 1))
    static let spark: SKTexture = assembleOrb(color: UIColor(red: 0.45, green: 0.92, blue: 1, alpha: 1), size: 192)
    static let blob: SKTexture = glowMask
    static let spawnRing: SKTexture = makeRing(color: UIColor(red: 0.8, green: 0.4, blue: 1, alpha: 1), size: 160)
    static let asteroid: SKTexture = named("Asteroid") ?? orb(color: UIColor(red: 0.32, green: 0.48, blue: 0.65, alpha: 1), size: 256)
    private static let asteroidAtlas = UIImage(named: "AsteroidMaterialAtlas")
    private static let basaltAsteroid = quadrant(of: asteroidAtlas, top: true, right: false)
    private static let iceAsteroid = quadrant(of: asteroidAtlas, top: true, right: true)
    private static let crystalAsteroid = quadrant(of: asteroidAtlas, top: false, right: false)
    private static let alloyAsteroid = quadrant(of: asteroidAtlas, top: false, right: true)
    private static let asteroidVariantsA = UIImage(named: "AsteroidVariantAtlasA")
    private static let porousAsteroid = quadrant(of: asteroidVariantsA, top: true, right: false)
    private static let spikyAsteroid = quadrant(of: asteroidVariantsA, top: true, right: true)
    private static let volcanicAsteroid = quadrant(of: asteroidVariantsA, top: false, right: false)
    private static let clusterAsteroid = quadrant(of: asteroidVariantsA, top: false, right: true)
    private static let asteroidVariantsB = UIImage(named: "AsteroidVariantAtlasB")
    private static let iceShardAsteroid = quadrant(of: asteroidVariantsB, top: true, right: false)
    private static let crystalShardAsteroid = quadrant(of: asteroidVariantsB, top: true, right: true)
    private static let obsidianAsteroid = quadrant(of: asteroidVariantsB, top: false, right: false)
    private static let relicAsteroid = quadrant(of: asteroidVariantsB, top: false, right: true)
    private static let wallAtlas = UIImage(named: "WallMaterialAtlas")
    private static let metalWall = quadrant(of: wallAtlas, top: true, right: false)
    private static let volcanicWall = quadrant(of: wallAtlas, top: true, right: true)
    private static let ancientWall = quadrant(of: wallAtlas, top: false, right: false)
    private static let iceWall = quadrant(of: wallAtlas, top: false, right: true)
    private static let wallVariantsA = UIImage(named: "WallVariantAtlasA")
    private static let crackedWall = quadrant(of: wallVariantsA, top: true, right: false)
    private static let crystalWall = quadrant(of: wallVariantsA, top: true, right: true)
    private static let overgrownWall = quadrant(of: wallVariantsA, top: false, right: false)
    private static let glassWall = quadrant(of: wallVariantsA, top: false, right: true)
    private static let wallVariantsB = UIImage(named: "WallVariantAtlasB")
    private static let techWall = quadrant(of: wallVariantsB, top: true, right: false)
    private static let forceWall = quadrant(of: wallVariantsB, top: true, right: true)
    private static let carvedWall = quadrant(of: wallVariantsB, top: false, right: false)
    private static let rubbleWall = quadrant(of: wallVariantsB, top: false, right: true)
    private static let obstacleAtlas = UIImage(named: "ObstacleTileAtlas")
    static let closedGate = quadrant(of: obstacleAtlas, top: true, right: false)
    static let openGate = quadrant(of: obstacleAtlas, top: true, right: true)
    static let slowField = quadrant(of: obstacleAtlas, top: false, right: false)
    static let hazardEmitter = quadrant(of: obstacleAtlas, top: false, right: true)
    static let blackHole: SKTexture = assembleOrb(color: UIColor(red: 0.22, green: 0.12, blue: 0.48, alpha: 1))
    static let candyTimeline: SKTexture = named("CandyTimeline") ?? blob
    static let frostVignette: SKTexture = frostVignetteTexture(size: 640)
    static let snowflakeParticle: SKTexture = snowflakeTexture(size: 96)
    static let shieldBubble: SKTexture = shieldBubbleTexture(size: 256)
    private static let bonusTextures: [BonusKind: SKTexture] = {
        Dictionary(uniqueKeysWithValues: BonusKind.allCases.map { kind in
            (kind, abilityPlate(kind: kind, color: color(for: kind), size: 160))
        })
    }()

    static func asteroid(for material: AsteroidMaterial, variation: Int = 0) -> SKTexture {
        let skins: [SKTexture?] = switch material {
        case .basalt: [basaltAsteroid, porousAsteroid, spikyAsteroid, volcanicAsteroid, clusterAsteroid]
        case .ice: [iceAsteroid, iceShardAsteroid]
        case .crystal: [crystalAsteroid, crystalShardAsteroid]
        case .alloy: [alloyAsteroid, obsidianAsteroid, relicAsteroid]
        }
        let index = ((variation % skins.count) + skins.count) % skins.count
        return circularized(skins[index] ?? skins[0] ?? asteroid)
    }

    static func wall(for theme: ArenaTheme, levelNumber: Int) -> SKTexture? {
        let finishes: [SKTexture?] = switch theme {
        case .void: [metalWall, glassWall, techWall]
        case .ember: [volcanicWall, crackedWall, rubbleWall]
        case .moss: [ancientWall, overgrownWall, carvedWall]
        case .ion: [crystalWall, forceWall, techWall]
        case .ice: [iceWall, forceWall, glassWall]
        case .dust: [ancientWall, carvedWall, crackedWall]
        }
        let epoch = (max(1, levelNumber) - 1) / ArenaTheme.allCases.count
        return finishes[epoch % finishes.count] ?? finishes[0]
    }

    static func bonus(_ kind: BonusKind) -> SKTexture {
        bonusTextures[kind] ?? abilityPlate(kind: kind, color: color(for: kind), size: 160)
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
        makeGlowMask(pixelSize: Int(size), tint: color)
    }

    static func abilityGlyph(systemName: String, color: UIColor, size: CGFloat) -> SKTexture {
        abilityPlate(kind: BonusKind.allCases.first { $0.icon == systemName } ?? .shield, color: color, size: size)
    }

    static func abilityPlate(kind: BonusKind, color: UIColor, size: CGFloat) -> SKTexture {
        let image = transparentImage(size: size) { cg in
            let bounds = CGRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84)
            let hex = hexPath(in: bounds)
            cg.addPath(hex)
            cg.setFillColor(UIColor(white: 0.08, alpha: 0.92).cgColor)
            cg.fillPath()
            cg.addPath(hex)
            cg.setStrokeColor(color.withAlphaComponent(0.92).cgColor)
            cg.setLineWidth(size * 0.035)
            cg.strokePath()
            AbilityGlyph.draw(kind: kind, in: bounds, color: .white, onto: cg)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func makeGlowMask(pixelSize: Int, tint: UIColor = .white) -> SKTexture {
        let side = CGFloat(max(16, pixelSize))
        let image = transparentImage(size: side) { cg in
            let center = CGPoint(x: side * 0.5, y: side * 0.5)
            let colors = [
                tint.withAlphaComponent(0.90).cgColor,
                tint.withAlphaComponent(0.46).cgColor,
                tint.withAlphaComponent(0.14).cgColor,
                tint.withAlphaComponent(0.03).cgColor,
                tint.withAlphaComponent(0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 0.22, 0.50, 0.76, 1]
            ) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: side * 0.46,
                    options: []
                )
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func makeRing(color: UIColor, size: CGFloat) -> SKTexture {
        let image = transparentImage(size: size) { cg in
            let inset = size * 0.18
            let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
            cg.setStrokeColor(color.withAlphaComponent(0.85).cgColor)
            cg.setLineWidth(size * 0.06)
            cg.strokeEllipse(in: rect)
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func hexPath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.5
        for index in 0..<6 {
            let angle = CGFloat(index) / 6 * .pi * 2 - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private static func transparentImage(size: CGFloat, draw: (CGContext) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format)
        return renderer.image { context in
            context.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
            draw(context.cgContext)
        }
    }

    private static func circularized(_ texture: SKTexture) -> SKTexture {
        let image = UIImage(cgImage: texture.cgImage())
        let masked = SKTexture(image: circularMasked(image))
        masked.filteringMode = .linear
        return masked
    }

    private static func circularMasked(_ image: UIImage) -> UIImage {
        let side = min(image.size.width, image.size.height)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format)
        return renderer.image { context in
            let rect = CGRect(x: 1, y: 1, width: side - 2, height: side - 2)
            context.cgContext.addEllipse(in: rect)
            context.cgContext.clip()
            image.draw(in: CGRect(
                x: (side - image.size.width) / 2,
                y: (side - image.size.height) / 2,
                width: image.size.width,
                height: image.size.height
            ))
        }
    }

    private static func assembleOrb(color: UIColor, size: CGFloat = 256) -> SKTexture {
        let image = transparentImage(size: size) { cg in
            let inset = size * 0.08
            let circle = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
            cg.addEllipse(in: circle)
            cg.clip()

            let center = CGPoint(x: size * 0.50, y: size * 0.50)
            let light = CGPoint(x: size * 0.38, y: size * 0.36)
            let sphere = [
                UIColor.white.withAlphaComponent(0.96).cgColor,
                color.withAlphaComponent(0.95).cgColor,
                color.withAlphaComponent(0.42).cgColor,
                UIColor(white: 0.04, alpha: 0.96).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: sphere, locations: [0, 0.22, 0.62, 1]) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: light,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: size * 0.46,
                    options: [.drawsAfterEndLocation]
                )
            }

            let sheen = [
                UIColor.white.withAlphaComponent(0.85).cgColor,
                UIColor.white.withAlphaComponent(0).cgColor,
            ] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: sheen, locations: [0, 1]) {
                cg.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: size * 0.36, y: size * 0.33),
                    startRadius: 0,
                    endCenter: CGPoint(x: size * 0.36, y: size * 0.33),
                    endRadius: size * 0.13,
                    options: []
                )
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    private static func quadrant(of atlas: UIImage?, top: Bool, right: Bool) -> SKTexture? {
        guard let image = atlas?.cgImage else { return nil }
        let halfWidth = image.width / 2
        let halfHeight = image.height / 2
        let inset = 4
        let bounds = CGRect(
            x: (right ? halfWidth : 0) + inset,
            y: (top ? 0 : halfHeight) + inset,
            width: halfWidth - inset * 2,
            height: halfHeight - inset * 2
        )
        guard let cropped = image.cropping(to: bounds) else { return nil }
        let texture = SKTexture(cgImage: cropped)
        texture.filteringMode = .linear
        return texture
    }

    private static func frostVignetteTexture(size: CGFloat) -> SKTexture {
        let image = transparentImage(size: size) { cg in
            let center = CGPoint(x: size / 2, y: size / 2)
            let colors = [
                UIColor.clear.cgColor,
                UIColor(red: 0.42, green: 0.76, blue: 1, alpha: 0.02).cgColor,
                UIColor(red: 0.72, green: 0.93, blue: 1, alpha: 0.12).cgColor,
                UIColor.white.withAlphaComponent(0.22).cgColor,
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
