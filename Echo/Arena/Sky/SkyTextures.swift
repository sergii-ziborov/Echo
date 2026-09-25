import SpriteKit
import UIKit

/// Procedural textures for the region landmarks, drawn once per map with
/// the portable bitmap canvas so the phone and the watch paint them alike.
extension Backdrop {
    private static let side: CGFloat = 256

    private static func scatter(_ radius: CGFloat, rng: inout SplitMix64) -> CGPoint {
        let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
        let reach = sqrt(CGFloat.random(in: 0...1, using: &rng)) * radius
        return CGPoint(x: side / 2 + cos(angle) * reach, y: side / 2 + sin(angle) * reach)
    }

    /// A star's face: a white-hot middle, granulation, a few spots and a
    /// darker limb.
    static func sunTexture(core: UIColor, corona: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let r = side / 2
        let middle = CGPoint(x: r, y: r)
        let grains = (0..<260).map { _ in (scatter(r * 0.95, rng: &rng), CGFloat.random(in: 2...7, using: &rng), CGFloat.random(in: 0.05...0.14, using: &rng)) }
        let spots = (0..<Int.random(in: 2...4, using: &rng)).map { _ in (scatter(r * 0.7, rng: &rng), CGFloat.random(in: 5...12, using: &rng)) }
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
            cg.clip()
            BitmapCanvas.radial(cg, [UIColor.white.cgColor, core.blended(with: .white, amount: 0.35).cgColor, core.cgColor, corona.cgColor], at: middle, to: middle, radius: r, locations: [0, 0.3, 0.72, 1])
            for (point, size, alpha) in grains {
                cg.setFillColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                cg.fillEllipse(in: CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size))
            }
            for (point, size) in spots {
                cg.setFillColor(corona.blended(with: .black, amount: 0.55).withAlphaComponent(0.4).cgColor)
                cg.fillEllipse(in: CGRect(x: point.x - size, y: point.y - size * 0.7, width: size * 2, height: size * 1.4))
            }
            BitmapCanvas.radial(cg, [UIColor.black.withAlphaComponent(0).cgColor, UIColor.black.withAlphaComponent(0.35).cgColor], at: middle, to: middle, radius: r, from: r * 0.7)
        }
    }

    /// A cratered moon; `cracks` receives the fissures so a glow can pulse on them.
    static func moonTexture(base: UIColor, glow: UIColor, scale: CGFloat, cracks: inout CGPath, rng: inout SplitMix64) -> SKTexture {
        let r = side / 2
        let middle = CGPoint(x: r, y: r)
        let craters = (0..<12).map { _ in (scatter(r * 0.82, rng: &rng), CGFloat.random(in: 6...24, using: &rng)) }
        let path = CGMutablePath()
        for _ in 0..<5 {
            var point = scatter(r * 0.25, rng: &rng)
            var heading = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            path.move(to: point)
            for _ in 0..<6 {
                heading += CGFloat.random(in: -0.5...0.5, using: &rng)
                point = CGPoint(x: point.x + cos(heading) * r * 0.16, y: point.y + sin(heading) * r * 0.16)
                path.addLine(to: point)
            }
        }
        cracks = path
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
            cg.clip()
            BitmapCanvas.radial(cg, [base.blended(with: .white, amount: 0.3).cgColor, base.cgColor, base.blended(with: .black, amount: 0.5).cgColor], at: CGPoint(x: r * 0.8, y: r * 1.2), to: middle, radius: r * 1.2)
            for (point, size) in craters {
                let rim = CGRect(x: point.x - size, y: point.y - size, width: size * 2, height: size * 2)
                cg.setFillColor(base.blended(with: .black, amount: 0.4).withAlphaComponent(0.55).cgColor)
                cg.fillEllipse(in: rim)
                cg.setStrokeColor(base.blended(with: .white, amount: 0.4).withAlphaComponent(0.35).cgColor)
                cg.setLineWidth(1.5)
                cg.strokeEllipse(in: rim.insetBy(dx: 1, dy: 1))
            }
            cg.setStrokeColor(glow.withAlphaComponent(0.35).cgColor)
            cg.setLineWidth(2)
            cg.setLineCap(.round)
            cg.addPath(path)
            cg.strokePath()
        }
    }

    static func crackGlowTexture(_ cracks: CGPath, glow: UIColor, scale: CGFloat) -> SKTexture {
        BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
            cg.clip()
            cg.saveGState()
            BitmapCanvas.glow(cg, blur: 8, color: glow.cgColor)
            cg.setStrokeColor(glow.cgColor)
            cg.setLineWidth(3)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            cg.addPath(cracks)
            cg.strokePath()
            cg.restoreGState()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.8).cgColor)
            cg.setLineWidth(1)
            cg.addPath(cracks)
            cg.strokePath()
        }
    }

    /// A molten seam running right across a broken world.
    static func faultTexture(glow: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -4, y: 70))
        for step in 1...10 {
            let x = side * CGFloat(step) / 10
            path.addLine(to: CGPoint(x: x, y: 70 + 120 * CGFloat(step) / 10 + CGFloat.random(in: -16...16, using: &rng)))
        }
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: side, height: side))
            cg.clip()
            cg.saveGState()
            BitmapCanvas.glow(cg, blur: 12, color: glow.cgColor)
            cg.setStrokeColor(glow.withAlphaComponent(0.9).cgColor)
            cg.setLineWidth(7)
            cg.setLineJoin(.round)
            cg.addPath(path)
            cg.strokePath()
            cg.restoreGState()
            cg.setStrokeColor(UIColor(red: 1, green: 0.92, blue: 0.6, alpha: 0.9).cgColor)
            cg.setLineWidth(2)
            cg.addPath(path)
            cg.strokePath()
        }
    }

    /// A ring of rubble seen face on; tilting its node lays it into orbit.
    static func rubbleTexture(tint: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let r = side / 2
        let rocks = (0..<220).map { _ -> (CGPoint, CGFloat, CGFloat, Bool) in
            let angle = CGFloat.random(in: 0..<(2 * .pi), using: &rng)
            let reach = r * CGFloat.random(in: 0.72...0.97, using: &rng)
            return (CGPoint(x: r + cos(angle) * reach, y: r + sin(angle) * reach), CGFloat.random(in: 1.5...4.5, using: &rng), CGFloat.random(in: 0.35...0.9, using: &rng), Bool.random(using: &rng))
        }
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            for (point, size, alpha, light) in rocks {
                cg.setFillColor((light ? tint : tint.blended(with: .black, amount: 0.4)).withAlphaComponent(alpha).cgColor)
                cg.fillEllipse(in: CGRect(x: point.x - size / 2, y: point.y - size * 0.35, width: size, height: size * 0.7))
            }
        }
    }

    /// An accretion disc face on: white-hot inside, streaked, fading out.
    static func accretionTexture(tint: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let r = side / 2
        let middle = CGPoint(x: r, y: r)
        let streaks = (0..<90).map { _ in
            (r * CGFloat.random(in: 0.42...0.95, using: &rng), CGFloat.random(in: 0..<(2 * .pi), using: &rng), CGFloat.random(in: 0.3...1.2, using: &rng), CGFloat.random(in: 1...2.5, using: &rng), CGFloat.random(in: 0.1...0.35, using: &rng))
        }
        return BitmapCanvas.texture(size: CGSize(width: side, height: side), scale: scale) { cg in
            BitmapCanvas.radial(cg, [UIColor.white.cgColor, tint.cgColor, tint.withAlphaComponent(0).cgColor], at: middle, to: middle, radius: r, from: r * 0.38, locations: [0, 0.3, 1])
            cg.setLineCap(.round)
            for (radius, start, sweep, width, alpha) in streaks {
                cg.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                cg.setLineWidth(width)
                cg.addArc(center: middle, radius: radius, startAngle: start, endAngle: start + sweep, clockwise: false)
                cg.strokePath()
            }
            // The hole's own shadow is drawn by the scene; keep the middle clear.
            cg.setBlendMode(.clear)
            cg.fillEllipse(in: CGRect(x: r - r * 0.36, y: r - r * 0.36, width: r * 0.72, height: r * 0.72))
        }
    }

    /// A jagged tear of light, lying left to right.
    static func tearTexture(glow: UIColor, scale: CGFloat, rng: inout SplitMix64) -> SKTexture {
        let size = CGSize(width: 512, height: 96)
        let path = CGMutablePath()
        var point = CGPoint(x: 12, y: size.height / 2)
        path.move(to: point)
        for step in 1...14 {
            point = CGPoint(x: 12 + (size.width - 24) * CGFloat(step) / 14, y: size.height / 2 + CGFloat.random(in: -20...20, using: &rng))
            path.addLine(to: point)
            if step % 4 == 2 {
                path.move(to: point)
                path.addLine(to: CGPoint(x: point.x + CGFloat.random(in: 10...30, using: &rng), y: point.y + CGFloat.random(in: -26...26, using: &rng)))
                path.move(to: point)
            }
        }
        return BitmapCanvas.texture(size: size, scale: scale) { cg in
            cg.saveGState()
            BitmapCanvas.glow(cg, blur: 14, color: glow.cgColor)
            cg.setStrokeColor(glow.cgColor)
            cg.setLineWidth(6)
            cg.setLineCap(.round)
            cg.setLineJoin(.round)
            cg.addPath(path)
            cg.strokePath()
            cg.restoreGState()
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.9).cgColor)
            cg.setLineWidth(2)
            cg.addPath(path)
            cg.strokePath()
        }
    }
}
