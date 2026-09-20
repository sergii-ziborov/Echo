import SwiftUI

extension TechnologyPreviewView {
    func point(_ start: CGPoint, _ end: CGPoint, _ amount: Double) -> CGPoint {
        let value = CGFloat(max(0, min(1, amount)))
        return CGPoint(x: start.x + (end.x - start.x) * value, y: start.y + (end.y - start.y) * value)
    }

    func techOrb(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, hollow: Bool = false) {
        let glow = CGRect(x: center.x - radius * 1.8, y: center.y - radius * 1.8, width: radius * 3.6, height: radius * 3.6)
        context.fill(Circle().path(in: glow), with: .color(color.opacity(0.14)))
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        if !hollow { context.fill(Circle().path(in: rect), with: .color(color.opacity(0.94))) }
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.96)), lineWidth: hollow ? 2.2 : 1.2)
    }

    func techRing(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, width: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(max(0, min(1, opacity)))), lineWidth: width)
    }

    func techArc(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, progress: Double, color: Color, width: CGFloat) {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    func techLine(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dashed ? [5, 5] : []))
    }

    func techLightning(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        color: Color,
        seed: Int
    ) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let px = -dy / length
        let py = dx / length
        var path = Path()
        var points: [CGPoint] = []
        for index in 0...8 {
            let amount = CGFloat(index) / 8
            let envelope = sin(amount * .pi)
            let noise = sin(CGFloat(seed * 23 + index * 41) * 0.79) * 6.5 * envelope
            let point = CGPoint(x: start.x + dx * amount + px * noise, y: start.y + dy * amount + py * noise)
            points.append(point)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        for (index, direction) in [(3, CGFloat(1)), (6, CGFloat(-1))] {
            let source = points[index]
            path.move(to: source)
            path.addLine(to: CGPoint(x: source.x - 7, y: source.y + direction * 10))
        }
        context.stroke(path, with: .color(color.opacity(0.13)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(color.opacity(0.62)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(.white.opacity(0.98)), style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round))
    }

    func techSnowflake(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
        var path = Path()
        for branch in 0..<3 {
            let angle = CGFloat(branch) / 3 * .pi
            let delta = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            path.move(to: CGPoint(x: center.x - delta.x, y: center.y - delta.y))
            path.addLine(to: CGPoint(x: center.x + delta.x, y: center.y + delta.y))
        }
        context.stroke(path, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
    }

    func techIceShell(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: rect), with: .color(EchoTheme.cyan.opacity(0.10)))
        context.stroke(Circle().path(in: rect), with: .color(.white.opacity(0.74)), lineWidth: 1.1)
        for index in 0..<7 {
            let angle = CGFloat(index) / 7 * .pi * 2
            var shard = Path()
            shard.move(to: CGPoint(x: center.x + cos(angle) * radius * 0.70, y: center.y + sin(angle) * radius * 0.70))
            shard.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            context.stroke(shard, with: .color(EchoTheme.cyan.opacity(0.78)), lineWidth: 0.9)
        }
    }

    func techShieldBubble(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        layers: Int,
        impact: Bool,
        strength: Double
    ) {
        for layer in stride(from: layers - 1, through: 0, by: -1) {
            let value = radius + CGFloat(layer) * 10
            let rect = CGRect(x: center.x - value, y: center.y - value, width: value * 2, height: value * 2)
            let imageRect = rect.insetBy(dx: -value * 0.11, dy: -value * 0.11)
            var membrane = context
            membrane.opacity = layer == 0 ? 0.72 : 0.38
            membrane.draw(Image("ShieldBubbleV2"), in: imageRect)
            context.stroke(Circle().path(in: rect), with: .color((layer == 0 ? Color.green : .white).opacity(0.50 + strength * 0.30)), lineWidth: layer == 0 ? 1.7 : 1)
        }
        var highlight = Path()
        highlight.addArc(center: center, radius: radius - 2, startAngle: .degrees(205), endAngle: .degrees(292), clockwise: false)
        context.stroke(highlight, with: .color(.white.opacity(0.78)), style: StrokeStyle(lineWidth: 2.1, lineCap: .round))
        if impact {
            var cracks = Path()
            let hit = CGPoint(x: center.x - radius, y: center.y)
            for index in 0..<4 {
                let joint = CGPoint(x: hit.x + 10, y: hit.y + CGFloat(index - 2) * 4)
                cracks.move(to: hit)
                cracks.addLine(to: joint)
                cracks.addLine(to: CGPoint(x: joint.x + 8, y: joint.y + CGFloat(index.isMultiple(of: 2) ? 8 : -7)))
            }
            context.stroke(cracks, with: .color(.white.opacity(0.95)), style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))
        }
    }

    func techMagneticField(
        context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        phase: Double
    ) {
        for index in 0..<4 {
            let scale = 0.58 + CGFloat(index) * 0.14
            var path = Path()
            let north = CGPoint(x: center.x, y: center.y - 16)
            let south = CGPoint(x: center.x, y: center.y + 16)
            path.move(to: north)
            path.addCurve(
                to: south,
                control1: CGPoint(x: center.x + width * scale, y: center.y - height * scale),
                control2: CGPoint(x: center.x + width * scale, y: center.y + height * scale)
            )
            path.addCurve(
                to: north,
                control1: CGPoint(x: center.x - width * scale, y: center.y + height * scale),
                control2: CGPoint(x: center.x - width * scale, y: center.y - height * scale)
            )
            let flow = 0.50 + 0.22 * sin(phase * .pi * 4 + Double(index))
            context.stroke(
                path,
                with: .color((index.isMultiple(of: 2) ? EchoTheme.magenta : EchoTheme.cyan).opacity(flow)),
                style: StrokeStyle(lineWidth: index == 3 ? 1.5 : 1.0, lineCap: .round)
            )
        }
        techOrb(context: &context, center: CGPoint(x: center.x, y: center.y - 16), radius: 2.7, color: EchoTheme.cyan)
        techOrb(context: &context, center: CGPoint(x: center.x, y: center.y + 16), radius: 2.7, color: EchoTheme.magenta)
    }

    func techCrystal(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        techPolygon(context: &context, center: center, radius: radius, sides: 4, color: color, filled: true)
    }

    func techPolygon(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, sides: Int, color: Color, filled: Bool) {
        var path = Path()
        for index in 0..<sides {
            let angle = -Double.pi / 2 + Double(index) / Double(sides) * Double.pi * 2
            let next = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
            index == 0 ? path.move(to: next) : path.addLine(to: next)
        }
        path.closeSubpath()
        if filled { context.fill(path, with: .color(color.opacity(0.62))) }
        context.stroke(path, with: .color(color.opacity(0.96)), lineWidth: 1.6)
    }

    func techIcon(context: inout GraphicsContext, name: String, center: CGPoint, color: Color) {
        var symbol = context.resolve(Image(systemName: name))
        symbol.shading = .color(color)
        context.draw(symbol, at: center)
    }
}
