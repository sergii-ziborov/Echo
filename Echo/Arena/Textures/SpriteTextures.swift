import CoreGraphics
import SpriteKit
import UIKit

/// Procedural sprites that draw the same on iPhone and Apple Watch: comet
/// puffs, actor heads, spark crystals and the ability tokens used on the map,
/// in the HUD and in the Lab.
@MainActor
enum SpriteTextures {
    static let puff = makePuff(pixels: 96)
    static let nucleus = makeNucleus(pixels: 128)
    static let glint = makeGlint(pixels: 64)
    static let sparkGem = makeGem(timed: false)
    static let timedGem = makeGem(timed: true)
    static let shine = makeShine()
    private static var tokens: [BonusKind: SKTexture] = [:]

    static func token(_ kind: BonusKind) -> SKTexture {
        if let cached = tokens[kind] { return cached }
        let texture = makeToken(kind)
        tokens[kind] = texture
        return texture
    }

    static func tint(_ kind: BonusKind) -> UIColor {
        UIColor(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b, alpha: 1)
    }

    // MARK: - Soft shapes

    /// A broad, flat-topped puff: overlapping copies merge into one soft body
    /// instead of a string of bright beads.
    static func makePuff(pixels: Int) -> SKTexture {
        let side = CGFloat(max(16, pixels))
        return BitmapCanvas.texture(size: CGSize(width: side, height: side)) { cg in
            let center = CGPoint(x: side / 2, y: side / 2)
            let stops: [CGFloat] = [0, 0.2, 0.4, 0.6, 0.8, 1]
            let colors = stops.map { rho in UIColor.white.withAlphaComponent(pow(max(0, 1 - rho * rho), 1.6)).cgColor }
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: stops) else { return }
            cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: side / 2, options: [])
        }
    }

    /// Neutral head shading; the actor's fill colour tints it. A hot centre
    /// above-left of the middle keeps the head from reading as a flat plate.
    static func makeNucleus(pixels: Int) -> SKTexture {
        let side = CGFloat(max(16, pixels))
        return BitmapCanvas.texture(size: CGSize(width: side, height: side)) { cg in
            BitmapCanvas.radial(
                cg,
                [UIColor.white.cgColor, UIColor(white: 0.97, alpha: 1).cgColor, UIColor(white: 0.84, alpha: 1).cgColor],
                at: CGPoint(x: side * 0.42, y: side * 0.6),
                to: CGPoint(x: side / 2, y: side / 2),
                radius: side / 2,
                locations: [0, 0.45, 1]
            )
        }
    }

    /// A four-point twinkle with a soft core, for glints on gems and pickups.
    static func makeGlint(pixels: Int) -> SKTexture {
        let side = CGFloat(max(16, pixels))
        return BitmapCanvas.texture(size: CGSize(width: side, height: side)) { cg in
            let c = side / 2
            BitmapCanvas.radial(cg, [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor], at: CGPoint(x: c, y: c), to: CGPoint(x: c, y: c), radius: side * 0.22)
            cg.translateBy(x: c, y: c)
            cg.setFillColor(UIColor.white.cgColor)
            for (arm, waist, turn) in [(side * 0.5, side * 0.045, CGFloat(0)), (side * 0.3, side * 0.03, .pi / 4)] {
                cg.saveGState()
                cg.rotate(by: turn)
                cg.move(to: CGPoint(x: 0, y: arm))
                cg.addLine(to: CGPoint(x: waist, y: waist))
                cg.addLine(to: CGPoint(x: arm, y: 0))
                cg.addLine(to: CGPoint(x: waist, y: -waist))
                cg.addLine(to: CGPoint(x: 0, y: -arm))
                cg.addLine(to: CGPoint(x: -waist, y: -waist))
                cg.addLine(to: CGPoint(x: -arm, y: 0))
                cg.addLine(to: CGPoint(x: -waist, y: waist))
                cg.closePath()
                cg.fillPath()
                cg.restoreGState()
            }
        }
    }

    /// A soft diagonal light band that sweeps across tokens.
    static func makeShine() -> SKTexture {
        BitmapCanvas.texture(size: CGSize(width: 32, height: 96)) { cg in
            BitmapCanvas.linear(
                cg,
                [UIColor.white.withAlphaComponent(0).cgColor, UIColor.white.withAlphaComponent(0.75).cgColor, UIColor.white.withAlphaComponent(0).cgColor],
                from: CGPoint(x: 0, y: 48),
                to: CGPoint(x: 32, y: 48)
            )
        }
    }

    // MARK: - Spark crystals

    /// A cut gem seen from above: a diamond for plain sparks, a hexagonal
    /// brilliant for timed crystals. Facets catch the upper-left light.
    static func makeGem(timed: Bool) -> SKTexture {
        let side: CGFloat = 64
        let light = timed ? UIColor(red: 1, green: 0.97, blue: 0.78, alpha: 1) : UIColor(red: 0.88, green: 1, blue: 1, alpha: 1)
        let mid = timed ? UIColor(red: 1, green: 0.78, blue: 0.26, alpha: 1) : UIColor(red: 0.38, green: 0.88, blue: 1, alpha: 1)
        let dark = timed ? UIColor(red: 0.72, green: 0.42, blue: 0.06, alpha: 1) : UIColor(red: 0.10, green: 0.46, blue: 0.78, alpha: 1)
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: 3) { cg in
            let c = CGPoint(x: side / 2, y: side / 2)
            let outer: [CGPoint] = timed
                ? (0..<8).map { index in
                    let angle = CGFloat(index) / 8 * 2 * .pi + .pi / 8
                    return CGPoint(x: c.x + cos(angle) * side * 0.4, y: c.y + sin(angle) * side * 0.4)
                }
                : [
                    CGPoint(x: c.x, y: c.y + side * 0.44), CGPoint(x: c.x - side * 0.3, y: c.y),
                    CGPoint(x: c.x, y: c.y - side * 0.44), CGPoint(x: c.x + side * 0.3, y: c.y),
                ]
            let table = outer.map { CGPoint(x: c.x + ($0.x - c.x) * 0.42, y: c.y + ($0.y - c.y) * 0.42) }
            cg.saveGState()
            BitmapCanvas.glow(cg, blur: 5, color: mid.withAlphaComponent(0.9).cgColor)
            cg.addPath(BitmapCanvas.polygon(outer))
            cg.setFillColor(mid.cgColor)
            cg.fillPath()
            cg.restoreGState()
            // Crown facets between the rim and the table, shaded by how much each faces the light.
            for index in outer.indices {
                let next = (index + 1) % outer.count
                let facet = [outer[index], outer[next], table[next], table[index]]
                let middle = CGPoint(x: (outer[index].x + outer[next].x) / 2 - c.x, y: (outer[index].y + outer[next].y) / 2 - c.y)
                let facing = max(-1, min(1, (-middle.x + middle.y) / (side * 0.36)))
                let tone = facing > 0 ? mid.blended(with: light, amount: facing) : mid.blended(with: dark, amount: -facing)
                cg.addPath(BitmapCanvas.polygon(facet))
                cg.setFillColor(tone.cgColor)
                cg.fillPath()
            }
            cg.saveGState()
            cg.addPath(BitmapCanvas.polygon(table))
            cg.clip()
            BitmapCanvas.linear(cg, [light.cgColor, mid.cgColor], from: CGPoint(x: c.x - side * 0.14, y: c.y + side * 0.14), to: CGPoint(x: c.x + side * 0.14, y: c.y - side * 0.14))
            cg.restoreGState()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            cg.setLineWidth(1.1)
            cg.setLineJoin(.round)
            cg.addPath(BitmapCanvas.polygon(outer))
            cg.strokePath()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.45).cgColor)
            cg.setLineWidth(0.7)
            for index in outer.indices {
                cg.move(to: outer[index])
                cg.addLine(to: table[index])
            }
            cg.addPath(BitmapCanvas.polygon(table))
            cg.strokePath()
        }
    }

    // MARK: - Ability tokens

    /// A jewel-like hexagonal token: dark enamel lit by the ability colour, a
    /// bevelled rim, a glossy upper half and the glyph glowing in its tint.
    static func makeToken(_ kind: BonusKind) -> SKTexture {
        let side: CGFloat = 96
        let tint = tint(kind)
        let navy = UIColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1)
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: 2) { cg in
            let c = CGPoint(x: side / 2, y: side / 2)
            let hex = BitmapCanvas.hexagon(center: c, radius: side * 0.42, corner: side * 0.07)
            cg.saveGState()
            BitmapCanvas.glow(cg, blur: side * 0.07, color: tint.withAlphaComponent(0.85).cgColor)
            cg.addPath(hex)
            cg.setFillColor(navy.cgColor)
            cg.fillPath()
            cg.restoreGState()

            cg.saveGState()
            cg.addPath(hex)
            cg.clip()
            BitmapCanvas.radial(
                cg,
                [tint.blended(with: navy, amount: 0.35).cgColor, tint.blended(with: navy, amount: 0.78).cgColor, navy.cgColor],
                at: CGPoint(x: c.x, y: c.y + side * 0.08),
                to: c,
                radius: side * 0.46,
                locations: [0, 0.55, 1]
            )
            BitmapCanvas.linear(
                cg,
                [UIColor.white.withAlphaComponent(0.26).cgColor, UIColor.white.withAlphaComponent(0).cgColor],
                from: CGPoint(x: c.x, y: c.y + side * 0.42),
                to: CGPoint(x: c.x, y: c.y + side * 0.02)
            )
            cg.addPath(BitmapCanvas.hexagon(center: c, radius: side * 0.36, corner: side * 0.05))
            cg.setStrokeColor(tint.withAlphaComponent(0.45).cgColor)
            cg.setLineWidth(side * 0.018)
            cg.strokePath()
            cg.restoreGState()

            cg.addPath(hex)
            cg.setStrokeColor(tint.blended(with: .white, amount: 0.25).cgColor)
            cg.setLineWidth(side * 0.035)
            cg.strokePath()
            cg.saveGState()
            cg.addPath(hex)
            cg.setLineWidth(side * 0.035)
            cg.replacePathWithStrokedPath()
            cg.clip()
            BitmapCanvas.linear(
                cg,
                [UIColor.white.withAlphaComponent(0.9).cgColor, UIColor.white.withAlphaComponent(0).cgColor],
                from: CGPoint(x: c.x - side * 0.3, y: c.y + side * 0.42),
                to: CGPoint(x: c.x + side * 0.05, y: c.y)
            )
            cg.restoreGState()

            cg.saveGState()
            BitmapCanvas.glow(cg, blur: side * 0.05, color: tint.cgColor)
            let glyph = CGRect(x: c.x - side * 0.32, y: c.y - side * 0.32, width: side * 0.64, height: side * 0.64)
            AbilityGlyph.draw(kind: kind, in: glyph, color: .white, onto: cg)
            cg.restoreGState()
        }
    }
}
