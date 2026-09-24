import CoreGraphics
import UIKit

/// Line icons for every ability, drawn in a unit box centred on the origin
/// with y pointing up. Callers draw into y-up contexts (BitmapCanvas), so the
/// shield points down and the prism points up the way they were designed.
enum AbilityGlyph {
    static func draw(kind: BonusKind, in rect: CGRect, color: UIColor, onto cg: CGContext) {
        let inset = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
        cg.saveGState()
        cg.translateBy(x: inset.midX, y: inset.midY)
        cg.scaleBy(x: inset.width, y: inset.height)
        cg.setStrokeColor(color.cgColor)
        cg.setFillColor(color.cgColor)
        cg.setLineWidth(0.075)
        cg.setLineCap(.round)
        cg.setLineJoin(.round)

        switch kind {
        case .shield, .ward:
            shield(lock: kind == .ward, color: color, onto: cg)
        case .freeze:
            snowflake(onto: cg)
        case .surge:
            bolt(onto: cg)
        case .pulse:
            pulse(onto: cg)
        case .magnet:
            magnet(onto: cg)
        case .phase:
            phase(color: color, onto: cg)
        case .chrono:
            clock(onto: cg)
        case .anchor:
            hourglass(onto: cg)
        case .repulse:
            repulse(onto: cg)
        case .prism:
            prism(color: color, onto: cg)
        case .blink:
            blink(onto: cg)
        }
        cg.restoreGState()
    }

