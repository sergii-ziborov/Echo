import SpriteKit
import UIKit

extension GlowTextures {
    static func makeGlowMask(pixelSize: Int, tint: UIColor = .white) -> SKTexture {
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

    static func makeRing(color: UIColor, size: CGFloat) -> SKTexture {
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

    static func hexPath(in rect: CGRect) -> CGPath {
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

    static func transparentImage(size: CGFloat, draw: (CGContext) -> Void) -> UIImage {
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

    static func circularized(_ texture: SKTexture) -> SKTexture {
        let image = UIImage(cgImage: texture.cgImage())
        let masked = SKTexture(image: circularMasked(image))
        masked.filteringMode = .linear
        return masked
    }

    static func circularMasked(_ image: UIImage) -> UIImage {
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

    static func assembleOrb(color: UIColor, size: CGFloat = 256) -> SKTexture {
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

    static func quadrant(of atlas: UIImage?, top: Bool, right: Bool) -> SKTexture? {
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

    static func frostVignetteTexture(size: CGFloat) -> SKTexture {
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

    static func snowflakeTexture(size: CGFloat) -> SKTexture {
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

    static func shieldBubbleTexture(size: CGFloat) -> SKTexture {
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
