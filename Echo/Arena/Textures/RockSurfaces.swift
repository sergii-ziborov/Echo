import UIKit

/// Surfaces for the later rock families. Each one reads at a glance even at
/// a few dozen points: molten fissures, banded stone with crystal pockets,
/// pitted meteoric metal, and a dusty snowball with venting jets.
extension RockPainter {
    static func magmaSurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        // Heat bleeding through the crust from the core.
        radial(cg, [colors.accent.withAlphaComponent(0.28), colors.accent.withAlphaComponent(0)], at: .zero, to: .zero, radius: r * 0.95)
        for _ in 0..<Int.random(in: 5...8, using: &rng) {
            let size = r * CGFloat.random(in: 0.2...0.38, using: &rng)
            let at = scatter(r * 0.75, rng: &rng)
            cg.setFillColor(colors.dark.withAlphaComponent(CGFloat.random(in: 0.3...0.5, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: at.x - size / 2, y: at.y - size * 0.4, width: size, height: size * 0.8))
        }
        let fissures = cracks(r, count: Int.random(in: 4...6, using: &rng), steps: 4...6, rng: &rng)
        cg.saveGState()
        glow(cg, blur: r * 0.24, color: colors.accent)
        cg.setStrokeColor(colors.accent.withAlphaComponent(0.95).cgColor)
        cg.setLineWidth(max(1, r * 0.065))
        cg.setLineCap(.round)
        cg.setLineJoin(.round)
        cg.addPath(fissures)
        cg.strokePath()
        cg.restoreGState()
        cg.setStrokeColor(UIColor(red: 1, green: 0.9, blue: 0.56, alpha: 0.9).cgColor)
        cg.setLineWidth(max(0.5, r * 0.022))
        cg.setLineCap(.round)
        cg.addPath(fissures)
        cg.strokePath()
        for _ in 0..<Int.random(in: 2...3, using: &rng) {
            let at = scatter(r * 0.6, rng: &rng)
            radial(cg, [UIColor(red: 1, green: 0.86, blue: 0.5, alpha: 0.8), colors.accent.withAlphaComponent(0)], at: at, to: at, radius: r * CGFloat.random(in: 0.1...0.18, using: &rng))
        }
    }

