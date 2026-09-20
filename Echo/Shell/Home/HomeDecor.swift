import SwiftUI

struct LevelMiniMap: View {
    let level: LevelDefinition
    let tint: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            Canvas { context, size in
                let inset: CGFloat = 8
                let sx = (size.width - inset * 2) / CGFloat(level.worldWidth)
                let sy = (size.height - inset * 2) / CGFloat(level.worldHeight)

                func point(_ value: Vec2) -> CGPoint {
                    CGPoint(
                        x: inset + CGFloat(value.x) * sx,
                        y: size.height - inset - CGFloat(value.y) * sy
                    )
                }

                for wall in level.walls {
                    let rect = CGRect(
                        x: inset + CGFloat(wall.minX) * sx,
                        y: size.height - inset - CGFloat(wall.maxY) * sy,
                        width: CGFloat(wall.width) * sx,
                        height: CGFloat(wall.height) * sy
                    )
                    let path = Path(roundedRect: rect, cornerRadius: 1)
                    context.fill(path, with: .color(tint.opacity(0.16)))
                    context.stroke(path, with: .color(tint.opacity(0.52)), lineWidth: 0.7)
                }

                for spark in level.sparks.prefix(8) {
                    let p = point(spark.position)
                    let diameter: CGFloat = spark.timer == nil ? 2.8 : 3.8
                    context.fill(
                        Path(ellipseIn: CGRect(x: p.x - diameter / 2, y: p.y - diameter / 2, width: diameter, height: diameter)),
                        with: .color((spark.timer == nil ? EchoTheme.cyanBright : EchoTheme.gold).opacity(0.9))
                    )
                }

                let exit = point(level.exit)
                let exitPulse = CGFloat(1 + (reduceMotion ? 0 : 0.10 * sin(time * 1.8)))
                let exitRect = CGRect(x: exit.x - 5 * exitPulse, y: exit.y - 5 * exitPulse, width: 10 * exitPulse, height: 10 * exitPulse)
                context.stroke(Path(ellipseIn: exitRect), with: .color(EchoTheme.gold.opacity(0.85)), lineWidth: 1.2)

                let start = point(level.playerStart)
                let startDiameter = CGFloat(5 + (reduceMotion ? 0 : 1.3 * (sin(time * 2.2) + 1)))
                context.fill(
                    Path(ellipseIn: CGRect(x: start.x - startDiameter / 2, y: start.y - startDiameter / 2, width: startDiameter, height: startDiameter)),
                    with: .color(.white)
                )
            }
            .background(
                RadialGradient(
                    colors: [tint.opacity(0.16), EchoTheme.navyDeep.opacity(0.72)],
                    center: .center,
                    startRadius: 2,
                    endRadius: 58
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.22), lineWidth: 1)
            )
        }
        .accessibilityHidden(true)
    }
}

struct HomeProgressBar: View {
    let value: Double
    let tint: Color
    let animate: Bool
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.075))
                Capsule()
                    .fill(LinearGradient(colors: [tint, EchoTheme.cyanBright], startPoint: .leading, endPoint: .trailing))
                    .frame(width: animate ? geometry.size.width * max(0, min(1, value)) : 0)
                    .shadow(color: tint.opacity(0.5), radius: 4)
            }
        }
        .frame(height: 5)
        .animation(
            reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.9, dampingFraction: 0.82).delay(0.32),
            value: animate
        )
    }
}

struct HomePulseDot: View {
    let tint: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Circle()
                .fill(tint)
                .frame(width: 5, height: 5)
                .scaleEffect(reduceMotion ? 1 : 1 + 0.18 * sin(time * 2.4))
                .shadow(color: tint.opacity(0.8), radius: 4 + CGFloat(reduceMotion ? 0 : 2 * sin(time * 2.4)))
        }
    }
}

struct HomeStarfield: View {
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                for index in 0..<24 {
                    let seedX = Double((index * 47 + 13) % 101) / 101
                    let seedY = Double((index * 71 + 29) % 103) / 103
                    let drift = reduceMotion ? 0 : time * (1.2 + Double(index % 5) * 0.32)
                    let y = CGFloat((seedY * Double(size.height) + drift).truncatingRemainder(dividingBy: Double(size.height)))
                    let x = CGFloat(seedX * Double(size.width) + sin(time * 0.12 + Double(index)) * 3)
                    let diameter = CGFloat(index.isMultiple(of: 7) ? 2.1 : 1.1)
                    let color = index.isMultiple(of: 3) ? EchoTheme.cyan : EchoTheme.magenta
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - diameter / 2, y: y - diameter / 2, width: diameter, height: diameter)),
                        with: .color(color.opacity(index.isMultiple(of: 7) ? 0.32 : 0.16))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct HomeEntranceModifier: ViewModifier {
    let visible: Bool
    let delay: TimeInterval
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: reduceMotion || visible ? 0 : 18)
            .scaleEffect(reduceMotion || visible ? 1 : 0.985)
            .blur(radius: reduceMotion || visible ? 0 : 2)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.18).delay(delay * 0.25)
                    : .spring(response: 0.48, dampingFraction: 0.86).delay(delay),
                value: visible
            )
    }
}

extension View {
    func homeEntrance(_ visible: Bool, delay: TimeInterval, reduceMotion: Bool) -> some View {
        modifier(HomeEntranceModifier(visible: visible, delay: delay, reduceMotion: reduceMotion))
    }
}

extension Act {
    var homeTint: Color {
        switch self {
        case .trace: EchoTheme.cyan
        case .drift: EchoTheme.primaryBlueHi
        case .fracture: EchoTheme.violet
        case .debris: .orange
        case .paradox: EchoTheme.magenta
        case .singularity: EchoTheme.danger
        case .rift: Color(red: 0.40, green: 0.62, blue: 1.0)
        case .gravity: EchoTheme.gold
        case .mirage: Color(red: 0.44, green: 0.96, blue: 0.86)
        case .confection: Color(red: 1.0, green: 0.40, blue: 0.76)
        case .eternity: .white
        }
    }
}
