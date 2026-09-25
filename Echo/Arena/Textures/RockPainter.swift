import SpriteKit
import UIKit

/// Everything the scene needs to draw one asteroid and later break it apart.
struct RockArt {
    struct Shard {
        var texture: SKTexture
        var size: CGSize
        var anchor: CGPoint
        /// Where the shard sits inside the unrotated rock.
        var centroid: CGPoint
        /// Physics outline relative to `centroid`.
        var hull: [CGPoint]
    }

    var shape: RockShape
    var texture: SKTexture
    var canvas: CGSize
    var shards: [Shard]
    /// Seconds per turn; zero keeps the rock still.
    var spin: TimeInterval
    var spinDirection: CGFloat
    var phase: CGFloat
}

/// Paints asteroids procedurally, so no two rocks share a silhouette or a
/// surface. Light comes from the upper left; the colour families keep every
/// material readable (basalt breaks slowly, ice fast, crystal glows, alloy
/// never breaks). The later families live in RockSurfaces.
@MainActor
enum RockPainter {
    struct Palette {
        var light: UIColor
        var mid: UIColor
        var dark: UIColor
        var accent: UIColor
    }

    static func art(material: AsteroidMaterial, radius: CGFloat, seed: UInt64, still: Bool, scale: CGFloat) -> RockArt {
        var rng = SplitMix64(seed: seed ^ 0xA57E_401D)
        let shape = RockShape(material: material, radius: radius, seed: seed)
        let half = radius * 1.18 + 2
        let image = paint(shape, material: material, half: half, scale: scale, rng: &rng)
        let texture = image.map { SKTexture(cgImage: $0) } ?? SKTexture()
        texture.filteringMode = .linear
        let shards = material.isBreakable
            ? shape.shards.map { shard(of: image, polygon: $0, half: half, scale: scale) }
            : []
        let slow = material.isMetallic
        return RockArt(
            shape: shape,
            texture: texture,
            canvas: CGSize(width: half * 2, height: half * 2),
            shards: shards,
            spin: still ? 0 : TimeInterval.random(in: (slow ? 13...19 : 7...13), using: &rng),
            spinDirection: Bool.random(using: &rng) ? 1 : -1,
            phase: CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        )
    }

