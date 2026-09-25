import SpriteKit
import UIKit

/// A slow, distant sky behind the arena: the region's landmark (a planet, a
/// star, a black hole, a tear) that says where on the Fold Road the Signal
/// is, a spiral galaxy wheeling far away, twinkling stars, now and then a
/// meteor, and a soft light that breathes and sweeps past. It sits behind
/// everything, stays dim, and moves far too slowly to read as a hazard.
@MainActor
final class Backdrop {
    struct Palette {
        var sky: UIColor
        var glow: UIColor
        var accent: UIColor
    }

    struct Budget {
        var stars: Int
        /// Seconds between meteors.
        var meteorGap: ClosedRange<TimeInterval>
        var textureScale: CGFloat
        var lightSweep: Bool
        /// A small face needs a smaller, fainter planet to keep it in the back.
        var planetScale: CGFloat
        var planetAlpha: CGFloat

        static let phone = Budget(stars: 44, meteorGap: 5...11, textureScale: 2, lightSweep: true, planetScale: 1, planetAlpha: 0.48)
        static let watch = Budget(stars: 16, meteorGap: 8...15, textureScale: 2, lightSweep: false, planetScale: 0.72, planetAlpha: 0.34)
    }

    let root = SKNode()
    let size: CGSize
    let palette: Palette
    let budget: Budget
    let motion: Bool
    let landmark: SkyLandmark
    /// How far through its region the map lies; the landmark draws nearer.
    let progress: CGFloat
    var rng: SplitMix64
    private var nextMeteor: TimeInterval = 0
    /// Meteors fall away from the side the landmark hangs on.
    var landmarkOnLeft = true

    init(size: CGSize, palette: Palette, seed: UInt64, landmark: SkyLandmark, progress: Double = 0.5, budget: Budget = .phone, motion: Bool = true) {
        self.size = size
        self.palette = palette
        self.budget = budget
        self.motion = motion
        self.landmark = landmark
        self.progress = CGFloat(min(1, max(0, progress)))
        rng = SplitMix64(seed: seed ^ 0xBAC6_D509)
        root.name = "backdrop"
        buildLight()
        buildGalaxy()
        buildStars()
        buildLandmark()
        if budget.lightSweep { buildSweep() }
    }

    /// Called every frame by the owning scene; launches the odd meteor.
    func tick(now: TimeInterval) {
        guard motion else { return }
        if nextMeteor == 0 {
            nextMeteor = now + TimeInterval.random(in: 1.5...4, using: &rng)
            return
        }
        guard now >= nextMeteor else { return }
        nextMeteor = now + TimeInterval.random(in: budget.meteorGap, using: &rng)
        launchMeteor()
    }

    // MARK: - Layers

