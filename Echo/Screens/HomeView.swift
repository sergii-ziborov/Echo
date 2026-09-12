import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var level: LevelDefinition { model.continueLevel }
    private var act: Act { Act.containing(level: level.number) }
    private var cleared: Int {
        LevelCatalog.playable.filter { model.progress.progress(for: $0.id).stars > 0 }.count
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            HomeStarfield(reduceMotion: reduceMotion)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar
                        .homeEntrance(appeared, delay: 0.02, reduceMotion: reduceMotion)

                    HomeHero(act: act, cleared: cleared, reduceMotion: reduceMotion)
                        .homeEntrance(appeared, delay: 0.08, reduceMotion: reduceMotion)

                    HomePlayButton(level: level, act: act, reduceMotion: reduceMotion) {
                        model.playPrimary()
                    }
                    .homeEntrance(appeared, delay: 0.16, reduceMotion: reduceMotion)

                    routeBar
                        .homeEntrance(appeared, delay: 0.23, reduceMotion: reduceMotion)

                    continueCard
                        .homeEntrance(appeared, delay: 0.30, reduceMotion: reduceMotion)

                    tagline
                        .homeEntrance(appeared, delay: 0.37, reduceMotion: reduceMotion)
                }
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            IconCircle(system: "gearshape") { model.openSettings() }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.progress.difficulty.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.8)
                HStack(spacing: 5) {
                    HomePulseDot(tint: .green, reduceMotion: reduceMotion)
                    Text("TIMELINE ONLINE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(EchoTheme.cyan)
                }
            }

            Spacer(minLength: 6)

            ResourcePill(value: model.progress.totalStars, systemImage: "checkmark.seal.fill", tint: EchoTheme.gold)
            ResourcePill(value: model.progress.points, systemImage: "diamond.fill", tint: EchoTheme.magenta)
        }
    }

    private var routeBar: some View {
        HStack(spacing: 9) {
            HomeRouteButton(title: "Daily", systemImage: "calendar", tint: EchoTheme.gold) {
                model.openDaily()
            }
            HomeRouteButton(title: "Acts", systemImage: "square.grid.2x2", tint: EchoTheme.cyan) {
                model.openWorlds()
            }
            HomeRouteButton(title: "Lab", systemImage: "hexagon.fill", tint: EchoTheme.magenta) {
                model.openShop()
            }
            HomeRouteButton(title: "Wiki", systemImage: "books.vertical.fill", tint: EchoTheme.cyanBright) {
                model.openWiki()
            }
        }
    }

    private var continueCard: some View {
        Button {
            model.playPrimary()
        } label: {
            ZStack(alignment: .topTrailing) {
                Text(String(format: "%02d", level.number))
                    .font(.system(size: 82, weight: .black, design: .rounded))
                    .foregroundStyle(act.homeTint.opacity(0.045))
                    .offset(x: 4, y: 18)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Label("CONTINUE", systemImage: "play.fill")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(act.homeTint)
                        Spacer()
                        Text("\(cleared)/\(LevelCatalog.playable.count) CLEARED")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.7)
                            .foregroundStyle(EchoTheme.muted)
                    }

                    HStack(spacing: 14) {
                        LevelMiniMap(level: level, tint: act.homeTint, reduceMotion: reduceMotion)
                            .frame(width: 76, height: 76)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("ACT \(String(format: "%02d", act.rawValue)) · \(act.title)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(EchoTheme.muted)
                            Text(level.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(level.subtitle)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.58))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .layoutPriority(1)

                        Spacer(minLength: 2)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(EchoTheme.navyDeep)
                            .frame(width: 38, height: 38)
                            .background(act.homeTint, in: Circle())
                            .shadow(color: act.homeTint.opacity(0.34), radius: 10)
                    }

                    VStack(spacing: 6) {
                        HStack {
                            Text("WORLD PROGRESS")
                            Spacer()
                            Text("\(Int((Double(cleared) / Double(LevelCatalog.playable.count) * 100).rounded()))%")
                        }
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(EchoTheme.muted)

                        HomeProgressBar(
                            value: Double(cleared) / Double(LevelCatalog.playable.count),
                            tint: act.homeTint,
                            animate: appeared,
                            reduceMotion: reduceMotion
                        )
                    }
                }
                .padding(17)
            }
            .background(
                LinearGradient(
                    colors: [EchoTheme.panel.opacity(0.97), act.homeTint.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 25, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [act.homeTint.opacity(0.34), Color.white.opacity(0.07)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel("Continue with level \(level.number), \(level.name)")
    }

    private var tagline: some View {
        HStack(spacing: 11) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, EchoTheme.cyan.opacity(0.28)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
            Text(LevelCatalog.worldTagline)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .italic()
                .foregroundStyle(EchoTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(LinearGradient(colors: [EchoTheme.magenta.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
        .padding(.top, 3)
    }

}

private struct HomeHero: View {
    let act: Act
    let cleared: Int
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack(alignment: .top) {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: 63)
                    for index in 0..<3 {
                        let expansion = CGFloat(index) * 18
                        let rect = CGRect(
                            x: center.x - 86 - expansion,
                            y: center.y - 43 - expansion * 0.36,
                            width: 172 + expansion * 2,
                            height: 86 + expansion * 0.72
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color((index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta).opacity(0.10 - Double(index) * 0.02)),
                            style: StrokeStyle(lineWidth: 1, dash: [4 + CGFloat(index) * 2, 9])
                        )
                    }

                    for index in 0..<4 {
                        let angle = time * (0.17 + Double(index) * 0.025) + Double(index) * .pi / 2
                        let rx = 92.0 + Double(index % 2) * 21
                        let ry = 46.0 + Double(index % 2) * 8
                        let point = CGPoint(
                            x: center.x + CGFloat(cos(angle) * rx),
                            y: center.y + CGFloat(sin(angle) * ry)
                        )
                        let diameter = CGFloat(index == 0 ? 6 : 3.5)
                        let color = index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta
                        context.fill(
                            Path(ellipseIn: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)),
                            with: .color(color.opacity(index == 0 ? 0.9 : 0.55))
                        )
                    }
                }

                VStack(spacing: 1) {
                    EchoMark(size: 126, spinning: !reduceMotion)
                        .scaleEffect(reduceMotion ? 1 : 1 + 0.018 * sin(time * 1.1))

                    Wordmark(titleSize: 43, subtitleSize: 9)

                    HStack(spacing: 7) {
                        HomeHeroPill(
                            text: "ACT \(String(format: "%02d", act.rawValue)) · \(act.title)",
                            tint: act.homeTint
                        )
                        HomeHeroPill(
                            text: cleared == LevelCatalog.playable.count
                                ? "ARCHIVE COMPLETE"
                                : "\(LevelCatalog.playable.count - cleared) TIMELINES REMAIN",
                            tint: EchoTheme.magenta
                        )
                    }
                    .padding(.top, 8)
                }
                .offset(y: reduceMotion ? 0 : CGFloat(sin(time * 0.62) * 1.7))
            }
        }
        .frame(height: 240)
        .accessibilityElement(children: .combine)
    }
}

private struct HomeHeroPill: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 4, height: 4)
            Text(text)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .lineLimit(1)
        }
        .foregroundStyle(Color.white.opacity(0.7))
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
    }
}

