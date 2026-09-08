import SpriteKit
import UIKit

enum GlowTextures {
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

    static func hexCore(color: UIColor, size: CGFloat) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let inset = size * 0.18
            let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
            let path = hexagon(in: rect)
            cg.setStrokeColor(color.cgColor)
            cg.setLineWidth(size * 0.06)
            cg.setLineJoin(.round)
            cg.addPath(path)
            cg.strokePath()
            cg.setFillColor(UIColor.white.withAlphaComponent(0.92).cgColor)
            let coreR = size * 0.16
            cg.fillEllipse(in: CGRect(x: size / 2 - coreR, y: size / 2 - coreR, width: coreR * 2, height: coreR * 2))
        }
        return SKTexture(image: image)
    }

    private static func hexagon(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        let cx = rect.midX
        let cy = rect.midY
        let r = min(rect.width, rect.height) / 2
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let p = CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}
