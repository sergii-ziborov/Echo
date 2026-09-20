import SwiftUI

extension MechanicDemoView {
    func drawGrid(context: inout GraphicsContext, size: CGSize) {
        for x in stride(from: CGFloat(0), through: size.width, by: 34) {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(scenario.tint.opacity(0.045)), lineWidth: 1)
        }
        for y in stride(from: CGFloat(0), through: size.height, by: 32) {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(scenario.tint.opacity(0.045)), lineWidth: 1)
        }
    }

    func drawScenario(context: inout GraphicsContext, size: CGSize, progress t: Double) {
        let w = size.width
        let h = size.height
        let mid = CGPoint(x: w * 0.5, y: h * 0.48)
        let eased = t * t * (3 - 2 * t)

        switch scenario {
        case .echo:
            var route = Path()
            route.move(to: CGPoint(x: w * 0.12, y: h * 0.60))
            route.addCurve(
                to: CGPoint(x: w * 0.88, y: h * 0.34),
                control1: CGPoint(x: w * 0.38, y: h * 0.13),
                control2: CGPoint(x: w * 0.58, y: h * 0.82)
            )
            context.stroke(route, with: .color(EchoTheme.cyan.opacity(0.28)), style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
            let player = curvePoint(t: eased, size: size)
            let echo = curvePoint(t: max(0, eased - 0.24), size: size)
            orb(context: &context, center: echo, radius: 11, color: EchoTheme.violet, hollow: true)
            orb(context: &context, center: player, radius: 12, color: .white)

        case .asteroid:
            let impact = min(1, t / 0.48)
            let rebound = max(0, (t - 0.48) / 0.52)
            let wall = CGRect(x: w * 0.78, y: h * 0.18, width: 13, height: h * 0.57)
            context.fill(Path(roundedRect: wall, cornerRadius: 4), with: .color(EchoTheme.magenta.opacity(0.32)))
            let x = w * (0.20 + 0.52 * impact - 0.18 * rebound)
            polygon(context: &context, center: CGPoint(x: x, y: h * 0.46), radius: 22, sides: 7, color: .orange, filled: true)
            if t > 0.45 {
                for offset in [-1.0, 0, 1.0] {
                    var crack = Path()
                    crack.move(to: CGPoint(x: x, y: h * 0.46))
                    crack.addLine(to: CGPoint(x: x + CGFloat(offset * 14), y: h * 0.46 + 18))
                    context.stroke(crack, with: .color(.white.opacity(0.82)), lineWidth: 1.3)
                }
            }

        case .rift:
            let opening = 0.72 + 0.28 * sin(t * .pi * 2)
            ring(context: &context, center: mid, radius: 35, color: EchoTheme.violet, lineWidth: 5, opacity: opening)
            ring(context: &context, center: mid, radius: 45, color: EchoTheme.cyan, lineWidth: 1.5, opacity: 0.55)
            let x = w * (0.13 + eased * 0.74)
            orb(context: &context, center: CGPoint(x: x, y: mid.y), radius: 10, color: t > 0.52 ? EchoTheme.magenta : .white)

        case .freeze:
            let freezeAt = min(t, 0.34)
            let playerX = w * (0.12 + eased * 0.76)
            let hazardX = w * (0.72 - freezeAt * 0.75)
            let wave = min(1, t * 3.4)
            ring(context: &context, center: mid, radius: CGFloat(18 + wave * 67), color: .white, lineWidth: 1.2, opacity: t < 0.72 ? 0.82 : 0.12)
            ring(context: &context, center: mid, radius: CGFloat(25 + wave * 72), color: EchoTheme.cyan, lineWidth: 5, opacity: t < 0.64 ? 0.17 : 0.04)
            let frozenHazard = CGPoint(x: hazardX, y: h * 0.35)
            orb(context: &context, center: frozenHazard, radius: 13, color: EchoTheme.violet, hollow: true)
            iceShell(context: &context, center: frozenHazard, radius: 19, opacity: 0.78)
            let rock = CGPoint(x: w * 0.68, y: h * 0.61)
            polygon(context: &context, center: rock, radius: 17, sides: 7, color: .orange, filled: true)
            iceShell(context: &context, center: rock, radius: 24, opacity: 0.66)
            for index in 0..<12 {
                let column = CGFloat((index * 47) % 13) / 13
                let fall = CGFloat((t * 1.65 + Double(index) * 0.137).truncatingRemainder(dividingBy: 1))
                snowflake(
                    context: &context,
                    center: CGPoint(x: 12 + column * (w - 24), y: 17 + fall * (h - 42)),
                    radius: 2.7 + CGFloat(index % 3),
                    opacity: 0.34 + Double(index % 3) * 0.15
                )
            }
            orb(context: &context, center: CGPoint(x: playerX, y: mid.y), radius: 11, color: .white)

        case .phase:
            let x = w * (0.12 + eased * 0.76)
            orb(context: &context, center: mid, radius: 23, color: EchoTheme.violet, hollow: true)
            orb(context: &context, center: CGPoint(x: x, y: mid.y), radius: 11, color: EchoTheme.cyan.opacity(abs(x - mid.x) < 28 ? 0.45 : 1))
            if abs(x - mid.x) < 38 { ring(context: &context, center: CGPoint(x: x, y: mid.y), radius: 20, color: .white, lineWidth: 1.5, opacity: 0.8) }

        case .collision:
            let u = min(1, t * 2.1)
            let left = CGPoint(x: w * (0.16 + 0.34 * u), y: mid.y)
            let right = CGPoint(x: w * (0.84 - 0.34 * u), y: mid.y)
            orb(context: &context, center: left, radius: 11, color: EchoTheme.cyan, hollow: true)
            orb(context: &context, center: right, radius: 11, color: EchoTheme.violet, hollow: true)
            if t > 0.47 { ring(context: &context, center: mid, radius: CGFloat(14 + (t - 0.47) * 28), color: EchoTheme.magenta, lineWidth: 4, opacity: 0.9) }

        case .gate:
            let open = t > 0.28 && t < 0.72
            let gateRect = CGRect(x: w * 0.47, y: h * 0.20, width: 14, height: h * 0.54)
            context.fill(Path(roundedRect: gateRect, cornerRadius: 4), with: .color(EchoTheme.magenta.opacity(open ? 0.10 : 0.75)))
            orb(context: &context, center: CGPoint(x: w * (0.13 + eased * 0.74), y: mid.y), radius: 11, color: .white)

        case .laser:
            let firing = t > 0.42 && t < 0.72
            let playerY = h * (t < 0.42 ? 0.48 : 0.32)
            line(context: &context, from: CGPoint(x: w * 0.12, y: mid.y), to: CGPoint(x: w * 0.88, y: mid.y), color: firing ? .red : .orange, width: firing ? 6 : 1.5, dashed: !firing)
            orb(context: &context, center: CGPoint(x: w * 0.62, y: playerY), radius: 11, color: .white)

        case .timeCrystal:
            polygon(context: &context, center: CGPoint(x: w * 0.78, y: mid.y), radius: 17, sides: 6, color: EchoTheme.gold, filled: true)
            orb(context: &context, center: CGPoint(x: w * 0.78, y: mid.y), radius: 7, color: .white)
            orb(context: &context, center: CGPoint(x: w * (0.12 + eased * 0.66), y: mid.y), radius: 11, color: .white)

        case .resonance:
            let points = [CGPoint(x: w * 0.24, y: h * 0.58), CGPoint(x: w * 0.48, y: h * 0.30), CGPoint(x: w * 0.73, y: h * 0.55)]
            for (index, point) in points.enumerated() {
                orb(context: &context, center: point, radius: 7, color: index <= Int(t * 4) ? EchoTheme.gold : EchoTheme.cyan, hollow: index > Int(t * 4))
            }
            let segment = min(2, Int(t * 3))
            let local = t * 3 - Double(segment)
            let from = segment == 0 ? CGPoint(x: w * 0.10, y: h * 0.62) : points[segment - 1]
            let to = points[segment]
            orb(context: &context, center: lerp(from, to, min(1, local)), radius: 10, color: .white)

        case .blackHole:
            for radius in [24.0, 38.0, 54.0] { ring(context: &context, center: mid, radius: radius, color: EchoTheme.violet, lineWidth: radius == 24 ? 5 : 1, opacity: 0.65) }
            orb(context: &context, center: mid, radius: 13, color: .black)
            let angle = .pi * (1.15 + t * 1.45)
            let radius = 64 - t * 28
            orb(context: &context, center: CGPoint(x: mid.x + CGFloat(cos(angle) * radius), y: mid.y + CGFloat(sin(angle) * radius)), radius: 10, color: .white)

        case .shield:
            let hazardX = t < 0.52 ? w * (0.15 + t * 1.1) : w * (0.72 + (t - 0.52) * 0.3)
            shieldBubble(context: &context, center: mid, radius: 30, color: .green, impact: t > 0.43 && t < 0.67)
            context.draw(Image("PlayerOrbV2"), in: CGRect(x: mid.x - 45, y: mid.y - 45, width: 90, height: 90))
            polygon(context: &context, center: CGPoint(x: hazardX, y: mid.y), radius: 12, sides: 7, color: .orange, filled: true)

        case .surge:
            let x = w * (0.10 + min(1, t * 1.55) * 0.80)
            for index in 0..<4 {
                let trailX = x - CGFloat(18 + index * 14)
                context.fill(
                    Path(ellipseIn: CGRect(x: trailX - 5, y: mid.y - 5, width: 10, height: 10)),
                    with: .color(EchoTheme.gold.opacity(0.55 - Double(index) * 0.1))
                )
            }
            orb(context: &context, center: CGPoint(x: x, y: mid.y), radius: 12, color: .white)

        case .pulse, .chrono:
            let count = scenario == .chrono ? 4 : 2
            for index in 0..<count {
                let phase = (t + Double(index) / Double(count)).truncatingRemainder(dividingBy: 1)
                ring(context: &context, center: mid, radius: CGFloat(16 + phase * 65), color: scenario == .chrono ? EchoTheme.violet : EchoTheme.magenta, lineWidth: 2, opacity: 1 - phase)
            }
            orb(context: &context, center: mid, radius: 11, color: .white)
            orb(context: &context, center: CGPoint(x: w * (0.78 + t * 0.08), y: mid.y), radius: 10, color: EchoTheme.violet, hollow: true)

        case .magnet:
            orb(context: &context, center: mid, radius: 11, color: .white)
            mechanicMagneticField(context: &context, center: mid, width: 64, height: 47, color: .green)
            for index in 0..<7 {
                let angle = Double(index) / 7 * .pi * 2
                let start = CGPoint(x: mid.x + CGFloat(cos(angle) * 76), y: mid.y + CGFloat(sin(angle) * 48))
                let pull = max(0, min(1, (t - 0.16) * 1.35))
                orb(context: &context, center: lerp(start, mid, pull * 0.82), radius: 5, color: EchoTheme.cyan)
            }

        case .anchor:
            let playerX = w * (0.12 + eased * 0.76)
            let slowT = t < 0.20 ? t : 0.20 + (t - 0.20) * 0.25
            let rockX = w * (0.76 - slowT * 0.45)
            ring(context: &context, center: mid, radius: CGFloat(24 + sin(t * .pi) * 32), color: EchoTheme.cyan, lineWidth: 2, opacity: 0.7)
            polygon(context: &context, center: CGPoint(x: rockX, y: h * 0.34), radius: 16, sides: 7, color: .orange, filled: true)
            orb(context: &context, center: CGPoint(x: playerX, y: h * 0.58), radius: 11, color: .white)

        case .repulse:
            orb(context: &context, center: mid, radius: 11, color: .white)
            let blast = max(0, min(1, (t - 0.22) * 1.6))
            ring(context: &context, center: mid, radius: CGFloat(18 + blast * 72), color: EchoTheme.magenta, lineWidth: 3, opacity: 1 - blast * 0.65)
            for index in 0..<6 {
                let angle = Double(index) / 6 * .pi * 2
                let radius = 30 + blast * 70
                polygon(context: &context, center: CGPoint(x: mid.x + CGFloat(cos(angle) * radius), y: mid.y + CGFloat(sin(angle) * radius * 0.55)), radius: 9, sides: 6, color: .orange, filled: true)
            }

        case .prism:
            let left = CGPoint(x: w * 0.10, y: mid.y)
            let right = CGPoint(x: w * 0.90, y: mid.y)
            polygon(context: &context, center: mid, radius: 25, sides: 3, color: Color(red: 0.60, green: 1, blue: 0.92), filled: false)
            line(context: &context, from: left, to: CGPoint(x: mid.x - 21, y: mid.y), color: .red, width: 4)
            line(context: &context, from: CGPoint(x: mid.x - 21, y: mid.y), to: CGPoint(x: mid.x + 22, y: mid.y - 25), color: EchoTheme.cyan, width: 3)
            line(context: &context, from: CGPoint(x: mid.x + 22, y: mid.y - 25), to: right, color: EchoTheme.violet, width: 3)
            orb(context: &context, center: mid, radius: 9, color: .white)

        case .blink:
            let start = CGPoint(x: w * 0.20, y: mid.y)
            let end = CGPoint(x: w * 0.80, y: mid.y)
            let atEnd = t > 0.42
            polygon(context: &context, center: mid, radius: 24, sides: 6, color: EchoTheme.magenta, filled: true)
            for index in 0..<4 {
                let trailT = Double(index) / 4
                orb(context: &context, center: lerp(start, end, trailT), radius: 9, color: EchoTheme.cyan.opacity(atEnd ? 0.12 + trailT * 0.15 : 0.06), hollow: true)
            }
            ring(context: &context, center: atEnd ? end : start, radius: 22, color: EchoTheme.violet, lineWidth: 2, opacity: 0.8)
            orb(context: &context, center: atEnd ? end : start, radius: 11, color: .white)
        }
    }

}