    static func geodeSurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        // Banded layers, like the cut face of an agate.
        let core = scatter(r * 0.3, rng: &rng)
        let squash = CGFloat.random(in: 0.7...0.95, using: &rng)
        for band in 0..<4 {
            let size = r * (0.3 + CGFloat(band) * 0.19)
            let tone = band.isMultiple(of: 2) ? colors.light : colors.dark
            cg.setStrokeColor(tone.withAlphaComponent(0.2).cgColor)
            cg.setLineWidth(max(0.8, r * 0.05))
            cg.strokeEllipse(in: CGRect(x: core.x - size, y: core.y - size * squash, width: size * 2, height: size * 2 * squash))
        }
        speckle(cg, radius: r, count: Int(r * 2.2), light: colors.light, dark: colors.dark, rng: &rng)
        for _ in 0..<Int.random(in: 1...2, using: &rng) {
            let size = r * CGFloat.random(in: 0.18...0.28, using: &rng)
            crystalPocket(cg, at: scatter(r * 0.62 - size, rng: &rng), size: size, colors: colors, rng: &rng)
        }
    }

    /// A pit in the stone whose walls are lined with violet crystal.
    static func crystalPocket(_ cg: CGContext, at center: CGPoint, size: CGFloat, colors: Palette, rng: inout SplitMix64) {
        let rim = CGRect(x: center.x - size, y: center.y - size * 0.8, width: size * 2, height: size * 1.6)
        cg.saveGState()
        cg.addEllipse(in: rim)
        cg.clip()
        cg.setFillColor(UIColor(red: 0.16, green: 0.06, blue: 0.26, alpha: 1).cgColor)
        cg.fill(rim)
        let facets = 7
        let turn = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        for index in 0..<facets {
            let a = turn + CGFloat(index) / CGFloat(facets) * 2 * .pi
            let b = turn + CGFloat(index + 1) / CGFloat(facets) * 2 * .pi
            cg.move(to: center)
            cg.addLine(to: CGPoint(x: center.x + cos(a) * size * 1.2, y: center.y + sin(a) * size))
            cg.addLine(to: CGPoint(x: center.x + cos(b) * size * 1.2, y: center.y + sin(b) * size))
            cg.closePath()
            let lit = sin(a + .pi / 4) > 0
            cg.setFillColor(colors.accent.withAlphaComponent(lit ? 0.85 : 0.45).cgColor)
            cg.fillPath()
        }
        radial(cg, [UIColor.white.withAlphaComponent(0.55), colors.accent.withAlphaComponent(0)], at: center, to: center, radius: size * 0.6)
        cg.restoreGState()
        cg.setStrokeColor(colors.dark.withAlphaComponent(0.85).cgColor)
        cg.setLineWidth(max(0.8, size * 0.16))
        cg.strokeEllipse(in: rim)
        glint(cg, at: CGPoint(x: center.x - size * 0.3, y: center.y + size * 0.2), size: size * 0.5)
    }

    static func ironSurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        // Rust where the fusion crust weathered.
        for _ in 0..<Int.random(in: 3...5, using: &rng) {
            let size = r * CGFloat.random(in: 0.18...0.34, using: &rng)
            let at = scatter(r * 0.72, rng: &rng)
            cg.setFillColor(colors.accent.withAlphaComponent(CGFloat.random(in: 0.16...0.3, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: at.x - size / 2, y: at.y - size / 2, width: size, height: size * 0.85))
        }
        // Regmaglypts: shallow thumbprints melted in on the way down.
        for _ in 0..<(Int.random(in: 6...9, using: &rng) + Int(r / 12)) {
            let size = r * CGFloat.random(in: 0.08...0.16, using: &rng)
            let at = scatter(r * 0.82 - size, rng: &rng)
            let dent = CGRect(x: at.x - size, y: at.y - size * 0.8, width: size * 2, height: size * 1.6)
            cg.setFillColor(colors.dark.withAlphaComponent(0.35).cgColor)
            cg.fillEllipse(in: dent.offsetBy(dx: -size * 0.12, dy: size * 0.12))
            cg.setFillColor(colors.light.withAlphaComponent(0.16).cgColor)
            cg.fillEllipse(in: dent.insetBy(dx: size * 0.3, dy: size * 0.3).offsetBy(dx: size * 0.2, dy: -size * 0.2))
        }
        // One cut, polished face shows the crossing crystal bands of meteoric iron.
        let face = scatter(r * 0.25, rng: &rng)
        let span = r * CGFloat.random(in: 0.34...0.44, using: &rng)
        cg.saveGState()
        cg.addEllipse(in: CGRect(x: face.x - span, y: face.y - span * 0.7, width: span * 2, height: span * 1.4))
        cg.clip()
        radial(cg, [colors.light.withAlphaComponent(0.55), colors.mid.withAlphaComponent(0.2)], at: face, to: face, radius: span)
        cg.setStrokeColor(colors.light.withAlphaComponent(0.34).cgColor)
        cg.setLineWidth(max(0.5, r * 0.012))
        let tilt = CGFloat.random(in: 0..<(.pi), using: &rng)
        for set in 0..<3 {
            let angle = tilt + CGFloat(set) * .pi / 3
            let along = CGVector(dx: cos(angle), dy: sin(angle))
            let across = CGVector(dx: -along.dy, dy: along.dx)
            for line in -4...4 {
                let offset = CGFloat(line) * span * 0.2
                cg.move(to: CGPoint(x: face.x + across.dx * offset - along.dx * span, y: face.y + across.dy * offset - along.dy * span))
                cg.addLine(to: CGPoint(x: face.x + across.dx * offset + along.dx * span, y: face.y + across.dy * offset + along.dy * span))
            }
        }
        cg.strokePath()
        cg.restoreGState()
        let glare = CGPoint(x: -r * 0.38, y: r * 0.42)
        radial(cg, [UIColor.white.withAlphaComponent(0.55), UIColor.white.withAlphaComponent(0)], at: glare, to: glare, radius: r * 0.36)
    }

    static func cometSurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        // Dust that the sun has not boiled off yet.
        for _ in 0..<Int.random(in: 4...7, using: &rng) {
            let size = r * CGFloat.random(in: 0.18...0.4, using: &rng)
            let at = scatter(r * 0.7, rng: &rng)
            cg.setFillColor(colors.dark.withAlphaComponent(CGFloat.random(in: 0.3...0.55, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: at.x - size / 2, y: at.y - size * 0.35, width: size, height: size * 0.7))
        }
        for _ in 0..<Int(r * 1.6) {
            let at = scatter(r * 0.95, rng: &rng)
            let dot = CGFloat.random(in: 0.3...0.9, using: &rng) * max(1, r / 24)
            cg.setFillColor(UIColor.white.withAlphaComponent(CGFloat.random(in: 0.3...0.7, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: at.x - dot / 2, y: at.y - dot / 2, width: dot, height: dot))
        }
        // Venting jets glow where sunlight reaches fresh ice.
        for _ in 0..<Int.random(in: 1...2, using: &rng) {
            let angle = CGFloat.random(in: 0.3...2.2, using: &rng)
            let at = CGPoint(x: cos(angle) * r * 0.62, y: sin(angle) * r * 0.62)
            radial(cg, [UIColor.white.withAlphaComponent(0.9), colors.accent.withAlphaComponent(0)], at: at, to: at, radius: r * 0.2)
        }
    }

    // MARK: - Helpers

    /// A uniformly scattered point inside a disc.
    static func scatter(_ radius: CGFloat, rng: inout SplitMix64) -> CGPoint {
        let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        let reach = sqrt(CGFloat.random(in: 0...1, using: &rng)) * max(0, radius)
        return CGPoint(x: cos(angle) * reach, y: sin(angle) * reach)
    }

    /// Wandering fissures that start near the middle and run outward.
    static func cracks(_ radius: CGFloat, count: Int, steps: ClosedRange<Int>, rng: inout SplitMix64) -> CGPath {
        let path = CGMutablePath()
        for _ in 0..<count {
            var point = scatter(radius * 0.3, rng: &rng)
            var heading = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            path.move(to: point)
            for _ in 0..<Int.random(in: steps, using: &rng) {
                heading += CGFloat.random(in: -0.6...0.6, using: &rng)
                point = CGPoint(x: point.x + cos(heading) * radius * 0.17, y: point.y + sin(heading) * radius * 0.17)
                path.addLine(to: point)
            }
        }
        return path
    }
}