private struct HomePlayButton: View {
    let level: LevelDefinition
    let act: Act
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let phase = time.truncatingRemainder(dividingBy: 3.2) / 3.2

            Button(action: action) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .black))
                            .offset(x: 1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("PLAY")
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .tracking(0.8)
                        Text("\(act.title) \(String(format: "%02d", level.number)) · \(level.name)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .opacity(0.72)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .black))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.12), in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [EchoTheme.cyan, EchoTheme.primaryBlueHi, EchoTheme.primaryBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.30), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.28)
                        .rotationEffect(.degrees(16))
                        .offset(x: -geometry.size.width * 0.35 + geometry.size.width * 1.45 * phase)
                    }
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.24), lineWidth: 1))
                .shadow(
                    color: EchoTheme.primaryBlue.opacity(0.40),
                    radius: 15 + CGFloat(reduceMotion ? 0 : 2 * sin(time * 1.4)),
                    y: 7
                )
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("Play level \(level.number), \(level.name)")
        }
    }
}

private struct ResourcePill: View {
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        Label("\(value)", systemImage: systemImage)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .contentTransition(.numericText())
            .padding(.horizontal, 10)
            .frame(height: 37)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.11), Color.white.opacity(0.045)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }
}

private struct HomeRouteButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 29, height: 29)
                    .background(tint.opacity(0.12), in: Circle())
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.075), tint.opacity(0.055)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(title)
    }
}

private struct LevelMiniMap: View {
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

private struct HomeProgressBar: View {
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

private struct HomePulseDot: View {
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

private struct HomeStarfield: View {
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

private struct HomeEntranceModifier: ViewModifier {
    let visible: Bool
    let delay: TimeInterval
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: reduceMotion || visible ? 0 : 18)
            .scaleEffect(reduceMotion || visible ? 1 : 0.985)
            .blur(radius: reduceMotion || visible ? 0 : 5)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.18).delay(delay * 0.25)
                    : .spring(response: 0.66, dampingFraction: 0.84).delay(delay),
                value: visible
            )
    }
}

private extension View {
    func homeEntrance(_ visible: Bool, delay: TimeInterval, reduceMotion: Bool) -> some View {
        modifier(HomeEntranceModifier(visible: visible, delay: delay, reduceMotion: reduceMotion))
    }
}

private extension Act {
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
