import SwiftUI

extension TechnologyPreviewView {
    func drawComparison(context: inout GraphicsContext, size: CGSize, progress t: Double) {
        let phase = min(2, Int(t * 3))
        let pulse = 0.5 + 0.5 * sin(t * .pi * 6)
        let reveal = phase == 0 ? 0.12 : phase == 1 ? 0.48 + pulse * 0.18 : 1.0
        let sceneProgress = (t * 3).truncatingRemainder(dividingBy: 1)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.56)
        let arena = CGSize(width: size.width * 0.74, height: size.height * 0.31)

        if phase == 1, kind != .magnetism {
            for index in 0..<3 {
                techRing(
                    context: &context,
                    center: center,
                    radius: 26 + CGFloat(index) * 16 + CGFloat(pulse) * 7,
                    color: tint,
                    width: 2,
                    opacity: 0.62 - Double(index) * 0.13
                )
            }
        }

        drawTechnology(
            context: &context,
            center: center,
            arena: arena,
            time: sceneProgress / 2.1,
            strength: reveal
        )
    }

    func drawTechnology(
        context: inout GraphicsContext,
        center: CGPoint,
        arena: CGSize,
        time t: Double,
        strength: Double
    ) {
        let w = arena.width
        let h = arena.height
        let local = (t * 2.1).truncatingRemainder(dividingBy: 1)
        let smooth = local * local * (3 - 2 * local)
        let boost = max(0.05, min(1, strength))

        switch kind {
        case .velocity:
            let start = CGPoint(x: center.x - w * 0.42, y: center.y + h * 0.14)
            let target = CGPoint(x: center.x + w * 0.42, y: center.y - h * 0.10)
            let end = point(start, target, 0.59 + 0.41 * boost)
            techLine(context: &context, from: start, to: target, color: tint.opacity(0.55), width: 2, dashed: true)
            for index in 0..<4 {
                let trail = max(0, smooth - Double(index) * 0.09)
                techOrb(context: &context, center: point(start, end, trail), radius: 8 - CGFloat(index), color: tint.opacity(0.16 + trail * 0.35), hollow: true)
            }
            techOrb(context: &context, center: point(start, end, smooth), radius: 10, color: .white)
            techCrystal(context: &context, center: target, radius: 12, color: EchoTheme.gold)

        case .sparkSense:
            let radius = CGFloat(30 + 47 * boost)
            techRing(context: &context, center: center, radius: radius, color: tint, width: 2, opacity: 0.72)
            techOrb(context: &context, center: center, radius: 10, color: .white)
            for index in 0..<7 {
                let angle = Double(index) / 7 * .pi * 2
                let start = CGPoint(x: center.x + CGFloat(cos(angle)) * 68, y: center.y + CGFloat(sin(angle)) * 38)
                let pulled = boost > 0.70 ? max(0, min(0.96, (smooth - 0.14) * 1.4)) : 0
                techOrb(context: &context, center: point(start, center, pulled), radius: 4, color: EchoTheme.cyan)
            }

        case .magnetism:
            let fieldWidth = CGFloat(49 + boost * 42)
            techMagneticField(
                context: &context,
                center: center,
                width: fieldWidth,
                height: CGFloat(40 + boost * 27),
                phase: t
            )
            techOrb(context: &context, center: center, radius: 10, color: .white)
            for index in 0..<7 {
                let angle = Double(index) / 7 * .pi * 2 + 0.32
                let start = CGPoint(x: center.x + CGFloat(cos(angle)) * 91, y: center.y + CGFloat(sin(angle)) * 50)
                let pull = max(0, min(0.84, (smooth - 0.10) * boost))
                let bend = CGPoint(
                    x: (start.x + center.x) * 0.5 + CGFloat(sin(angle)) * 18,
                    y: (start.y + center.y) * 0.5 - CGFloat(cos(angle)) * 12
                )
                let first = point(start, bend, min(1, pull * 2))
                let position = pull < 0.5 ? first : point(bend, center, (pull - 0.5) * 2)
                techOrb(context: &context, center: position, radius: 4, color: index.isMultiple(of: 2) ? EchoTheme.cyan : tint)
            }

        case .dashCapacitor, .recharge:
            let radius: CGFloat = 34
            let faster = min(1, smooth * (1.0 + boost * 0.9))
            techRing(context: &context, center: center, radius: radius, color: Color.white.opacity(0.15), width: 6, opacity: 1)
            techArc(context: &context, center: center, radius: radius, progress: faster, color: tint, width: 6)
            techIcon(context: &context, name: kind == .recharge ? "bolt.fill" : "arrow.up.right", center: center, color: faster > 0.96 ? .white : tint)

        case .surgeMastery:
            let start = CGPoint(x: center.x - w * 0.40, y: center.y)
            let end = CGPoint(x: center.x + w * 0.40, y: center.y)
            let travel = min(1, smooth * (0.85 + boost * 0.35))
            let orbPoint = point(start, end, travel)
            let trailLength = CGFloat(24 + boost * 72)
            for index in 0..<4 {
                let trailX = orbPoint.x - 10 - CGFloat(index) * (trailLength / 4)
                context.fill(
                    Path(ellipseIn: CGRect(x: trailX - 5, y: orbPoint.y - 5, width: 10, height: 10)),
                    with: .color(EchoTheme.gold.opacity(0.55 - Double(index) * 0.1))
                )
            }
            techOrb(context: &context, center: orbPoint, radius: 11, color: .white)

        case .dashImpulse, .blinkResearch:
            let start = CGPoint(x: center.x - w * 0.38, y: center.y)
            let end = CGPoint(x: center.x + w * (0.08 + boost * 0.32), y: center.y)
            techPolygon(context: &context, center: center, radius: 22, sides: 6, color: EchoTheme.magenta, filled: true)
            techLine(context: &context, from: start, to: end, color: tint, width: 2, dashed: true)
            let atEnd = local > 0.40
            techRing(context: &context, center: atEnd ? end : start, radius: 19, color: tint, width: 2, opacity: 0.85)
            techOrb(context: &context, center: atEnd ? end : start, radius: 10, color: .white)

        case .slots:
            let count = min(6, 2 + level + (boost > 0.70 ? 1 : 0))
            let spacing: CGFloat = 27
            for index in 0..<count {
                let x = center.x + (CGFloat(index) - CGFloat(count - 1) / 2) * spacing
                let rect = CGRect(x: x - 10, y: center.y - 10, width: 20, height: 20)
                context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(index == count - 1 ? tint.opacity(boost) : Color.white.opacity(0.15)))
                context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(index == count - 1 ? tint : .white.opacity(0.32)), lineWidth: 1)
            }

        case .reserves:
            let count = min(8, 3 + level * 2 + (boost > 0.70 ? 2 : 0))
            for index in 0..<count {
                let column = index % 4
                let row = index / 4
                techCrystal(context: &context, center: CGPoint(x: center.x + CGFloat(column) * 25 - 38, y: center.y + CGFloat(row) * 27 - 12), radius: 8, color: index >= count - 2 ? tint : EchoTheme.cyan)
            }

        case .fabricator:
            let costCount = boost > 0.70 ? 4 : 6
            techIcon(context: &context, name: "atom", center: CGPoint(x: center.x, y: center.y - 13), color: tint)
            for index in 0..<costCount {
                techCrystal(context: &context, center: CGPoint(x: center.x + CGFloat(index) * 17 - CGFloat(costCount - 1) * 8.5, y: center.y + 31), radius: 6, color: EchoTheme.violet)
            }

        case .aegis, .shieldLattice:
            let unlocksSecondLayer = kind == .shieldLattice && level + 1 >= kind.maxLevel
            let layers = unlocksSecondLayer && boost > 0.70 ? 2 : 1
            techShieldBubble(
                context: &context,
                center: center,
                radius: 31,
                layers: layers,
                impact: local > 0.40 && local < 0.65,
                strength: boost
            )
            context.draw(Image("PlayerOrbV2"), in: CGRect(x: center.x - 45, y: center.y - 45, width: 90, height: 90))
            let impact = CGPoint(x: center.x - CGFloat(56 - smooth * 38), y: center.y)
            techPolygon(context: &context, center: impact, radius: 10, sides: 7, color: .orange, filled: true)

        case .fieldAmplifier:
            let duration = min(1, local * (0.68 + boost * 0.52))
            techRing(context: &context, center: center, radius: CGFloat(29 + sin(local * .pi) * 20), color: tint, width: 3, opacity: 0.75)
            techOrb(context: &context, center: center, radius: 10, color: .white)
            let bar = CGRect(x: center.x - 60, y: center.y + 49, width: 120, height: 5)
            context.fill(Path(roundedRect: bar, cornerRadius: 3), with: .color(.white.opacity(0.12)))
            context.fill(Path(roundedRect: CGRect(x: bar.minX, y: bar.minY, width: bar.width * duration, height: bar.height), cornerRadius: 3), with: .color(tint))

        case .beamForecast:
            let warningStart = 0.62 - boost * 0.30
            let warning = local > warningStart
            let firing = local > 0.76
            if warning || firing {
                techLine(context: &context, from: CGPoint(x: center.x - w * 0.43, y: center.y), to: CGPoint(x: center.x + w * 0.43, y: center.y), color: firing ? .red : .orange, width: firing ? 6 : 2, dashed: !firing)
            }
            techOrb(context: &context, center: CGPoint(x: center.x + 20, y: center.y - (warning ? 31 : 0)), radius: 10, color: .white)

        case .cryostasis:
            let frozenUntil = 0.42 + boost * 0.42
            let move = local < frozenUntil ? 0.18 : (local - frozenUntil) / max(0.1, 1 - frozenUntil)
            let freezeRadius = CGFloat(30 + boost * 35)
            techRing(context: &context, center: center, radius: freezeRadius, color: EchoTheme.cyan, width: 5, opacity: 0.17)
            techRing(context: &context, center: center, radius: freezeRadius, color: .white, width: 1.1, opacity: 0.76)
            techOrb(context: &context, center: center, radius: 10, color: .white)
            let frozenRock = CGPoint(x: center.x + CGFloat(62 - move * 48), y: center.y - 4)
            techPolygon(context: &context, center: frozenRock, radius: 13, sides: 7, color: .orange, filled: true)
            techIceShell(context: &context, center: frozenRock, radius: 20)
            for index in 0..<10 {
                let angle = Double(index) / 10 * .pi * 2 + local * 0.22
                let radial = CGFloat(26 + (index % 3) * 14)
                let flake = CGPoint(x: center.x + CGFloat(cos(angle)) * radial, y: center.y + CGFloat(sin(angle)) * radial * 0.58)
                techSnowflake(context: &context, center: flake, radius: CGFloat(3 + index % 3), opacity: 0.46 + boost * 0.28)
            }

        case .echoForecast:
            let spacing = CGFloat(25 + boost * 60)
            let player = CGPoint(x: center.x + CGFloat(sin(local * .pi * 2)) * 50, y: center.y - 5)
            techOrb(context: &context, center: CGPoint(x: player.x - spacing, y: player.y + 13), radius: 10, color: EchoTheme.violet, hollow: true)
            techLine(context: &context, from: CGPoint(x: player.x - spacing + 12, y: player.y + 8), to: CGPoint(x: player.x - 12, y: player.y), color: tint.opacity(0.6), width: 1.5, dashed: true)
            techOrb(context: &context, center: player, radius: 10, color: .white)

        case .crystalMemory:
            techCrystal(context: &context, center: center, radius: 15, color: EchoTheme.gold)
            let wave = (local * (0.72 + boost * 0.28)).truncatingRemainder(dividingBy: 1)
            techRing(context: &context, center: center, radius: CGFloat(21 + wave * (38 + boost * 30)), color: EchoTheme.cyan, width: 3, opacity: 1 - wave)
            techIcon(context: &context, name: "snowflake", center: CGPoint(x: center.x, y: center.y + 43), color: EchoTheme.cyan)

        case .phaseResearch:
            let wall = CGRect(x: center.x - 7, y: center.y - 37, width: 14, height: 74)
            context.fill(Path(roundedRect: wall, cornerRadius: 4), with: .color(EchoTheme.magenta.opacity(0.52)))
            let start = CGPoint(x: center.x - w * 0.40, y: center.y)
            let end = CGPoint(x: center.x + w * 0.40, y: center.y)
            let orbPoint = point(start, end, smooth)
            techRing(context: &context, center: orbPoint, radius: 19, color: tint, width: 2, opacity: boost)
            techOrb(context: &context, center: orbPoint, radius: 10, color: Color.white.opacity(abs(orbPoint.x - center.x) < 18 ? boost : 1))

        case .chronoResearch:
            for index in 0..<3 {
                let wave = (local + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                techRing(context: &context, center: center, radius: CGFloat(18 + wave * (45 + boost * 25)), color: tint, width: 2, opacity: 1 - wave)
            }
            techOrb(context: &context, center: center, radius: 10, color: .white)
            techOrb(context: &context, center: CGPoint(x: center.x + CGFloat(42 + boost * 42), y: center.y), radius: 9, color: EchoTheme.violet, hollow: true)

        case .rewind:
            let start = CGPoint(x: center.x - w * 0.38, y: center.y + 18)
            let end = CGPoint(x: center.x + w * 0.38, y: center.y - 17)
            techLine(context: &context, from: start, to: end, color: tint.opacity(0.65), width: 2, dashed: true)
            let back = max(0, min(1, smooth * (0.38 + boost * 0.62)))
            techOrb(context: &context, center: point(end, start, back), radius: 10, color: .white)
            techIcon(context: &context, name: "arrow.counterclockwise", center: center, color: tint)

        case .anchorResearch:
            techRing(context: &context, center: center, radius: CGFloat(30 + boost * 32), color: tint, width: 2, opacity: 0.70)
            techOrb(context: &context, center: CGPoint(x: center.x - 40 + CGFloat(smooth) * 80, y: center.y + 18), radius: 10, color: .white)
            let hazardTravel = smooth * (1 - boost * 0.72)
            techPolygon(context: &context, center: CGPoint(x: center.x + 58 - CGFloat(hazardTravel) * 72, y: center.y - 19), radius: 13, sides: 7, color: .orange, filled: true)
            techIcon(context: &context, name: "hourglass", center: center, color: tint)

        case .repulseResearch:
            techOrb(context: &context, center: center, radius: 10, color: .white)
            let wave = max(0, min(1, (local - 0.15) * 1.4))
            let radius = CGFloat(18 + wave * (42 + boost * 38))
            techRing(context: &context, center: center, radius: radius, color: EchoTheme.magenta, width: 3, opacity: 1 - wave * 0.55)
            for index in 0..<5 {
                let angle = Double(index) / 5 * .pi * 2
                let distance = 27 + wave * (35 + boost * 36)
                techPolygon(context: &context, center: CGPoint(x: center.x + CGFloat(cos(angle) * distance), y: center.y + CGFloat(sin(angle) * distance * 0.42)), radius: 7, sides: 6, color: .orange, filled: true)
            }

        case .prismResearch:
            techPolygon(context: &context, center: center, radius: 23, sides: 3, color: tint, filled: false)
            let left = CGPoint(x: center.x - w * 0.46, y: center.y)
            let right = CGPoint(x: center.x + w * 0.46, y: center.y)
            techLine(context: &context, from: left, to: CGPoint(x: center.x - 18, y: center.y), color: .red, width: 4)
            techLine(context: &context, from: CGPoint(x: center.x - 18, y: center.y), to: CGPoint(x: center.x + 18, y: center.y - CGFloat(boost * 30)), color: EchoTheme.cyan, width: 3)
            techLine(context: &context, from: CGPoint(x: center.x + 18, y: center.y - CGFloat(boost * 30)), to: right, color: EchoTheme.violet, width: 3)
            techOrb(context: &context, center: center, radius: 8, color: .white)
        }
    }

}
