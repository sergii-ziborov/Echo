import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    static func asteroidShape(
        radius: CGFloat,
        seed: Int,
        sides: Int = 8,
        jaggedness: CGFloat = 0.28
    ) -> SKShapeNode {
        let path = CGMutablePath()
        let count = max(5, sides)
        for i in 0..<count {
            let wave = 0.5 + 0.5 * sin(Double(seed * 13 + i * 19))
            let jitter = Double(1 - jaggedness) + Double(jaggedness) * wave
            let angle = (Double(i) / Double(count)) * .pi * 2
            let p = CGPoint(x: cos(angle) * Double(radius) * jitter, y: sin(angle) * Double(radius) * jitter)
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.lineJoin = .round
        return node
    }

    static func asteroidMaterialPath(
        material: AsteroidMaterial,
        radius: CGFloat,
        seed: Int
    ) -> CGPath {
        let path = CGMutablePath()
        let offset = CGFloat(seed % 17) * 0.11
        switch material {
        case .basalt:
            for index in 0..<4 {
                let angle = offset + CGFloat(index) * 1.71
                let distance = radius * (0.22 + CGFloat(index % 2) * 0.18)
                let craterRadius = radius * (0.12 + CGFloat(index % 3) * 0.035)
                path.addEllipse(in: CGRect(
                    x: cos(angle) * distance - craterRadius,
                    y: sin(angle) * distance - craterRadius,
                    width: craterRadius * 2,
                    height: craterRadius * 2
                ))
            }
        case .ice:
            path.addPath(polygonPath(radius: radius * 0.76, sides: 6))
            for index in 0..<6 {
                let angle = offset + CGFloat(index) / 6 * .pi * 2
                path.move(to: CGPoint(x: cos(angle) * radius * 0.12, y: sin(angle) * radius * 0.12))
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.82, y: sin(angle) * radius * 0.82))
            }
        case .crystal:
            path.addPath(polygonPath(radius: radius * 0.86, sides: 5))
            for index in 0..<5 {
                let angle = -.pi / 2 + CGFloat(index) / 5 * .pi * 2
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.86, y: sin(angle) * radius * 0.86))
            }
            path.addEllipse(in: CGRect(x: -radius * 0.19, y: -radius * 0.19, width: radius * 0.38, height: radius * 0.38))
        case .alloy:
            path.addEllipse(in: CGRect(x: -radius * 0.78, y: -radius * 0.78, width: radius * 1.56, height: radius * 1.56))
            path.addEllipse(in: CGRect(x: -radius * 0.31, y: -radius * 0.31, width: radius * 0.62, height: radius * 0.62))
            for index in 0..<8 {
                let angle = offset + CGFloat(index) / 8 * .pi * 2
                path.move(to: CGPoint(x: cos(angle) * radius * 0.38, y: sin(angle) * radius * 0.38))
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.76, y: sin(angle) * radius * 0.76))
            }
        case .magma:
            for index in 0..<3 {
                var angle = offset + CGFloat(index) * 2.1
                var point = CGPoint(x: cos(angle) * radius * 0.12, y: sin(angle) * radius * 0.12)
                path.move(to: point)
                for step in 0..<3 {
                    angle += step.isMultiple(of: 2) ? 0.45 : -0.35
                    point = CGPoint(x: point.x + cos(angle) * radius * 0.24, y: point.y + sin(angle) * radius * 0.24)
                    path.addLine(to: point)
                }
            }
        case .geode:
            for ring in [0.3, 0.52, 0.74] as [CGFloat] {
                path.addEllipse(in: CGRect(x: -radius * ring, y: -radius * ring * 0.8, width: radius * ring * 2, height: radius * ring * 1.6))
            }
        case .iron:
            for index in 0..<3 {
                let angle = offset + CGFloat(index) * .pi / 3
                path.move(to: CGPoint(x: -cos(angle) * radius * 0.7, y: -sin(angle) * radius * 0.7))
                path.addLine(to: CGPoint(x: cos(angle) * radius * 0.7, y: sin(angle) * radius * 0.7))
            }
        case .comet:
            path.addEllipse(in: CGRect(x: -radius * 0.4, y: -radius * 0.4, width: radius * 0.8, height: radius * 0.8))
            for index in -1...1 {
                let spread = CGFloat(index) * 0.18
                path.move(to: CGPoint(x: -radius * 0.4, y: radius * spread))
                path.addLine(to: CGPoint(x: -radius * 0.95, y: radius * spread * 2.2))
            }
        }
        return path
    }

    static func asteroidCrackPath(radius: CGFloat, seed: Int) -> CGPath {
        let path = CGMutablePath()
        let offset = CGFloat(seed % 23) * 0.09
        for index in 0..<4 {
            let angle = offset + CGFloat(index) / 4 * .pi * 2
            let inner = CGPoint(x: cos(angle + 0.25) * radius * 0.08, y: sin(angle + 0.25) * radius * 0.08)
            let middle = CGPoint(x: cos(angle - 0.12) * radius * 0.48, y: sin(angle - 0.12) * radius * 0.48)
            let outer = CGPoint(x: cos(angle + 0.08) * radius * 0.92, y: sin(angle + 0.08) * radius * 0.92)
            path.move(to: inner)
            path.addLine(to: middle)
            path.addLine(to: outer)
            path.move(to: middle)
            path.addLine(to: CGPoint(
                x: middle.x + cos(angle + 0.72) * radius * 0.24,
                y: middle.y + sin(angle + 0.72) * radius * 0.24
            ))
        }
        return path
    }

    static func polygonPath(radius: CGFloat, sides: Int) -> CGPath {
        let path = CGMutablePath()
        let count = max(3, sides)
        for index in 0..<count {
            let angle = CGFloat(index) / CGFloat(count) * .pi * 2 - .pi / 2
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    static func lightningPath(
        angle: CGFloat,
        inner: CGFloat,
        outer: CGFloat,
        segments: Int,
        seed: Int
    ) -> CGPath {
        let path = CGMutablePath()
        let count = max(5, segments)
        let direction = CGVector(dx: cos(angle), dy: sin(angle))
        let perpendicular = CGVector(dx: -direction.dy, dy: direction.dx)
        var points: [CGPoint] = []

        for index in 0...count {
            let progress = CGFloat(index) / CGFloat(count)
            let radius = inner + (outer - inner) * progress
            let envelope = sin(progress * .pi)
            let waveA = sin(CGFloat(seed * 19 + index * 43) * 0.73)
            let waveB = cos(CGFloat(seed * 31 + index * 17) * 1.11)
            let lateral = (waveA * 0.72 + waveB * 0.28) * (outer - inner) * 0.18 * envelope
            let point = CGPoint(
                x: direction.dx * radius + perpendicular.dx * lateral,
                y: direction.dy * radius + perpendicular.dy * lateral
            )
            points.append(point)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }

        let branchLength = (outer - inner) * 0.24
        for branchIndex in 0..<2 {
            let sourceIndex = min(count - 1, max(2, (count * (branchIndex + 2)) / 4))
            let source = points[sourceIndex]
            let side: CGFloat = (seed + branchIndex).isMultiple(of: 2) ? 1 : -1
            let branchAngle = angle + side * (0.52 + CGFloat(branchIndex) * 0.12)
            let branchDirection = CGVector(dx: cos(branchAngle), dy: sin(branchAngle))
            let branchPerpendicular = CGVector(dx: -branchDirection.dy, dy: branchDirection.dx)
            path.move(to: source)
            for step in 1...2 {
                let amount = CGFloat(step) / 2
                let branchJitter = sin(CGFloat(seed * 13 + branchIndex * 23 + step * 37)) * branchLength * 0.10
                path.addLine(to: CGPoint(
                    x: source.x + branchDirection.dx * branchLength * amount + branchPerpendicular.dx * branchJitter,
                    y: source.y + branchDirection.dy * branchLength * amount + branchPerpendicular.dy * branchJitter
                ))
            }
        }
        return path
    }

    static func magneticFieldPath(
        horizontal: CGFloat,
        vertical: CGFloat,
        poleGap: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        let north = CGPoint(x: 0, y: poleGap)
        let south = CGPoint(x: 0, y: -poleGap)
        path.move(to: north)
        path.addCurve(
            to: south,
            control1: CGPoint(x: horizontal, y: vertical),
            control2: CGPoint(x: horizontal, y: -vertical)
        )
        path.addCurve(
            to: north,
            control1: CGPoint(x: -horizontal, y: -vertical),
            control2: CGPoint(x: -horizontal, y: vertical)
        )
        path.closeSubpath()
        return path
    }

    static func segmentedCirclePath(
        radius: CGFloat,
        segments: Int,
        coverage: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        let count = max(2, segments)
        let slice = CGFloat.pi * 2 / CGFloat(count)
        let visible = slice * min(max(coverage, 0.1), 0.92)
        for index in 0..<count {
            let start = CGFloat(index) * slice
            path.addArc(
                center: .zero,
                radius: radius,
                startAngle: start,
                endAngle: start + visible,
                clockwise: false
            )
        }
        return path
    }

    static func arc(radius: CGFloat, fraction: Double) -> CGPath {
        let path = CGMutablePath()
        let end = CGFloat(fraction) * .pi * 2
        path.addArc(center: .zero, radius: radius, startAngle: 0, endAngle: end, clockwise: false)
        return path
    }

    static func color(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt:
            UIColor(red: 0.42, green: 0.32, blue: 0.24, alpha: 1)
        case .ice:
            UIColor(red: 0.38, green: 0.62, blue: 0.78, alpha: 1)
        case .crystal:
            UIColor(red: 0.58, green: 0.32, blue: 0.78, alpha: 1)
        case .alloy:
            UIColor(red: 0.40, green: 0.46, blue: 0.52, alpha: 1)
        case .magma:
            UIColor(red: 0.58, green: 0.24, blue: 0.12, alpha: 1)
        case .geode:
            UIColor(red: 0.62, green: 0.52, blue: 0.40, alpha: 1)
        case .iron:
            UIColor(red: 0.46, green: 0.44, blue: 0.43, alpha: 1)
        case .comet:
            UIColor(red: 0.62, green: 0.78, blue: 0.90, alpha: 1)
        }
    }

    static func rockBodyColor(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt:
            UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1)
        case .ice:
            UIColor(red: 0.16, green: 0.24, blue: 0.32, alpha: 1)
        case .crystal:
            UIColor(red: 0.18, green: 0.10, blue: 0.26, alpha: 1)
        case .alloy:
            UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 1)
        case .magma:
            UIColor(red: 0.16, green: 0.06, blue: 0.04, alpha: 1)
        case .geode:
            UIColor(red: 0.26, green: 0.20, blue: 0.15, alpha: 1)
        case .iron:
            UIColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1)
        case .comet:
            UIColor(red: 0.30, green: 0.36, blue: 0.44, alpha: 1)
        }
    }

    static func secondaryColor(for material: AsteroidMaterial) -> UIColor {
        switch material {
        case .basalt:
            UIColor(red: 1.00, green: 0.62, blue: 0.29, alpha: 1)
        case .ice:
            UIColor.white
        case .crystal:
            UIColor(red: 0.42, green: 0.92, blue: 1.00, alpha: 1)
        case .alloy:
            UIColor(red: 1.00, green: 0.78, blue: 0.32, alpha: 1)
        case .magma:
            UIColor(red: 1.00, green: 0.45, blue: 0.12, alpha: 1)
        case .geode:
            UIColor(red: 0.78, green: 0.50, blue: 1.00, alpha: 1)
        case .iron:
            UIColor(red: 1.00, green: 0.66, blue: 0.40, alpha: 1)
        case .comet:
            UIColor(red: 0.70, green: 0.95, blue: 1.00, alpha: 1)
        }
    }

    static func color(for kind: BonusKind) -> UIColor {
        GlowTextures.color(for: kind)
    }

    func decorationColor(_ tone: ArenaDecorationTone) -> UIColor {
        switch tone {
        case .theme:
            session.level.theme.wallStroke.uiColor
        case .cyan:
            UIColor(red: 0.42, green: 0.88, blue: 1, alpha: 1)
        case .violet:
            UIColor(red: 0.78, green: 0.42, blue: 1, alpha: 1)
        case .gold:
            UIColor(red: 1, green: 0.76, blue: 0.26, alpha: 1)
        case .danger:
            UIColor(red: 1, green: 0.29, blue: 0.43, alpha: 1)
        }
    }

}
