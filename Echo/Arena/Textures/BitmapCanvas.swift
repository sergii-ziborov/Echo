import CoreGraphics
import SpriteKit

/// Offscreen Core Graphics drawing that behaves the same on iPhone and Apple
/// Watch (UIGraphicsImageRenderer does not exist on watchOS). The context is
/// y-up with its origin in the lower-left corner, like SpriteKit, so shapes
/// designed for the scene draw upright without a flip.
enum BitmapCanvas {
    static func image(size: CGSize, scale: CGFloat, draw: (CGContext) -> Void) -> CGImage? {
        let width = max(1, Int((size.width * scale).rounded(.up)))
        let height = max(1, Int((size.height * scale).rounded(.up)))
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.scaleBy(x: scale, y: scale)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        draw(context)
        return context.makeImage()
    }

    static func texture(size: CGSize, scale: CGFloat = 1, draw: (CGContext) -> Void) -> SKTexture {
        guard let image = image(size: size, scale: scale, draw: draw) else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }

    /// Core Graphics measures shadow blur in device pixels, not in the scaled
    /// user space, so convert to keep glows the same size at every scale.
    static func glow(_ cg: CGContext, blur: CGFloat, color: CGColor) {
        let pixels = abs(cg.userSpaceToDeviceSpaceTransform.a)
        cg.setShadow(offset: .zero, blur: blur * max(1, pixels), color: color)
    }

    static func radial(_ cg: CGContext, _ colors: [CGColor], at start: CGPoint, to end: CGPoint, radius: CGFloat, from inner: CGFloat = 0, locations: [CGFloat]? = nil) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return }
        cg.drawRadialGradient(gradient, startCenter: start, startRadius: inner, endCenter: end, endRadius: radius, options: [.drawsAfterEndLocation])
    }

    static func linear(_ cg: CGContext, _ colors: [CGColor], from start: CGPoint, to end: CGPoint, locations: [CGFloat]? = nil) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: locations) else { return }
        cg.drawLinearGradient(gradient, start: start, end: end, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    static func polygon(_ points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    /// A pointy-top hexagon with rounded corners.
    static func hexagon(center: CGPoint, radius: CGFloat, corner: CGFloat) -> CGPath {
        let corners = (0..<6).map { index -> CGPoint in
            let angle = CGFloat(index) / 6 * 2 * .pi + .pi / 2
            return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }
        let path = CGMutablePath()
        path.move(to: CGPoint(x: (corners[0].x + corners[1].x) / 2, y: (corners[0].y + corners[1].y) / 2))
        for index in 1...6 {
            path.addArc(tangent1End: corners[index % 6], tangent2End: corners[(index + 1) % 6], radius: corner)
        }
        path.closeSubpath()
        return path
    }
}
