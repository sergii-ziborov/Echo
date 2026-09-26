import SwiftUI

struct AtlasMapStat: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        Label(value, systemImage: icon)
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(tint.opacity(0.08), in: Capsule())
    }
}

struct AtlasSummaryMetric: View {
    let icon: String
    let value: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                Text(title)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(tint.opacity(0.14), lineWidth: 1))
    }
}

struct AtlasLevelPreview: View {
    let level: LevelDefinition
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let inset: CGFloat = 8
            let sx = (size.width - inset * 2) / CGFloat(max(level.worldWidth, 1))
            let sy = (size.height - inset * 2) / CGFloat(max(level.worldHeight, 1))

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
                let path = Path(roundedRect: rect, cornerRadius: 1.5)
                context.fill(path, with: .color(tint.opacity(0.13)))
                context.stroke(path, with: .color(tint.opacity(0.48)), lineWidth: 0.65)
            }

            for laser in level.lasers {
                var beam = Path()
                beam.move(to: point(laser.start))
                beam.addLine(to: point(laser.end))
                context.stroke(beam, with: .color(Color.red.opacity(0.46)), style: StrokeStyle(lineWidth: 0.8, dash: [2, 2]))
            }

            for mover in level.movers {
                let p = point(mover.position)
                let diameter = min(11, max(3.5, CGFloat(mover.radius) * sx * 1.2))
                let rockColor: Color = switch mover.material {
                case .basalt: .orange
                case .ice: EchoTheme.cyan
                case .crystal: EchoTheme.magenta
                case .alloy: .white
                case .magma: Color(red: 1, green: 0.42, blue: 0.12)
                case .geode: Color(red: 0.8, green: 0.64, blue: 0.46)
                case .iron: Color(red: 0.62, green: 0.6, blue: 0.58)
                case .comet: Color(red: 0.8, green: 0.95, blue: 1)
                }
                let dot = Path(ellipseIn: CGRect(x: p.x - diameter / 2, y: p.y - diameter / 2, width: diameter, height: diameter))
                context.fill(dot, with: .color(rockColor.opacity(0.78)))
                if case .stationary = mover.path {
                    context.stroke(dot, with: .color(EchoTheme.cyanBright.opacity(0.82)), lineWidth: 1)
                }
            }

            for spark in level.sparks.prefix(10) {
                let p = point(spark.position)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)), with: .color(EchoTheme.cyanBright.opacity(0.92)))
            }

            let start = point(level.playerStart)
            context.fill(Path(ellipseIn: CGRect(x: start.x - 2.5, y: start.y - 2.5, width: 5, height: 5)), with: .color(.white))

            let exit = point(level.exit)
            context.stroke(Path(ellipseIn: CGRect(x: exit.x - 4.5, y: exit.y - 4.5, width: 9, height: 9)), with: .color(EchoTheme.gold.opacity(0.9)), lineWidth: 1.1)
        }
        .background(
            RadialGradient(colors: [tint.opacity(0.13), EchoTheme.navyDeep.opacity(0.86)], center: .center, startRadius: 2, endRadius: 72),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(tint.opacity(0.24), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

struct AtlasRegionGlyph: View {
    let act: Act
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for index in 0..<3 {
                    let radius = CGFloat(22 + index * 9)
                    let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
                    context.stroke(
                        Circle().path(in: rect),
                        with: .color(act.atlasTint.opacity(0.18 - Double(index) * 0.035)),
                        style: StrokeStyle(lineWidth: 1, dash: [3 + CGFloat(index), 6])
                    )
                }

                for index in 0..<3 {
                    let angle = time * (0.42 + Double(index) * 0.05) + Double(index) * .pi * 0.66
                    let radius = 25.0 + Double(index) * 5
                    let point = CGPoint(x: center.x + CGFloat(cos(angle) * radius), y: center.y + CGFloat(sin(angle) * radius))
                    context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(act.atlasTint.opacity(0.75)))
                }
            }
            .overlay {
                Image(systemName: act.atlasIcon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(act.atlasTint)
                    .shadow(color: act.atlasTint.opacity(0.65), radius: 8)
            }
        }
        .background(act.atlasTint.opacity(0.07), in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(act.atlasTint.opacity(0.20), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

struct AtlasBackground: View {
    let act: Act
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            ScreenBackground()

            TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    guard size.width > 0, size.height > 0 else { return }

                    for index in 0..<24 {
                        let seedX = Double((index * 47 + act.rawValue * 17) % 101) / 101
                        let seedY = Double((index * 71 + act.rawValue * 13) % 103) / 103
                        let drift = reduceMotion ? 0 : time * (0.8 + Double(index % 4) * 0.28)
                        let y = CGFloat((seedY * Double(size.height) + drift).truncatingRemainder(dividingBy: Double(size.height)))
                        let x = CGFloat(seedX * Double(size.width) + sin(time * 0.12 + Double(index)) * 2)
                        let diameter = CGFloat(index.isMultiple(of: 8) ? 2.1 : 1.0)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                            with: .color(act.atlasTint.opacity(index.isMultiple(of: 8) ? 0.30 : 0.12))
                        )
                    }
                }
            }
            .ignoresSafeArea()

            Circle()
                .fill(act.atlasTint.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 1)
                .offset(x: 155, y: -290)
                .animation(.easeInOut(duration: 0.35), value: act.rawValue)
        }
    }
}

enum AtlasRouteLayout {
    static func points(for act: Act, in size: CGSize) -> [CGPoint] {
        // Room on every side for the loop round the selected stop.
        let normalized: [(Double, Double)] = switch act.rawValue % 3 {
        case 0:
            [(0.18, 0.84), (0.37, 0.69), (0.64, 0.80), (0.82, 0.60), (0.56, 0.47), (0.28, 0.31), (0.70, 0.15)]
        case 1:
            [(0.18, 0.83), (0.40, 0.70), (0.22, 0.51), (0.48, 0.37), (0.73, 0.52), (0.82, 0.28), (0.55, 0.14)]
        default:
            [(0.19, 0.82), (0.44, 0.85), (0.68, 0.70), (0.82, 0.48), (0.60, 0.33), (0.31, 0.27), (0.50, 0.13)]
        }

        return normalized.map { point in
            CGPoint(x: size.width * point.0, y: size.height * point.1)
        }
    }
}

extension Act {
    var atlasCoverAsset: String {
        switch self {
        case .trace, .drift: "ActOriginCover"
        case .fracture, .debris, .paradox: "ActFractureCover"
        case .singularity, .rift, .gravity: "ActSingularityCover"
        case .mirage: "ActMirageCover"
        case .confection: "CandyTimeline"
        case .eternity: "ActEternityCover"
        }
    }

    var atlasRegion: String { region }

    /// The region's own light, the colour its walls glow in the arena.
    var atlasTint: Color {
        let rgb = theme.wallStroke
        return Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    var atlasIcon: String {
        switch self {
        case .trace: "scope"
        case .drift: "wind"
        case .fracture: "point.3.connected.trianglepath.dotted"
        case .debris: "circle.hexagongrid.fill"
        case .paradox: "snowflake"
        case .singularity: "rays"
        case .rift: "hurricane"
        case .gravity: "circle.circle.fill"
        case .mirage: "arrow.left.and.right"
        case .confection: "birthday.cake.fill"
        case .eternity: "infinity.circle.fill"
        }
    }

    var atlasTraits: [String] { (1...3).map { Copy.text("region.\(key).trait\($0)") } }
}