    private func buildLight() {
        let reach = max(size.width, size.height) * 0.9
        let light = SKSpriteNode(texture: Self.softDisc, size: CGSize(width: reach, height: reach))
        light.color = palette.glow
        light.colorBlendFactor = 1
        light.blendMode = .add
        light.alpha = 0.07
        light.position = CGPoint(x: size.width * CGFloat.random(in: 0.15...0.85, using: &rng), y: size.height * CGFloat.random(in: 0.55...0.9, using: &rng))
        light.zPosition = -5
        root.addChild(light)
        guard motion else { return }
        light.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.12, duration: 7),
            .fadeAlpha(to: 0.05, duration: 8),
        ])))
    }

    private func buildGalaxy() {
        // From the rim the home galaxy fills a good part of the sky; next to
        // Ashcrown the star drowns it out.
        let scale: CGFloat = switch landmark {
        case .giant, .dawn: 1.5
        case .sun(_, _, let size): size > 0.4 ? 0 : 1
        case .blackHole, .tear: 0.7
        default: 1
        }
        guard scale > 0 else { return }
        let radius = min(size.width, size.height) * CGFloat.random(in: 0.17...0.24, using: &rng) * scale
        let tilt = SKNode()
        tilt.position = CGPoint(x: size.width * CGFloat.random(in: 0.2...0.8, using: &rng), y: size.height * CGFloat.random(in: 0.3...0.75, using: &rng))
        tilt.zRotation = CGFloat.random(in: 0..<(.pi), using: &rng)
        tilt.yScale = CGFloat.random(in: 0.42...0.62, using: &rng)
        tilt.zPosition = -4
        let arms = Int.random(in: 2...3, using: &rng)
        let texture = Self.galaxyTexture(radius: radius, arms: arms, tint: palette.accent, scale: budget.textureScale, rng: &rng)
        let disc = SKSpriteNode(texture: texture, size: CGSize(width: radius * 2, height: radius * 2))
        disc.blendMode = .add
        disc.alpha = 0.42
        tilt.addChild(disc)
        root.addChild(tilt)
        guard motion else { return }
        disc.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: TimeInterval.random(in: 200...260, using: &rng))))
    }

    private func buildStars() {
        for _ in 0..<budget.stars {
            let star = SKSpriteNode(texture: Self.softDisc)
            let side = CGFloat.random(in: 1.4...3.2, using: &rng)
            star.size = CGSize(width: side, height: side)
            star.color = Bool.random(using: &rng) ? .white : palette.accent.blended(with: .white, amount: 0.6)
            star.colorBlendFactor = 1
            star.blendMode = .add
            star.alpha = CGFloat.random(in: 0.3...0.8, using: &rng)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width, using: &rng), y: CGFloat.random(in: 0...size.height, using: &rng))
            star.zPosition = -3
            root.addChild(star)
            guard motion, Int.random(in: 0..<10, using: &rng) < 5 else { continue }
            let bright = star.alpha
            star.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval.random(in: 0...3, using: &rng)),
                .fadeAlpha(to: bright * 0.25, duration: TimeInterval.random(in: 0.8...2.2, using: &rng)),
                .fadeAlpha(to: bright, duration: TimeInterval.random(in: 0.8...2.2, using: &rng)),
            ])))
        }
    }

    /// Once in a while a broad, faint band of light crosses the whole sky.
    private func buildSweep() {
        let span = hypot(size.width, size.height)
        let sweep = SKSpriteNode(texture: Self.sweepTexture, size: CGSize(width: span * 0.35, height: span * 1.6))
        sweep.color = palette.glow.blended(with: .white, amount: 0.5)
        sweep.colorBlendFactor = 1
        sweep.blendMode = .add
        sweep.alpha = 0
        sweep.zRotation = -0.5
        sweep.zPosition = -1
        let start = CGPoint(x: -span * 0.3, y: size.height / 2)
        sweep.position = start
        root.addChild(sweep)
        guard motion else { return }
        let across = SKAction.moveBy(x: size.width + span * 0.6, y: 0, duration: 9)
        across.timingMode = .easeInEaseOut
        sweep.run(.repeatForever(.sequence([
            .wait(forDuration: 24, withRange: 16),
            .move(to: start, duration: 0),
            .group([
                across,
                .sequence([.fadeAlpha(to: 0.09, duration: 3), .wait(forDuration: 3), .fadeAlpha(to: 0, duration: 3)]),
            ]),
        ])))
    }

    private func launchMeteor() {
        let length = min(size.width, size.height) * CGFloat.random(in: 0.18...0.32, using: &rng)
        let meteor = SKSpriteNode(texture: Self.streakTexture, size: CGSize(width: length, height: max(1.6, length * 0.02)))
        meteor.anchorPoint = CGPoint(x: 1, y: 0.5)
        meteor.color = Bool.random(using: &rng) ? .white : palette.accent.blended(with: .white, amount: 0.5)
        meteor.colorBlendFactor = 1
        meteor.blendMode = .add
        meteor.alpha = 0
        meteor.zPosition = -1.5
        // Fall across the upper sky, away from the side the planet sits on.
        let leftward = !landmarkOnLeft
        let heading = (leftward ? .pi + 0.35 : -0.35) + CGFloat.random(in: -0.25...0.25, using: &rng)
        let start = CGPoint(
            x: size.width * CGFloat.random(in: 0.2...0.8, using: &rng),
            y: size.height * CGFloat.random(in: 0.55...0.95, using: &rng)
        )
        let travel = min(size.width, size.height) * CGFloat.random(in: 0.35...0.6, using: &rng)
        let duration = TimeInterval.random(in: 0.7...1.2, using: &rng)
        meteor.position = start
        meteor.zRotation = heading
        root.addChild(meteor)
        meteor.run(.sequence([
            .group([
                .moveBy(x: cos(heading) * travel, y: sin(heading) * travel, duration: duration),
                .sequence([
                    .fadeAlpha(to: CGFloat.random(in: 0.45...0.75, using: &rng), duration: duration * 0.2),
                    .wait(forDuration: duration * 0.45),
                    .fadeOut(withDuration: duration * 0.35),
                ]),
            ]),
            .removeFromParent(),
        ]))
    }
}

