import SwiftUI

extension MechanicDemoView {
    func curvePoint(t: Double, size: CGSize) -> CGPoint {
        let u = max(0, min(1, t))
        return CGPoint(
            x: size.width * (0.12 + u * 0.76),
            y: size.height * (0.60 - u * 0.26 + sin(u * .pi * 2) * 0.18)
        )
    }

    func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        let amount = CGFloat(t)
        return CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
    }

    func orb(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, hollow: Bool = false) {
        let glowRect = CGRect(x: center.x - radius * 1.65, y: center.y - radius * 1.65, width: radius * 3.3, height: radius * 3.3)
        context.fill(Circle().path(in: glowRect), with: .color(color.opacity(0.13)))
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        if !hollow { context.fill(Circle().path(in: rect), with: .color(color.opacity(0.90))) }
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.95)), lineWidth: hollow ? 2.2 : 1.2)
    }

    func ring(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, lineWidth: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(max(0, min(1, opacity)))), lineWidth: lineWidth)
    }

    func line(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color.opacity(0.88)), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dashed ? [5, 5] : []))
    }

    func polygon(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, sides: Int, color: Color, filled: Bool) {
        var path = Path()
        for index in 0..<sides {
            let angle = -Double.pi / 2 + Double(index) / Double(sides) * Double.pi * 2
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        if filled { context.fill(path, with: .color(color.opacity(0.55))) }
        context.stroke(path, with: .color(color.opacity(0.92)), lineWidth: 1.8)
    }

    func mechanicLightning(
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
        for index in 0...7 {
            let amount = CGFloat(index) / 7
            let envelope = sin(amount * .pi)
            let jitter = sin(CGFloat(seed * 19 + index * 37)) * 7 * envelope
            let point = CGPoint(x: start.x + dx * amount + px * jitter, y: start.y + dy * amount + py * jitter)
            points.append(point)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        for index in [3, 5] {
            let source = points[index]
            path.move(to: source)
            path.addLine(to: CGPoint(x: source.x - 8, y: source.y + (index == 3 ? 9 : -10)))
        }
        context.stroke(path, with: .color(color.opacity(0.13)), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(color.opacity(0.54)), style: StrokeStyle(lineWidth: 3.6, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(.white.opacity(0.98)), style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round))
    }

    func snowflake(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        opacity: Double
    ) {
        var glow = context
        glow.addFilter(.shadow(color: EchoTheme.cyan.opacity(opacity * 0.8), radius: radius * 1.5))
        var path = Path()
        for branch in 0..<3 {
            let angle = CGFloat(branch) / 3 * .pi
            let dx = cos(angle) * radius
            let dy = sin(angle) * radius
            path.move(to: CGPoint(x: center.x - dx, y: center.y - dy))
            path.addLine(to: CGPoint(x: center.x + dx, y: center.y + dy))
        }
        glow.stroke(path, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
    }

    func iceShell(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: rect), with: .color(EchoTheme.cyan.opacity(opacity * 0.08)))
        context.stroke(Circle().path(in: rect), with: .color(.white.opacity(opacity * 0.72)), lineWidth: 1.15)
        for index in 0..<8 {
            let angle = CGFloat(index) / 8 * .pi * 2
            var shard = Path()
            shard.move(to: CGPoint(x: center.x + cos(angle) * radius * 0.70, y: center.y + sin(angle) * radius * 0.70))
            shard.addLine(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            context.stroke(shard, with: .color(EchoTheme.cyan.opacity(opacity)), lineWidth: 1)
        }
    }

    func shieldBubble(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        impact: Bool
    ) {
        let halo = CGRect(x: center.x - radius * 1.12, y: center.y - radius * 1.12, width: radius * 2.24, height: radius * 2.24)
        var membrane = context
        membrane.opacity = impact ? 0.88 : 0.70
        membrane.draw(Image("ShieldBubbleV2"), in: halo)
        let shell = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Circle().path(in: shell), with: .color(color.opacity(0.56)), lineWidth: 1.2)
        var highlight = Path()
        highlight.addArc(center: center, radius: radius - 2, startAngle: .degrees(205), endAngle: .degrees(294), clockwise: false)
        context.stroke(highlight, with: .color(.white.opacity(0.76)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        if impact {
            var cracks = Path()
            let hit = CGPoint(x: center.x - radius + 1, y: center.y)
            for index in 0..<4 {
                let joint = CGPoint(x: hit.x + 10, y: hit.y + CGFloat(index - 2) * 4)
                cracks.move(to: hit)
                cracks.addLine(to: joint)
                cracks.addLine(to: CGPoint(x: joint.x + 8, y: joint.y + CGFloat(index.isMultiple(of: 2) ? 8 : -7)))
            }
            context.stroke(cracks, with: .color(.white.opacity(0.95)), style: StrokeStyle(lineWidth: 1.05, lineCap: .round, lineJoin: .round))
        }
    }

    func mechanicMagneticField(
        context: inout GraphicsContext,
        center: CGPoint,
        width: CGFloat,
        height: CGFloat,
        color: Color
    ) {
        for index in 0..<3 {
            let scale = 0.66 + CGFloat(index) * 0.17
            var path = Path()
            let north = CGPoint(x: center.x, y: center.y - 15)
            let south = CGPoint(x: center.x, y: center.y + 15)
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
            context.stroke(path, with: .color((index == 1 ? EchoTheme.cyan : color).opacity(0.34 + Double(index) * 0.10)), lineWidth: index == 2 ? 1.5 : 1)
        }
    }
}
