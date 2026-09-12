import SwiftUI

struct ScreenBackground: View {
    var body: some View {
        LinearGradient.screenBackground
            .ignoresSafeArea()
            .overlay {
                EchoAmbientOrbs()
                    .allowsHitTesting(false)
            }
    }
}

struct EchoAmbientOrbs: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawOrb(context: &context, size: size, t: t, x: 0.78, y: 0.08, r: 90, color: EchoTheme.cyan)
                drawOrb(context: &context, size: size, t: t * 0.7, x: 0.18, y: 0.16, r: 50, color: EchoTheme.magenta)
                drawOrb(context: &context, size: size, t: t * 1.1, x: 0.9, y: 0.42, r: 40, color: EchoTheme.violet)
            }
        }
        .blur(radius: 0.2)
    }

    private func drawOrb(context: inout GraphicsContext, size: CGSize, t: Double, x: Double, y: Double, r: CGFloat, color: Color) {
        let pulse = 1 + 0.06 * sin(t)
        let rect = CGRect(
            x: size.width * x - r * pulse,
            y: size.height * y - r * pulse,
            width: r * 2 * pulse,
            height: r * 2 * pulse
        )
        context.fill(Circle().path(in: rect), with: .color(color.opacity(0.12)))
    }
}

struct EchoMark: View {
    var size: CGFloat = 220
    var spinning = true

    var body: some View {
        TimelineView(.animation(minimumInterval: spinning ? 1 / 30 : 10, paused: !spinning)) { timeline in
            let t = spinning ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { context, canvasSize in
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2
                let radius = min(canvasSize.width, canvasSize.height) * 0.30
                let count = 16
                var head = CGPoint(x: cx, y: cy)
                for i in 0..<count {
                    let u = Double(i) / Double(count - 1)
                    let angle = 0.85 * .pi + u * 1.55 * .pi + t * 0.22
                    let x = cx + cos(angle) * radius
                    let y = cy + sin(angle) * radius
                    let s = canvasSize.width * (0.10 + 0.06 * u)
                    let color = Color(
                        red: 0.62 + 0.12 * (1 - u),
                        green: 0.32 + 0.55 * u,
                        blue: 1.0
                    )
                    let rect = CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)
                    context.opacity = 0.22 + 0.55 * u
                    context.fill(Circle().path(in: rect), with: .color(color.opacity(0.42)))
                    context.stroke(Circle().path(in: rect.insetBy(dx: 1, dy: 1)), with: .color(color.opacity(0.85)), lineWidth: 1.2)
                    if i == count - 1 { head = CGPoint(x: x, y: y) }
                }
                let core = canvasSize.width * 0.155
                let coreRect = CGRect(x: head.x - core / 2, y: head.y - core / 2, width: core, height: core)
                context.opacity = 1
                context.fill(Circle().path(in: coreRect.insetBy(dx: -12, dy: -12)), with: .color(EchoTheme.cyan.opacity(0.28)))
                context.fill(Circle().path(in: coreRect), with: .color(.white))
            }
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String = "play.fill"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(LinearGradient.primaryButton))
            .shadow(color: EchoTheme.primaryBlue.opacity(0.45), radius: 16, y: 6)
        }
        .buttonStyle(PressStyle())
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }
}

struct GhostButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(EchoTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(PressStyle())
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct Wordmark: View {
    var subtitle: String = "YOU SURVIVE THE TIMELINE YOU CREATED"
    var titleSize: CGFloat = 54
    var subtitleSize: CGFloat = 11

    var body: some View {
        VStack(spacing: 10) {
            Text("ECHO")
                .font(.system(size: titleSize, weight: .ultraLight))
                .tracking(EchoTheme.wordmarkTracking)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: subtitleSize, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(EchoTheme.muted)
                .minimumScaleFactor(0.72)
                .lineLimit(1)
        }
    }
}

struct PanelCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(EchoTheme.panel.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(EchoTheme.panelStroke, lineWidth: 1)
            )
    }
}