// MARK: - Textures

extension Backdrop {
    static let softDisc: SKTexture = BitmapCanvas.texture(size: CGSize(width: 64, height: 64)) { cg in
        BitmapCanvas.radial(cg, [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.35).cgColor, UIColor.white.withAlphaComponent(0).cgColor], at: CGPoint(x: 32, y: 32), to: CGPoint(x: 32, y: 32), radius: 32, locations: [0, 0.25, 1])
    }

    /// A bright head fading into a long tail, drawn with the head on the right.
    static let streakTexture: SKTexture = BitmapCanvas.texture(size: CGSize(width: 256, height: 8)) { cg in
        BitmapCanvas.linear(cg, [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.55).cgColor, UIColor.white.cgColor], from: CGPoint(x: 0, y: 4), to: CGPoint(x: 256, y: 4), locations: [0, 0.8, 1])
    }

    static let sweepTexture: SKTexture = BitmapCanvas.texture(size: CGSize(width: 64, height: 8)) { cg in
        BitmapCanvas.linear(cg, [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor], from: CGPoint(x: 0, y: 4), to: CGPoint(x: 64, y: 4))
    }

    /// A thin glow hugging the lit limb (+x side) of a unit planet.
    static let rimTexture: SKTexture = BitmapCanvas.texture(size: CGSize(width: 250, height: 250), scale: 1) { cg in
        let center = CGPoint(x: 125, y: 125)
        cg.saveGState()
        cg.addEllipse(in: CGRect(x: 0, y: 0, width: 250, height: 250))
        cg.addEllipse(in: CGRect(x: 25, y: 25, width: 200, height: 200))
        cg.clip(using: .evenOdd)
        BitmapCanvas.radial(cg, [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.8).cgColor, UIColor.white.withAlphaComponent(0).cgColor], at: center, to: center, radius: 125, from: 98, locations: [0, 0.12, 1])
        cg.restoreGState()
        // Keep only the side that faces the light.
        cg.setBlendMode(.destinationOut)
        BitmapCanvas.linear(cg, [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor], from: CGPoint(x: 40, y: 125), to: CGPoint(x: 200, y: 125))
    }

    /// Night side and limb darkening for a planet lit from +x.
    static func terminatorTexture(sky: UIColor, scale: CGFloat) -> SKTexture {
        BitmapCanvas.texture(size: CGSize(width: 200, height: 200), scale: scale) { cg in
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: 200, height: 200))
            cg.clip()
            BitmapCanvas.linear(cg, [sky.withAlphaComponent(0.92).cgColor, sky.withAlphaComponent(0.55).cgColor, sky.withAlphaComponent(0).cgColor], from: CGPoint(x: 0, y: 100), to: CGPoint(x: 150, y: 100), locations: [0, 0.45, 1])
            BitmapCanvas.radial(cg, [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.45).cgColor], at: CGPoint(x: 100, y: 100), to: CGPoint(x: 100, y: 100), radius: 100, from: 70)
        }
    }

    /// Horizontal cloud bands that tile left to right, with a storm or two.
    static func bandTexture(size: CGSize, base: UIColor, accent: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        var bands: [(y: CGFloat, height: CGFloat, color: UIColor, wave: CGFloat, phase: CGFloat)] = []
        var y: CGFloat = 0
        while y < size.height {
            let height = size.height * CGFloat.random(in: 0.04...0.12, using: &rng)
            let lift = CGFloat.random(in: -0.28...0.28, using: &rng)
            let color = lift > 0 ? base.blended(with: .white, amount: lift) : base.blended(with: .black, amount: -lift)
            let tinted = Int.random(in: 0..<4, using: &rng) == 0 ? color.blended(with: accent, amount: 0.35) : color
            bands.append((y, height, tinted, size.height * CGFloat.random(in: 0.005...0.02, using: &rng), CGFloat.random(in: 0..<(2 * .pi), using: &rng)))
            y += height
        }
        let storms = (0..<Int.random(in: 1...2, using: &rng)).map { _ in
            (CGPoint(x: CGFloat.random(in: 0...size.width, using: &rng), y: CGFloat.random(in: size.height * 0.25...size.height * 0.75, using: &rng)),
             size.height * CGFloat.random(in: 0.06...0.1, using: &rng))
        }
        return BitmapCanvas.texture(size: size, scale: scale) { cg in
            cg.setFillColor(base.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            for band in bands {
                let path = CGMutablePath()
                let steps = 48
                // Whole sine periods across the width keep the edges seamless.
                for step in 0...steps {
                    let x = size.width * CGFloat(step) / CGFloat(steps)
                    let wobble = sin(x / size.width * .pi * 4 + band.phase) * band.wave
                    step == 0 ? path.move(to: CGPoint(x: x, y: band.y + wobble)) : path.addLine(to: CGPoint(x: x, y: band.y + wobble))
                }
                for step in (0...steps).reversed() {
                    let x = size.width * CGFloat(step) / CGFloat(steps)
                    let wobble = sin(x / size.width * .pi * 4 + band.phase) * band.wave
                    path.addLine(to: CGPoint(x: x, y: band.y + band.height + wobble))
                }
                path.closeSubpath()
                cg.addPath(path)
                cg.setFillColor(band.color.withAlphaComponent(0.8).cgColor)
                cg.fillPath()
            }
            for (center, radius) in storms {
                for shift in [-size.width, 0, size.width] {
                    let spot = CGRect(x: center.x + shift - radius * 1.6, y: center.y - radius, width: radius * 3.2, height: radius * 2)
                    cg.setFillColor(accent.blended(with: .white, amount: 0.3).withAlphaComponent(0.5).cgColor)
                    cg.fillEllipse(in: spot)
                    cg.setStrokeColor(UIColor.white.withAlphaComponent(0.25).cgColor)
                    cg.setLineWidth(max(1, radius * 0.12))
                    cg.strokeEllipse(in: spot.insetBy(dx: radius * 0.5, dy: radius * 0.35))
                }
            }
        }
    }

    /// A face-on spiral: a warm core and star-dusted arms on transparency.
    static func galaxyTexture(radius: CGFloat, arms: Int, tint: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let side = radius * 2
        var dots: [(CGPoint, CGFloat, CGFloat)] = []
        for arm in 0..<arms {
            let offset = CGFloat(arm) / CGFloat(arms) * 2 * .pi
            for index in 0..<150 {
                let t = CGFloat(index) / 150
                let angle = offset + t * .pi * 3.2 + CGFloat.random(in: -0.18...0.18, using: &rng)
                let reach = radius * (0.1 + 0.85 * t) * CGFloat.random(in: 0.9...1.1, using: &rng)
                let point = CGPoint(x: radius + cos(angle) * reach, y: radius + sin(angle) * reach)
                dots.append((point, CGFloat.random(in: 0.6...1.8, using: &rng) * max(1, radius / 60), (1 - t) * 0.7 + 0.15))
            }
        }
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            let center = CGPoint(x: radius, y: radius)
            BitmapCanvas.radial(cg, [tint.withAlphaComponent(0.35).cgColor, tint.withAlphaComponent(0).cgColor], at: center, to: center, radius: radius)
            for (point, size, alpha) in dots {
                cg.setFillColor(UIColor.white.blended(with: tint, amount: 0.4).withAlphaComponent(alpha).cgColor)
                cg.fillEllipse(in: CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size))
            }
            BitmapCanvas.radial(cg, [UIColor.white.cgColor, UIColor(red: 1, green: 0.9, blue: 0.7, alpha: 0.6).cgColor, tint.withAlphaComponent(0).cgColor], at: center, to: center, radius: radius * 0.3, locations: [0, 0.3, 1])
        }
    }
}
