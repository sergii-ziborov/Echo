import SpriteKit
import UIKit

@MainActor
enum GlowTextures {
    static let glowMask: SKTexture = makeGlowMask(pixelSize: 128)
    static let player: SKTexture = assembleOrb(color: UIColor(red: 0.40, green: 0.88, blue: 1, alpha: 1))
    static let echo: SKTexture = assembleOrb(color: UIColor(red: 0.78, green: 0.36, blue: 1, alpha: 1))
    static let spark: SKTexture = assembleOrb(color: UIColor(red: 0.45, green: 0.92, blue: 1, alpha: 1), size: 192)
    static let blob: SKTexture = glowMask
    static var puff: SKTexture { SpriteTextures.puff }
    static var nucleus: SKTexture { SpriteTextures.nucleus }
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

    static func asteroid(for material: AsteroidMaterial, variation: Int = 0) -> SKTexture {
        let skins: [SKTexture?] = switch material {
        case .basalt: [basaltAsteroid, porousAsteroid, spikyAsteroid, volcanicAsteroid, clusterAsteroid]
        case .ice: [iceAsteroid, iceShardAsteroid]
        case .crystal: [crystalAsteroid, crystalShardAsteroid]
        case .alloy: [alloyAsteroid, obsidianAsteroid, relicAsteroid]
        case .magma: [volcanicAsteroid, basaltAsteroid]
        case .geode: [porousAsteroid, clusterAsteroid]
        case .iron: [relicAsteroid, obsidianAsteroid]
        case .comet: [iceShardAsteroid, iceAsteroid]
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
        SpriteTextures.token(kind)
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

    static func abilityGlyph(systemName: String, color _: UIColor, size _: CGFloat) -> SKTexture {
        SpriteTextures.token(BonusKind.allCases.first { $0.icon == systemName } ?? .shield)
    }
}