struct StarRow: View {
    var filled: Int
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < filled ? "star.fill" : "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(i < filled ? EchoTheme.gold : EchoTheme.goldDim.opacity(0.45))
                    .shadow(color: i < filled ? EchoTheme.gold.opacity(0.6) : .clear, radius: 8)
            }
        }
    }
}

struct IconCircle: View {
    var system: String
    var action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

/// A single icon language is used in the Lab, the arena bar, and the teaching loops.
/// It keeps newly unlocked skills recognizable even when their particle effects overlap.
struct AbilityIconView: View {
    let kind: BonusKind
    var size: CGFloat = 42

    var body: some View {
        let tint = Color(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.34), tint.opacity(0.08), EchoTheme.navyDeep.opacity(0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .stroke(tint.opacity(0.55), lineWidth: 1)
            Circle()
                .fill(tint.opacity(0.20))
                .frame(width: size * 0.72, height: size * 0.72)
                .blur(radius: size * 0.08)
            Image(systemName: kind.icon)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: tint.opacity(0.9), radius: size * 0.12)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum MechanicDemoScenario: Hashable {
    case echo, asteroid, rift, freeze, phase, collision, gate, laser
    case timeCrystal, resonance, blackHole
    case shield, surge, pulse, magnet, chrono, anchor, repulse, prism, blink

    init(bonus: BonusKind) {
        self = switch bonus {
        case .shield, .ward: .shield
        case .freeze: .freeze
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .phase: .phase
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        }
    }

    init(upgrade: UpgradeKind) {
        self = switch upgrade {
        case .velocity, .surgeMastery: .surge
        case .sparkSense: .resonance
        case .dashCapacitor, .dashImpulse: .blink
        case .slots, .reserves, .fabricator: .shield
        case .aegis, .shieldLattice: .shield
        case .fieldAmplifier: .anchor
        case .recharge, .chronoResearch, .rewind, .echoForecast: .chrono
        case .beamForecast: .laser
        case .cryostasis: .freeze
        case .crystalMemory: .timeCrystal
        case .magnetism: .magnet
        case .phaseResearch: .phase
        case .anchorResearch: .anchor
        case .repulseResearch: .repulse
        case .prismResearch: .prism
        case .blinkResearch: .blink
        }
    }

    init(hint: EncounterHint) {
        self = switch hint {
        case .echo: .echo
        case .asteroid: .asteroid
        case .rift, .realityShift: .rift
        case .freeze: .freeze
        case .phase: .phase
        case .collision: .collision
        case .gate: .gate
        case .laser: .laser
        case .timeCrystal: .timeCrystal
        case .resonance: .resonance
        case .blackHole: .blackHole
        case .surge: .surge
        case .pulse: .pulse
        case .magnet: .magnet
        case .chrono: .chrono
        case .anchor: .anchor
        case .repulse: .repulse
        case .prism: .prism
        case .blink: .blink
        }
    }

    var caption: String {
        switch self {
        case .echo: "YOUR OLD ROUTE REPEATS"
        case .asteroid: "WALL HIT → CRACK → BREAK"
        case .rift: "OPEN RING CHANGES THE RULES"
        case .freeze: "HAZARDS STOP · YOU MOVE"
        case .phase: "CROSS THROUGH DANGER"
        case .collision: "TWO ECHOES LEAVE A SCAR"
        case .gate: "WAIT · THEN CROSS"
        case .laser: "CHARGE → FIRE → MOVE"
        case .timeCrystal: "REACH IT BEFORE ZERO"
        case .resonance: "FAST SPARKS BUILD A CHAIN"
        case .blackHole: "PULL OUTSIDE · DEATH INSIDE"
        case .shield: "ONE HIT BOUNCES AWAY"
        case .surge: "SPEED + ELECTRIC TRAIL"
        case .pulse: "NEXT ECHO ARRIVES LATER"
        case .magnet: "SPARKS FLY TO YOU"
        case .chrono: "PUSH THE TIMELINE BACK"
        case .anchor: "WORLD SLOWS · YOU DO NOT"
        case .repulse: "CLEAR SPACE AROUND YOU"
        case .prism: "LASERS BEND AROUND YOU"
        case .blink: "JUMP ACROSS ONE DANGER"
        }
    }

    var tint: Color {
        switch self {
        case .asteroid: .orange
        case .laser, .collision, .repulse: EchoTheme.magenta
        case .shield, .magnet: .green
        case .surge, .timeCrystal, .resonance: EchoTheme.gold
        case .phase, .rift, .chrono, .blink: EchoTheme.violet
        default: EchoTheme.cyan
        }
    }
}

/// A compact real-time teaching loop. It replaces paragraph-only tutorials and
/// behaves like an embedded four-second clip without shipping large video files.
struct MechanicDemoView: View {
    let scenario: MechanicDemoScenario
    var height: CGFloat = 156
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let rawTime = reduceMotion ? 1.9 : timeline.date.timeIntervalSinceReferenceDate
            let progress = rawTime.truncatingRemainder(dividingBy: 4) / 4

            Canvas { context, size in
                drawGrid(context: &context, size: size)
                drawScenario(context: &context, size: size, progress: progress)
            }
            .overlay(alignment: .topLeading) {
                Label("4S LIVE LOOP", systemImage: "play.fill")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 8)
                    .frame(height: 23)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(9)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 5) {
                    Text(scenario.caption)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                    GeometryReader { geometry in
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(scenario.tint)
                                    .frame(width: geometry.size.width * progress)
                            }
                    }
                    .frame(height: 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 9)
            }
        }
        .frame(height: height)
        .background(
            RadialGradient(
                colors: [scenario.tint.opacity(0.17), EchoTheme.navyDeep.opacity(0.98)],
                center: .center,
                startRadius: 2,
                endRadius: 190
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(scenario.tint.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel(scenario.caption)
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
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

    private func drawScenario(context: inout GraphicsContext, size: CGSize, progress t: Double) {
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
            let remaining = max(0.08, 1 - t)
            ring(context: &context, center: CGPoint(x: w * 0.78, y: mid.y), radius: CGFloat(26 + remaining * 7), color: EchoTheme.gold, lineWidth: 3, opacity: remaining)
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
            orb(context: &context, center: mid, radius: 10, color: .white)
            polygon(context: &context, center: CGPoint(x: hazardX, y: mid.y), radius: 12, sides: 7, color: .orange, filled: true)

        case .surge:
            let x = w * (0.10 + min(1, t * 1.55) * 0.80)
            for index in 0..<3 {
                mechanicLightning(
                    context: &context,
                    from: CGPoint(x: x - CGFloat(48 + index * 18), y: mid.y + CGFloat(index * 13 - 13)),
                    to: CGPoint(x: x - 8, y: mid.y + CGFloat(index * 5 - 5)),
                    color: index == 1 ? .white : EchoTheme.gold,
                    seed: index + Int(t * 18)
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

    private func curvePoint(t: Double, size: CGSize) -> CGPoint {
        let u = max(0, min(1, t))
        return CGPoint(
            x: size.width * (0.12 + u * 0.76),
            y: size.height * (0.60 - u * 0.26 + sin(u * .pi * 2) * 0.18)
        )
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        let amount = CGFloat(t)
        return CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
    }

    private func orb(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, hollow: Bool = false) {
        let glowRect = CGRect(x: center.x - radius * 1.65, y: center.y - radius * 1.65, width: radius * 3.3, height: radius * 3.3)
        context.fill(Circle().path(in: glowRect), with: .color(color.opacity(0.13)))
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        if !hollow { context.fill(Circle().path(in: rect), with: .color(color.opacity(0.90))) }
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.95)), lineWidth: hollow ? 2.2 : 1.2)
    }

    private func ring(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, lineWidth: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(max(0, min(1, opacity)))), lineWidth: lineWidth)
    }

    private func line(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color.opacity(0.88)), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dashed ? [5, 5] : []))
    }

    private func polygon(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, sides: Int, color: Color, filled: Bool) {
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

    private func mechanicLightning(
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

    private func snowflake(
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

    private func iceShell(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
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

    private func shieldBubble(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        color: Color,
        impact: Bool
    ) {
        let halo = CGRect(x: center.x - radius * 1.24, y: center.y - radius * 1.24, width: radius * 2.48, height: radius * 2.48)
        context.fill(Circle().path(in: halo), with: .radialGradient(
            Gradient(colors: [.clear, color.opacity(impact ? 0.20 : 0.08)]),
            center: center,
            startRadius: radius * 0.58,
            endRadius: radius * 1.22
        ))
        let shell = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Circle().path(in: shell), with: .linearGradient(
            Gradient(colors: [.white.opacity(0.10), color.opacity(0.035), color.opacity(0.13)]),
            startPoint: CGPoint(x: center.x - radius, y: center.y + radius),
            endPoint: CGPoint(x: center.x + radius, y: center.y - radius)
        ))
        context.stroke(Circle().path(in: shell), with: .color(color.opacity(0.78)), lineWidth: 1.6)
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

    private func mechanicMagneticField(
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

/// A research-specific comparison rather than a generic ability clip. Each node
/// renders its own before/after behavior over an ImageGen branch environment.
struct TechnologyPreviewView: View {
    let kind: UpgradeKind
    let level: Int
    let currentValue: String
    let nextValue: String
    var height: CGFloat = 232

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var loopStartedAt = Date()

    private var tint: Color {
        Color(red: kind.branch.tint.r, green: kind.branch.tint.g, blue: kind.branch.tint.b)
    }

    private var plateName: String {
        switch kind.branch {
        case .motion: "TechMotionPlate"
        case .loadout: "TechLoadoutPlate"
        case .temporal: "TechTemporalPlate"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let rawTime = reduceMotion ? 3.8 : max(0, timeline.date.timeIntervalSince(loopStartedAt))
            let progress = rawTime.truncatingRemainder(dividingBy: 5.4) / 5.4
            let phase = min(2, Int(progress * 3))

            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.12), EchoTheme.navyDeep.opacity(0.42), EchoTheme.navyDeep.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Canvas { context, size in
                    drawComparison(context: &context, size: size, progress: progress)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 7) {
                        ResearchIconView(kind: kind, size: 33)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title.uppercased())
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.7)
                            Text("ANIMATED EFFECT DEMO · 5.4S LOOP")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .tracking(0.4)
                                .foregroundStyle(tint)
                        }
                        Spacer()
                        Button {
                            loopStartedAt = Date()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 31, height: 31)
                                .foregroundStyle(.white)
                                .background(tint.opacity(0.20), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Replay technology demonstration")
                    }
                    .foregroundStyle(.white.opacity(0.90))

                    HStack(spacing: 8) {
                        previewValue("NOW", value: currentValue, tint: EchoTheme.muted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(tint)
                        previewValue(level >= kind.maxLevel ? "STATUS" : "NEXT", value: nextValue, tint: tint)
                    }
                    .padding(.top, 9)

                    Spacer()

                    Text(stageCopy(phase))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 33)
                        .background(EchoTheme.navyDeep.opacity(0.88), in: RoundedRectangle(cornerRadius: 11))

                    HStack(spacing: 5) {
                        stagePill("1 · WITHOUT", active: phase == 0)
                        stagePill("2 · UPGRADE", active: phase == 1)
                        stagePill("3 · WITH", active: phase == 2)
                    }
                    .padding(.top, 7)
                }
                .padding(11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GeometryReader { geometry in
                    Image(plateName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(0.32)
                }
            }
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.42), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.14), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animated comparison for \(kind.title). \(kind.detail)")
    }

    private func previewValue(_ eyebrow: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrow)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .padding(.horizontal, 9)
        .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func stagePill(_ title: String, active: Bool) -> some View {
        Text(title)
            .font(.system(size: 7, weight: .black, design: .rounded))
            .tracking(0.45)
            .foregroundStyle(active ? .white : EchoTheme.muted.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 20)
            .background(active ? tint.opacity(0.48) : Color.black.opacity(0.28), in: Capsule())
            .overlay(Capsule().stroke(active ? tint.opacity(0.8) : Color.white.opacity(0.05), lineWidth: 1))
    }

    private func stageCopy(_ phase: Int) -> String {
        if phase == 0 { return baselineCopy }
        if phase == 1 { return "UPGRADE APPLIED · WATCH THE SAME SCENE CHANGE" }
        return resultCopy
    }

    private var baselineCopy: String {
        switch kind {
        case .velocity: "BEFORE · THE CRYSTAL IS JUST OUT OF REACH"
        case .sparkSense: "BEFORE · YOU MUST TOUCH EVERY SPARK"
        case .dashCapacitor: "BEFORE · DASH IS STILL RECHARGING"
        case .surgeMastery: "BEFORE · THE LIGHTNING TRAIL ENDS EARLY"
        case .dashImpulse: "BEFORE · ONE DASH STOPS INSIDE DANGER"
        case .slots: "BEFORE · ONLY CURRENT ABILITY BUTTONS FIT"
        case .reserves: "BEFORE · CHARGES RUN OUT SOONER"
        case .fabricator: "BEFORE · EACH CHARGE COSTS MORE"
        case .aegis: "BEFORE · SHIELD RECOVERY ENDS SOONER"
        case .shieldLattice:
            level + 1 >= kind.maxLevel
                ? "BEFORE · ONE IMPACT BREAKS THE SHIELD"
                : "BEFORE · THE SAFE WINDOW FADES SOONER"
        case .fieldAmplifier: "BEFORE · TIMED EFFECTS EXPIRE SOONER"
        case .recharge: "BEFORE · ABILITIES STAY LOCKED LONGER"
        case .beamForecast: "BEFORE · THE LASER WARNING COMES LATE"
        case .cryostasis: "BEFORE · HAZARDS START MOVING SOONER"
        case .echoForecast: "BEFORE · YOUR ECHO FOLLOWS CLOSER"
        case .crystalMemory: "BEFORE · THE CRYSTAL FREEZES A SMALL WINDOW"
        case .magnetism: "BEFORE · DISTANT SPARKS STAY PUT"
        case .phaseResearch: "BEFORE · SOLID HAZARDS BLOCK THE ROUTE"
        case .chronoResearch: "BEFORE · THE NEXT EVENT ARRIVES SOONER"
        case .rewind: "BEFORE · ONLY A SHORT ROUTE CAN BE UNDONE"
        case .anchorResearch: "BEFORE · THE WHOLE WORLD MOVES AT FULL SPEED"
        case .repulseResearch: "BEFORE · NEARBY HAZARDS KEEP CLOSING IN"
        case .prismResearch: "BEFORE · LASERS CROSS YOUR POSITION"
        case .blinkResearch: "BEFORE · THE JUMP ENDS BEFORE SAFETY"
        }
    }

    private var resultCopy: String {
        switch kind {
        case .velocity: "AFTER · YOU REACH THE CRYSTAL SOONER"
        case .sparkSense: "AFTER · THE WIDER RING COLLECTS IT FOR YOU"
        case .dashCapacitor: "AFTER · DASH BECOMES READY SOONER"
        case .surgeMastery: "AFTER · SURGE AND LIGHTNING LAST LONGER"
        case .dashImpulse: "AFTER · ONE DASH CLEARS THE ENTIRE HAZARD"
        case .slots: "AFTER · ONE MORE ABILITY CAN BE EQUIPPED"
        case .reserves: "AFTER · EVERY ABILITY GAINS TWO CHARGES"
        case .fabricator: "AFTER · FUTURE CHARGES COST FEWER POINTS"
        case .aegis: "AFTER · THE SAFE RECOVERY WINDOW IS LONGER"
        case .shieldLattice:
            level + 1 >= kind.maxLevel
                ? "AFTER · TWO LAYERS CAN ABSORB TWO HITS"
                : "AFTER · THE SAFE WINDOW HOLDS LONGER"
        case .fieldAmplifier: "AFTER · EVERY TIMED FIELD LASTS LONGER"
        case .recharge: "AFTER · THE NEXT ACTIVATION ARRIVES SOONER"
        case .beamForecast: "AFTER · THE WARNING APPEARS EARLIER"
        case .cryostasis: "AFTER · FROZEN HAZARDS WAIT LONGER"
        case .echoForecast: "AFTER · MORE SPACE OPENS BEHIND YOU"
        case .crystalMemory: "AFTER · THE CRYSTAL FREEZES FOR LONGER"
        case .magnetism: "AFTER · THE FIELD PULLS DISTANT SPARKS IN"
        case .phaseResearch: "AFTER · YOU PASS THROUGH THE HAZARD"
        case .chronoResearch: "AFTER · THE TIMELINE IS PUSHED BACK"
        case .rewind: "AFTER · MORE OF YOUR ROUTE RETURNS"
        case .anchorResearch: "AFTER · HAZARDS SLOW WHILE YOU STAY FAST"
        case .repulseResearch: "AFTER · THE WIDER BLAST CLEARS THE ROOM"
        case .prismResearch: "AFTER · THE PRISM BENDS THE BEAM AWAY"
        case .blinkResearch: "AFTER · THE LONGER JUMP REACHES SAFETY"
        }
    }

    private func drawComparison(context: inout GraphicsContext, size: CGSize, progress t: Double) {
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

    private func drawTechnology(
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
            for index in 0..<3 {
                let y = orbPoint.y + CGFloat(index * 10 - 10)
                techLightning(
                    context: &context,
                    from: CGPoint(x: orbPoint.x - trailLength - CGFloat(index * 7), y: y + CGFloat(index.isMultiple(of: 2) ? 8 : -7)),
                    to: CGPoint(x: orbPoint.x - 8, y: y),
                    color: index == 1 ? .white : EchoTheme.gold,
                    seed: index + Int(t * 20)
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
            techOrb(context: &context, center: center, radius: 10, color: .white)
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

    private func point(_ start: CGPoint, _ end: CGPoint, _ amount: Double) -> CGPoint {
        let value = CGFloat(max(0, min(1, amount)))
        return CGPoint(x: start.x + (end.x - start.x) * value, y: start.y + (end.y - start.y) * value)
    }

    private func techOrb(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, hollow: Bool = false) {
        let glow = CGRect(x: center.x - radius * 1.8, y: center.y - radius * 1.8, width: radius * 3.6, height: radius * 3.6)
        context.fill(Circle().path(in: glow), with: .color(color.opacity(0.14)))
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        if !hollow { context.fill(Circle().path(in: rect), with: .color(color.opacity(0.94))) }
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(0.96)), lineWidth: hollow ? 2.2 : 1.2)
    }

    private func techRing(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color, width: CGFloat, opacity: Double) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.stroke(Circle().path(in: rect), with: .color(color.opacity(max(0, min(1, opacity)))), lineWidth: width)
    }

    private func techArc(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, progress: Double, color: Color, width: CGFloat) {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func techLine(context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color, width: CGFloat, dashed: Bool = false) {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dashed ? [5, 5] : []))
    }

    private func techLightning(
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

    private func techSnowflake(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, opacity: Double) {
        var path = Path()
        for branch in 0..<3 {
            let angle = CGFloat(branch) / 3 * .pi
            let delta = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            path.move(to: CGPoint(x: center.x - delta.x, y: center.y - delta.y))
            path.addLine(to: CGPoint(x: center.x + delta.x, y: center.y + delta.y))
        }
        context.stroke(path, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
    }

    private func techIceShell(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
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

    private func techShieldBubble(
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
            context.fill(Circle().path(in: rect), with: .color(.green.opacity(layer == 0 ? 0.075 : 0.025)))
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

    private func techMagneticField(
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

    private func techCrystal(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, color: Color) {
        techPolygon(context: &context, center: center, radius: radius, sides: 4, color: color, filled: true)
    }

    private func techPolygon(context: inout GraphicsContext, center: CGPoint, radius: CGFloat, sides: Int, color: Color, filled: Bool) {
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

    private func techIcon(context: inout GraphicsContext, name: String, center: CGPoint, color: Color) {
        var symbol = context.resolve(Image(systemName: name))
        symbol.shading = .color(color)
        context.draw(symbol, at: center)
    }
}