    static func palette(for material: AsteroidMaterial, rng: inout SplitMix64) -> Palette {
        let shift = CGFloat.random(in: -0.06...0.06, using: &rng)
        func tone(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> UIColor {
            UIColor(red: min(1, max(0, r + shift)), green: min(1, max(0, g + shift)), blue: min(1, max(0, b + shift)), alpha: 1)
        }
        switch material {
        case .basalt:
            return Palette(light: tone(0.63, 0.55, 0.48), mid: tone(0.37, 0.31, 0.27), dark: tone(0.12, 0.10, 0.09), accent: UIColor(red: 1, green: 0.50, blue: 0.14, alpha: 1))
        case .ice:
            return Palette(light: tone(0.93, 0.99, 1.00), mid: tone(0.55, 0.78, 0.93), dark: tone(0.16, 0.30, 0.50), accent: .white)
        case .crystal:
            return Palette(light: tone(0.88, 0.70, 1.00), mid: tone(0.55, 0.30, 0.86), dark: tone(0.18, 0.06, 0.36), accent: UIColor(red: 0.45, green: 0.96, blue: 1, alpha: 1))
        case .alloy:
            return Palette(light: tone(0.72, 0.80, 0.92), mid: tone(0.27, 0.32, 0.41), dark: tone(0.05, 0.06, 0.09), accent: UIColor(red: 1, green: 0.78, blue: 0.32, alpha: 1))
        case .magma:
            return Palette(light: tone(0.50, 0.30, 0.22), mid: tone(0.23, 0.11, 0.08), dark: tone(0.06, 0.03, 0.03), accent: UIColor(red: 1, green: 0.50, blue: 0.10, alpha: 1))
        case .geode:
            return Palette(light: tone(0.84, 0.74, 0.60), mid: tone(0.55, 0.45, 0.34), dark: tone(0.22, 0.17, 0.13), accent: UIColor(red: 0.74, green: 0.42, blue: 1, alpha: 1))
        case .iron:
            return Palette(light: tone(0.80, 0.79, 0.78), mid: tone(0.35, 0.34, 0.34), dark: tone(0.08, 0.08, 0.09), accent: UIColor(red: 0.82, green: 0.42, blue: 0.18, alpha: 1))
        case .comet:
            return Palette(light: tone(0.97, 0.99, 1.00), mid: tone(0.66, 0.74, 0.82), dark: tone(0.20, 0.23, 0.30), accent: UIColor(red: 0.58, green: 0.92, blue: 1, alpha: 1))
        }
    }

    // MARK: - Painting

    static func paint(_ shape: RockShape, material: AsteroidMaterial, half: CGFloat, scale: CGFloat, rng: inout SplitMix64) -> CGImage? {
        let colors = palette(for: material, rng: &rng)
        let r = shape.radius
        return BitmapCanvas.image(size: CGSize(width: half * 2, height: half * 2), scale: max(1, scale)) { cg in
            cg.translateBy(x: half, y: half)
            let body = BitmapCanvas.polygon(shape.outline)

            cg.saveGState()
            cg.addPath(body)
            cg.clip()
            radial(cg, [colors.light, colors.mid, colors.dark], at: CGPoint(x: -r * 0.42, y: r * 0.46), to: CGPoint(x: r * 0.1, y: -r * 0.1), radius: r * (material.isMetallic ? 1.45 : 1.9))
            switch material {
            case .basalt: basaltSurface(cg, shape: shape, colors: colors, rng: &rng)
            case .ice: facetedSurface(cg, shape: shape, colors: colors, glow: 0.18, rng: &rng)
            case .crystal: facetedSurface(cg, shape: shape, colors: colors, glow: 0.62, rng: &rng)
            case .alloy: alloySurface(cg, shape: shape, colors: colors, rng: &rng)
            case .magma: magmaSurface(cg, shape: shape, colors: colors, rng: &rng)
            case .geode: geodeSurface(cg, shape: shape, colors: colors, rng: &rng)
            case .iron: ironSurface(cg, shape: shape, colors: colors, rng: &rng)
            case .comet: cometSurface(cg, shape: shape, colors: colors, rng: &rng)
            }
            speckle(cg, radius: r, count: Int(r * 1.4), light: colors.light, dark: colors.dark, rng: &rng)
            // Ambient occlusion toward the rim, then the terminator on the lower right.
            radial(cg, [UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.42)], at: .zero, to: .zero, radius: r * 1.18, from: r * 0.52)
            linear(cg, [UIColor.white.withAlphaComponent(0.14), UIColor.black.withAlphaComponent(0), UIColor.black.withAlphaComponent(0.34)], from: CGPoint(x: -r, y: r), to: CGPoint(x: r, y: -r))
            cg.restoreGState()

            cg.addPath(body)
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.55).cgColor)
            cg.setLineWidth(max(1, r * 0.05))
            cg.setLineJoin(.round)
            cg.strokePath()
            rimLight(cg, body, color: colors.light, width: max(1, r * 0.055), radius: r)
        }
    }

    static func basaltSurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        for _ in 0..<Int.random(in: 6...10, using: &rng) {
            let width = r * CGFloat.random(in: 0.18...0.42, using: &rng)
            let height = width * CGFloat.random(in: 0.5...1, using: &rng)
            let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            let reach = CGFloat.random(in: 0...0.8, using: &rng) * r
            let tone = Bool.random(using: &rng) ? colors.light : colors.dark
            cg.setFillColor(tone.withAlphaComponent(CGFloat.random(in: 0.1...0.2, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: cos(angle) * reach - width / 2, y: sin(angle) * reach - height / 2, width: width, height: height))
        }
        for _ in 0..<(Int.random(in: 3...5, using: &rng) + Int(r / 14)) {
            let size = r * CGFloat.random(in: 0.09...0.22, using: &rng)
            let reach = CGFloat.random(in: 0...(r * 0.8 - size), using: &rng)
            let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            crater(cg, at: CGPoint(x: cos(angle) * reach, y: sin(angle) * reach), size: size, colors: colors)
        }
        guard Int.random(in: 0..<10, using: &rng) < 4 else { return }
        cg.saveGState()
        glow(cg, blur: r * 0.18, color: colors.accent.withAlphaComponent(0.9))
        cg.setStrokeColor(colors.accent.withAlphaComponent(0.85).cgColor)
        cg.setLineWidth(max(0.8, r * 0.035))
        cg.setLineCap(.round)
        cg.setLineJoin(.round)
        for _ in 0..<Int.random(in: 1...2, using: &rng) {
            var point = CGPoint(x: CGFloat.random(in: -0.3...0.3, using: &rng) * r, y: CGFloat.random(in: -0.3...0.3, using: &rng) * r)
            var heading = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            cg.move(to: point)
            for _ in 0..<4 {
                heading += CGFloat.random(in: -0.7...0.7, using: &rng)
                point = CGPoint(x: point.x + cos(heading) * r * 0.2, y: point.y + sin(heading) * r * 0.2)
                cg.addLine(to: point)
            }
        }
        cg.strokePath()
        cg.restoreGState()
    }

    static func crater(_ cg: CGContext, at center: CGPoint, size: CGFloat, colors: Palette) {
        let rim = CGRect(x: center.x - size, y: center.y - size, width: size * 2, height: size * 2)
        cg.saveGState()
        cg.addEllipse(in: rim)
        cg.clip()
        cg.setFillColor(colors.dark.withAlphaComponent(0.8).cgColor)
        cg.fill(rim)
        // The wall facing the light (lower right) catches it; the upper left stays in shadow.
        let lit = CGRect(x: center.x - size * 0.66, y: center.y - size * 1.08, width: size * 1.74, height: size * 1.74)
        cg.setFillColor(colors.mid.withAlphaComponent(0.85).cgColor)
        cg.fillEllipse(in: lit)
        cg.restoreGState()
        cg.setStrokeColor(colors.light.withAlphaComponent(0.28).cgColor)
        cg.setLineWidth(max(0.6, size * 0.16))
        cg.addArc(center: center, radius: size, startAngle: .pi * 0.35, endAngle: .pi * 1.15, clockwise: false)
        cg.strokePath()
    }

    static func facetedSurface(_ cg: CGContext, shape: RockShape, colors: Palette, glow: CGFloat, rng: inout SplitMix64) {
        let r = shape.radius
        let hub = CGPoint(x: CGFloat.random(in: -0.25...0.25, using: &rng) * r, y: CGFloat.random(in: -0.25...0.25, using: &rng) * r)
        let corners = shape.outline.count > 24 ? stride(from: 0, to: shape.outline.count, by: 4).map { shape.outline[$0] } : shape.outline
        for index in corners.indices {
            let a = corners[index]
            let b = corners[(index + 1) % corners.count]
            let facing = ((a.x + b.x) * -0.5 + (a.y + b.y) * 0.5) / (r * 2)
            let shade = facing + CGFloat.random(in: -0.18...0.18, using: &rng)
            cg.move(to: hub)
            cg.addLine(to: a)
            cg.addLine(to: b)
            cg.closePath()
            let tone = shade > 0 ? UIColor.white.withAlphaComponent(min(0.32, shade * 0.5)) : colors.dark.withAlphaComponent(min(0.4, -shade * 0.6))
            cg.setFillColor(tone.cgColor)
            cg.fillPath()
        }
        if glow > 0.3 {
            radial(cg, [colors.accent.withAlphaComponent(glow), colors.accent.withAlphaComponent(0)], at: hub, to: hub, radius: r * 0.55)
        }
        cg.saveGState()
        if glow > 0.3 {
            Self.glow(cg, blur: r * 0.12, color: colors.accent)
        }
        cg.setStrokeColor((glow > 0.3 ? colors.accent : UIColor.white).withAlphaComponent(glow > 0.3 ? 0.8 : 0.42).cgColor)
        cg.setLineWidth(max(0.6, r * 0.028))
        for corner in corners {
            cg.move(to: hub)
            cg.addLine(to: corner)
        }
        cg.strokePath()
        cg.restoreGState()
        for _ in 0..<Int.random(in: 2...4, using: &rng) {
            let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            let reach = CGFloat.random(in: 0.2...0.7, using: &rng) * r
            glint(cg, at: CGPoint(x: cos(angle) * reach, y: sin(angle) * reach), size: r * CGFloat.random(in: 0.08...0.15, using: &rng))
        }
    }

    static func alloySurface(_ cg: CGContext, shape: RockShape, colors: Palette, rng: inout SplitMix64) {
        let r = shape.radius
        let ring = r * CGFloat.random(in: 0.52...0.64, using: &rng)
        cg.setLineWidth(max(0.8, r * 0.04))
        cg.setStrokeColor(colors.dark.withAlphaComponent(0.7).cgColor)
        cg.strokeEllipse(in: CGRect(x: -ring, y: -ring, width: ring * 2, height: ring * 2))
        cg.setStrokeColor(colors.light.withAlphaComponent(0.3).cgColor)
        cg.strokeEllipse(in: CGRect(x: -ring - 1, y: -ring + 1, width: ring * 2, height: ring * 2))
        let seams = Int.random(in: 5...8, using: &rng)
        let turn = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        for index in 0..<seams {
            let angle = turn + CGFloat(index) / CGFloat(seams) * 2 * .pi
            cg.setStrokeColor(colors.dark.withAlphaComponent(0.55).cgColor)
            cg.move(to: CGPoint(x: cos(angle) * ring, y: sin(angle) * ring))
            cg.addLine(to: CGPoint(x: cos(angle) * r * 1.2, y: sin(angle) * r * 1.2))
            cg.strokePath()
            let rivet = CGPoint(x: cos(angle + 0.22) * r * 0.8, y: sin(angle + 0.22) * r * 0.8)
            let dot = max(0.9, r * 0.045)
            cg.setFillColor(colors.dark.withAlphaComponent(0.8).cgColor)
            cg.fillEllipse(in: CGRect(x: rivet.x - dot, y: rivet.y - dot, width: dot * 2, height: dot * 2))
            cg.setFillColor(colors.light.withAlphaComponent(0.7).cgColor)
            cg.fillEllipse(in: CGRect(x: rivet.x - dot * 0.9, y: rivet.y - dot * 0.2, width: dot, height: dot))
        }
        let start = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        cg.saveGState()
        glow(cg, blur: r * 0.1, color: colors.accent.withAlphaComponent(0.8))
        cg.setStrokeColor(colors.accent.withAlphaComponent(0.9).cgColor)
        cg.setLineWidth(max(1, r * 0.07))
        cg.setLineCap(.round)
        cg.addArc(center: .zero, radius: ring, startAngle: start, endAngle: start + CGFloat.random(in: 0.9...1.8, using: &rng), clockwise: false)
        cg.strokePath()
        cg.restoreGState()
        let hub = r * 0.16
        radial(cg, [colors.accent.withAlphaComponent(0.9), colors.accent.withAlphaComponent(0.25)], at: CGPoint(x: -hub * 0.3, y: hub * 0.3), to: .zero, radius: hub)
        let glare = CGPoint(x: -r * 0.4, y: r * 0.44)
        radial(cg, [UIColor.white.withAlphaComponent(0.5), UIColor.white.withAlphaComponent(0)], at: glare, to: glare, radius: r * 0.42)
        // A polished band across the hull reads as metal rather than stone.
        let tilt = CGFloat.random(in: 0.5...1.1, using: &rng)
        let across = CGVector(dx: cos(tilt + .pi / 2) * r * 0.3, dy: sin(tilt + .pi / 2) * r * 0.3)
        let middle = CGPoint(x: -r * 0.12, y: r * 0.1)
        linear(
            cg,
            [UIColor.white.withAlphaComponent(0), UIColor.white.withAlphaComponent(0.2), UIColor.white.withAlphaComponent(0)],
            from: CGPoint(x: middle.x - across.dx, y: middle.y - across.dy),
            to: CGPoint(x: middle.x + across.dx, y: middle.y + across.dy)
        )
    }

    // MARK: - Shards

    static func shard(of image: CGImage?, polygon: [CGPoint], half: CGFloat, scale: CGFloat) -> RockArt.Shard {
        let xs = polygon.map(\.x)
        let ys = polygon.map(\.y)
        let bounds = CGRect(
            x: (xs.min() ?? 0) - 1,
            y: (ys.min() ?? 0) - 1,
            width: (xs.max() ?? 0) - (xs.min() ?? 0) + 2,
            height: (ys.max() ?? 0) - (ys.min() ?? 0) + 2
        )
        let cut = BitmapCanvas.image(size: bounds.size, scale: max(1, scale)) { cg in
            cg.translateBy(x: -bounds.minX, y: -bounds.minY)
            let outline = BitmapCanvas.polygon(polygon)
            cg.addPath(outline)
            cg.clip()
            if let image {
                cg.draw(image, in: CGRect(x: -half, y: -half, width: half * 2, height: half * 2))
            }
            cg.addPath(outline)
            cg.setStrokeColor(UIColor.black.withAlphaComponent(0.45).cgColor)
            cg.setLineWidth(1)
            cg.strokePath()
        }
        let texture = cut.map { SKTexture(cgImage: $0) } ?? SKTexture()
        texture.filteringMode = .linear
        let centroid = RockShape.centroid(polygon)
        return RockArt.Shard(
            texture: texture,
            size: bounds.size,
            anchor: CGPoint(x: (centroid.x - bounds.minX) / bounds.width, y: (centroid.y - bounds.minY) / bounds.height),
            centroid: centroid,
            hull: RockShape.hull(polygon.map { CGPoint(x: $0.x - centroid.x, y: $0.y - centroid.y) })
        )
    }

    // MARK: - Drawing helpers

    static func radial(_ cg: CGContext, _ colors: [UIColor], at start: CGPoint, to end: CGPoint, radius: CGFloat, from inner: CGFloat = 0) {
        BitmapCanvas.radial(cg, colors.map(\.cgColor), at: start, to: end, radius: radius, from: inner)
    }

    static func linear(_ cg: CGContext, _ colors: [UIColor], from start: CGPoint, to end: CGPoint) {
        BitmapCanvas.linear(cg, colors.map(\.cgColor), from: start, to: end)
    }

    static func glow(_ cg: CGContext, blur: CGFloat, color: UIColor) {
        BitmapCanvas.glow(cg, blur: blur, color: color.cgColor)
    }

    static func rimLight(_ cg: CGContext, _ body: CGPath, color: UIColor, width: CGFloat, radius: CGFloat) {
        cg.saveGState()
        cg.addPath(body)
        cg.setLineWidth(width)
        cg.setLineJoin(.round)
        cg.replacePathWithStrokedPath()
        cg.clip()
        linear(cg, [color.withAlphaComponent(0.9), color.withAlphaComponent(0)], from: CGPoint(x: -radius * 0.8, y: radius * 0.8), to: CGPoint(x: radius * 0.25, y: -radius * 0.25))
        cg.restoreGState()
    }

    static func speckle(_ cg: CGContext, radius: CGFloat, count: Int, light: UIColor, dark: UIColor, rng: inout SplitMix64) {
        for _ in 0..<max(8, count) {
            let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            let reach = sqrt(CGFloat.random(in: 0...1, using: &rng)) * radius
            let size = CGFloat.random(in: 0.3...1.1, using: &rng) * max(1, radius / 26)
            let tone = Bool.random(using: &rng) ? light : dark
            cg.setFillColor(tone.withAlphaComponent(CGFloat.random(in: 0.12...0.34, using: &rng)).cgColor)
            cg.fillEllipse(in: CGRect(x: cos(angle) * reach - size / 2, y: sin(angle) * reach - size / 2, width: size, height: size))
        }
    }

    static func glint(_ cg: CGContext, at point: CGPoint, size: CGFloat) {
        cg.setFillColor(UIColor.white.withAlphaComponent(0.8).cgColor)
        cg.move(to: CGPoint(x: point.x, y: point.y + size))
        cg.addLine(to: CGPoint(x: point.x + size * 0.18, y: point.y))
        cg.addLine(to: CGPoint(x: point.x, y: point.y - size))
        cg.addLine(to: CGPoint(x: point.x - size * 0.18, y: point.y))
        cg.closePath()
        cg.move(to: CGPoint(x: point.x - size * 0.7, y: point.y))
        cg.addLine(to: CGPoint(x: point.x, y: point.y + size * 0.14))
        cg.addLine(to: CGPoint(x: point.x + size * 0.7, y: point.y))
        cg.addLine(to: CGPoint(x: point.x, y: point.y - size * 0.14))
        cg.closePath()
        cg.fillPath()
    }
}