    private static func shield(lock: Bool, color: UIColor, onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0.42))
        path.addQuadCurve(to: CGPoint(x: 0.34, y: 0.30), control: CGPoint(x: 0.18, y: 0.40))
        path.addLine(to: CGPoint(x: 0.32, y: -0.04))
        path.addQuadCurve(to: CGPoint(x: 0, y: -0.44), control: CGPoint(x: 0.28, y: -0.30))
        path.addQuadCurve(to: CGPoint(x: -0.32, y: -0.04), control: CGPoint(x: -0.28, y: -0.30))
        path.addLine(to: CGPoint(x: -0.34, y: 0.30))
        path.addQuadCurve(to: CGPoint(x: 0, y: 0.42), control: CGPoint(x: -0.18, y: 0.40))
        path.closeSubpath()
        cg.addPath(path)
        cg.setFillColor(color.withAlphaComponent(0.22).cgColor)
        cg.fillPath()
        cg.addPath(path)
        cg.strokePath()
        if lock {
            cg.addRect(CGRect(x: -0.12, y: -0.16, width: 0.24, height: 0.18))
            cg.fillPath()
            cg.move(to: CGPoint(x: -0.07, y: 0.02))
            cg.addLine(to: CGPoint(x: -0.07, y: 0.10))
            cg.addQuadCurve(to: CGPoint(x: 0.07, y: 0.10), control: CGPoint(x: 0, y: 0.20))
            cg.addLine(to: CGPoint(x: 0.07, y: 0.02))
            cg.strokePath()
        } else {
            cg.move(to: CGPoint(x: 0, y: 0.30))
            cg.addLine(to: CGPoint(x: 0, y: -0.30))
            cg.move(to: CGPoint(x: -0.20, y: 0.10))
            cg.addLine(to: CGPoint(x: 0.20, y: 0.10))
            cg.strokePath()
        }
    }

    private static func snowflake(onto cg: CGContext) {
        for index in 0..<6 {
            cg.saveGState()
            cg.rotate(by: CGFloat(index) * .pi / 3)
            cg.move(to: CGPoint(x: 0, y: 0.08))
            cg.addLine(to: CGPoint(x: 0, y: 0.42))
            cg.move(to: CGPoint(x: 0, y: 0.24))
            cg.addLine(to: CGPoint(x: 0.11, y: 0.33))
            cg.move(to: CGPoint(x: 0, y: 0.24))
            cg.addLine(to: CGPoint(x: -0.11, y: 0.33))
            cg.strokePath()
            cg.restoreGState()
        }
        cg.addPath(BitmapCanvas.polygon((0..<6).map { index in
            let angle = CGFloat(index) / 6 * 2 * .pi
            return CGPoint(x: cos(angle) * 0.09, y: sin(angle) * 0.09)
        }))
        cg.fillPath()
    }

    private static func bolt(onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.10, y: 0.44))
        path.addLine(to: CGPoint(x: -0.22, y: 0.02))
        path.addLine(to: CGPoint(x: 0.0, y: 0.02))
        path.addLine(to: CGPoint(x: -0.12, y: -0.44))
        path.addLine(to: CGPoint(x: 0.24, y: 0.08))
        path.addLine(to: CGPoint(x: 0.02, y: 0.08))
        path.closeSubpath()
        cg.addPath(path)
        cg.fillPath()
    }

    private static func pulse(onto cg: CGContext) {
        cg.addEllipse(in: CGRect(x: -0.09, y: -0.09, width: 0.18, height: 0.18))
        cg.fillPath()
        for radius in [0.23, 0.38] as [CGFloat] {
            cg.addArc(center: .zero, radius: radius, startAngle: -0.8, endAngle: 0.8, clockwise: false)
            cg.move(to: CGPoint(x: cos(CGFloat.pi - 0.8) * radius, y: sin(CGFloat.pi - 0.8) * radius))
            cg.addArc(center: .zero, radius: radius, startAngle: .pi - 0.8, endAngle: .pi + 0.8, clockwise: false)
            cg.strokePath()
        }
    }

    private static func magnet(onto cg: CGContext) {
        cg.setLineWidth(0.12)
        cg.move(to: CGPoint(x: -0.22, y: 0.34))
        cg.addLine(to: CGPoint(x: -0.22, y: 0.0))
        cg.addArc(center: .zero, radius: 0.22, startAngle: .pi, endAngle: 0, clockwise: false)
        cg.addLine(to: CGPoint(x: 0.22, y: 0.34))
        cg.setLineCap(.butt)
        cg.strokePath()
        cg.setLineWidth(0.16)
        cg.move(to: CGPoint(x: -0.22, y: 0.40))
        cg.addLine(to: CGPoint(x: -0.22, y: 0.28))
        cg.move(to: CGPoint(x: 0.22, y: 0.40))
        cg.addLine(to: CGPoint(x: 0.22, y: 0.28))
        cg.strokePath()
    }

    private static func phase(color: UIColor, onto cg: CGContext) {
        cg.setStrokeColor(color.withAlphaComponent(0.55).cgColor)
        cg.setLineDash(phase: 0, lengths: [0.07, 0.06])
        cg.addEllipse(in: CGRect(x: -0.40, y: -0.20, width: 0.40, height: 0.40))
        cg.strokePath()
        cg.setLineDash(phase: 0, lengths: [])
        cg.setStrokeColor(color.cgColor)
        cg.addEllipse(in: CGRect(x: -0.02, y: -0.20, width: 0.40, height: 0.40))
        cg.strokePath()
    }

    private static func clock(onto cg: CGContext) {
        cg.addArc(center: .zero, radius: 0.34, startAngle: .pi * 0.62, endAngle: .pi * 0.38 + 2 * .pi, clockwise: false)
        cg.strokePath()
        // Arrowhead at the end of the counter-clockwise sweep, pointing along it.
        let end = CGFloat.pi * 0.38
        let tip = CGPoint(x: cos(end) * 0.34, y: sin(end) * 0.34)
        let travel = CGVector(dx: -sin(end), dy: cos(end))
        let back = CGPoint(x: tip.x - travel.dx * 0.13, y: tip.y - travel.dy * 0.13)
        cg.move(to: CGPoint(x: back.x + travel.dy * 0.09, y: back.y - travel.dx * 0.09))
        cg.addLine(to: tip)
        cg.addLine(to: CGPoint(x: back.x - travel.dy * 0.09, y: back.y + travel.dx * 0.09))
        cg.strokePath()
        cg.move(to: .zero)
        cg.addLine(to: CGPoint(x: 0, y: 0.20))
        cg.move(to: .zero)
        cg.addLine(to: CGPoint(x: 0.15, y: -0.08))
        cg.strokePath()
    }

    private static func hourglass(onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.24, y: 0.38))
        path.addLine(to: CGPoint(x: 0.24, y: 0.38))
        path.addLine(to: CGPoint(x: 0.04, y: 0.02))
        path.addLine(to: CGPoint(x: 0.24, y: -0.38))
        path.addLine(to: CGPoint(x: -0.24, y: -0.38))
        path.addLine(to: CGPoint(x: -0.04, y: 0.02))
        path.closeSubpath()
        cg.addPath(path)
        cg.strokePath()
        cg.addPath(BitmapCanvas.polygon([CGPoint(x: -0.16, y: -0.32), CGPoint(x: 0.16, y: -0.32), CGPoint(x: 0, y: -0.12)]))
        cg.fillPath()
        cg.addPath(BitmapCanvas.polygon([CGPoint(x: -0.10, y: 0.28), CGPoint(x: 0.10, y: 0.28), CGPoint(x: 0, y: 0.14)]))
        cg.fillPath()
    }

    private static func repulse(onto cg: CGContext) {
        cg.addEllipse(in: CGRect(x: -0.07, y: -0.07, width: 0.14, height: 0.14))
        cg.fillPath()
        for index in 0..<6 {
            cg.saveGState()
            cg.rotate(by: CGFloat(index) * .pi / 3)
            cg.move(to: CGPoint(x: 0, y: 0.16))
            cg.addLine(to: CGPoint(x: 0, y: 0.42))
            cg.move(to: CGPoint(x: -0.09, y: 0.32))
            cg.addLine(to: CGPoint(x: 0, y: 0.42))
            cg.addLine(to: CGPoint(x: 0.09, y: 0.32))
            cg.strokePath()
            cg.restoreGState()
        }
    }

    private static func prism(color: UIColor, onto cg: CGContext) {
        let triangle = BitmapCanvas.polygon([CGPoint(x: 0, y: 0.36), CGPoint(x: 0.30, y: -0.20), CGPoint(x: -0.30, y: -0.20)])
        cg.addPath(triangle)
        cg.setFillColor(color.withAlphaComponent(0.2).cgColor)
        cg.fillPath()
        cg.addPath(triangle)
        cg.strokePath()
        cg.move(to: CGPoint(x: -0.46, y: 0.02))
        cg.addLine(to: CGPoint(x: -0.12, y: 0.10))
        cg.strokePath()
        cg.setLineWidth(0.05)
        for (index, lift) in ([0.16, 0.06, -0.04] as [CGFloat]).enumerated() {
            cg.setStrokeColor(color.withAlphaComponent(1 - CGFloat(index) * 0.22).cgColor)
            cg.move(to: CGPoint(x: 0.14, y: 0.06))
            cg.addLine(to: CGPoint(x: 0.46, y: lift))
            cg.strokePath()
        }
    }

    private static func blink(onto cg: CGContext) {
        cg.move(to: CGPoint(x: -0.40, y: 0))
        cg.addLine(to: CGPoint(x: 0.14, y: 0))
        cg.move(to: CGPoint(x: -0.02, y: 0.17))
        cg.addLine(to: CGPoint(x: 0.18, y: 0))
        cg.addLine(to: CGPoint(x: -0.02, y: -0.17))
        cg.strokePath()
        cg.setLineWidth(0.1)
        cg.move(to: CGPoint(x: 0.34, y: 0.26))
        cg.addLine(to: CGPoint(x: 0.34, y: -0.26))
        cg.strokePath()
        cg.setLineWidth(0.04)
        for y in [0.13, -0.13] as [CGFloat] {
            cg.move(to: CGPoint(x: -0.40, y: y))
            cg.addLine(to: CGPoint(x: -0.24, y: y))
        }
        cg.strokePath()
    }
}
