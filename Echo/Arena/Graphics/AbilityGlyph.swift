import CoreGraphics
import UIKit

enum AbilityGlyph {
    static func draw(kind: BonusKind, in rect: CGRect, color: UIColor, onto cg: CGContext) {
        let inset = rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.18)
        cg.saveGState()
        cg.translateBy(x: inset.midX, y: inset.midY)
        cg.scaleBy(x: inset.width, y: inset.height)
        cg.setStrokeColor(color.cgColor)
        cg.setFillColor(color.cgColor)
        cg.setLineWidth(0.08)
        cg.setLineCap(.round)
        cg.setLineJoin(.round)

        switch kind {
        case .shield, .ward:
            shield(lock: kind == .ward, onto: cg)
        case .freeze:
            snowflake(onto: cg)
        case .surge:
            bolt(onto: cg)
        case .pulse:
            pulse(onto: cg)
        case .magnet:
            magnet(onto: cg)
        case .phase:
            phase(onto: cg)
        case .chrono:
            clock(onto: cg)
        case .anchor:
            hourglass(onto: cg)
        case .repulse:
            repulse(onto: cg)
        case .prism:
            prism(onto: cg)
        case .blink:
            blink(onto: cg)
        }
        cg.restoreGState()
    }

    private static func shield(lock: Bool, onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0.42))
        path.addLine(to: CGPoint(x: 0.34, y: 0.30))
        path.addLine(to: CGPoint(x: 0.30, y: -0.10))
        path.addQuadCurve(to: CGPoint(x: 0, y: -0.42), control: CGPoint(x: 0.28, y: -0.32))
        path.addQuadCurve(to: CGPoint(x: -0.30, y: -0.10), control: CGPoint(x: -0.28, y: -0.32))
        path.addLine(to: CGPoint(x: -0.34, y: 0.30))
        path.closeSubpath()
        cg.addPath(path)
        cg.strokePath()
        if lock {
            cg.addEllipse(in: CGRect(x: -0.10, y: -0.04, width: 0.20, height: 0.18))
            cg.move(to: CGPoint(x: -0.07, y: 0.02))
            cg.addLine(to: CGPoint(x: -0.07, y: 0.14))
            cg.addQuadCurve(to: CGPoint(x: 0.07, y: 0.14), control: CGPoint(x: 0, y: 0.22))
            cg.addLine(to: CGPoint(x: 0.07, y: 0.02))
            cg.strokePath()
        }
    }

    private static func snowflake(onto cg: CGContext) {
        for index in 0..<6 {
            cg.saveGState()
            cg.rotate(by: CGFloat(index) * .pi / 3)
            cg.move(to: .zero)
            cg.addLine(to: CGPoint(x: 0, y: 0.40))
            cg.move(to: CGPoint(x: 0, y: 0.22))
            cg.addLine(to: CGPoint(x: 0.10, y: 0.30))
            cg.move(to: CGPoint(x: 0, y: 0.22))
            cg.addLine(to: CGPoint(x: -0.10, y: 0.30))
            cg.strokePath()
            cg.restoreGState()
        }
    }

    private static func bolt(onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0.08, y: 0.40))
        path.addLine(to: CGPoint(x: -0.18, y: 0.04))
        path.addLine(to: CGPoint(x: 0.02, y: 0.04))
        path.addLine(to: CGPoint(x: -0.10, y: -0.40))
        path.addLine(to: CGPoint(x: 0.20, y: 0.08))
        path.addLine(to: CGPoint(x: 0.00, y: 0.08))
        path.closeSubpath()
        cg.addPath(path)
        cg.fillPath()
    }

    private static func pulse(onto cg: CGContext) {
        cg.addEllipse(in: CGRect(x: -0.08, y: -0.08, width: 0.16, height: 0.16))
        cg.fillPath()
        cg.addArc(center: .zero, radius: 0.24, startAngle: -0.9, endAngle: 0.9, clockwise: false)
        cg.addArc(center: .zero, radius: 0.38, startAngle: -0.75, endAngle: 0.75, clockwise: false)
        cg.strokePath()
    }

    private static func magnet(onto cg: CGContext) {
        cg.move(to: CGPoint(x: -0.22, y: 0.28))
        cg.addLine(to: CGPoint(x: -0.22, y: 0.02))
        cg.addQuadCurve(to: CGPoint(x: 0.22, y: 0.02), control: CGPoint(x: 0, y: -0.34))
        cg.addLine(to: CGPoint(x: 0.22, y: 0.28))
        cg.strokePath()
        cg.setLineWidth(0.12)
        cg.move(to: CGPoint(x: -0.22, y: 0.28))
        cg.addLine(to: CGPoint(x: -0.22, y: 0.16))
        cg.move(to: CGPoint(x: 0.22, y: 0.28))
        cg.addLine(to: CGPoint(x: 0.22, y: 0.16))
        cg.strokePath()
    }

    private static func phase(onto cg: CGContext) {
        cg.addEllipse(in: CGRect(x: -0.34, y: -0.22, width: 0.40, height: 0.40))
        cg.strokePath()
        cg.addEllipse(in: CGRect(x: -0.06, y: -0.22, width: 0.40, height: 0.40))
        cg.strokePath()
    }

    private static func clock(onto cg: CGContext) {
        cg.addEllipse(in: CGRect(x: -0.36, y: -0.36, width: 0.72, height: 0.72))
        cg.strokePath()
        cg.move(to: .zero)
        cg.addLine(to: CGPoint(x: 0, y: 0.22))
        cg.move(to: .zero)
        cg.addLine(to: CGPoint(x: 0.22, y: -0.06))
        cg.strokePath()
    }

    private static func hourglass(onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -0.22, y: 0.34))
        path.addLine(to: CGPoint(x: 0.22, y: 0.34))
        path.addLine(to: CGPoint(x: 0.04, y: 0.04))
        path.addLine(to: CGPoint(x: 0.22, y: -0.34))
        path.addLine(to: CGPoint(x: -0.22, y: -0.34))
        path.addLine(to: CGPoint(x: -0.04, y: -0.04))
        path.closeSubpath()
        cg.addPath(path)
        cg.strokePath()
    }

    private static func repulse(onto cg: CGContext) {
        for index in 0..<6 {
            cg.saveGState()
            cg.rotate(by: CGFloat(index) * .pi / 3)
            cg.move(to: CGPoint(x: 0, y: 0.10))
            cg.addLine(to: CGPoint(x: 0, y: 0.38))
            cg.move(to: CGPoint(x: -0.08, y: 0.28))
            cg.addLine(to: CGPoint(x: 0, y: 0.38))
            cg.addLine(to: CGPoint(x: 0.08, y: 0.28))
            cg.strokePath()
            cg.restoreGState()
        }
    }

    private static func prism(onto cg: CGContext) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0.38))
        path.addLine(to: CGPoint(x: 0.36, y: -0.30))
        path.addLine(to: CGPoint(x: -0.36, y: -0.30))
        path.closeSubpath()
        cg.addPath(path)
        cg.strokePath()
    }

    private static func blink(onto cg: CGContext) {
        cg.move(to: CGPoint(x: -0.34, y: 0))
        cg.addLine(to: CGPoint(x: 0.16, y: 0))
        cg.move(to: CGPoint(x: 0.02, y: 0.16))
        cg.addLine(to: CGPoint(x: 0.22, y: 0))
        cg.addLine(to: CGPoint(x: 0.02, y: -0.16))
        cg.move(to: CGPoint(x: 0.32, y: 0.22))
        cg.addLine(to: CGPoint(x: 0.32, y: -0.22))
        cg.strokePath()
    }
}
