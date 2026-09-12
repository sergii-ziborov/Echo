import SwiftUI

struct WorldsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selectedActID = Act.trace.rawValue
    @State private var selectedLevelNumber = 1
    @State private var appeared = false

    private var selectedAct: Act {
        Act(rawValue: selectedActID) ?? .trace
    }

    var body: some View {
        ZStack {
            AtlasBackground(act: selectedAct, reduceMotion: reduceMotion)

            VStack(spacing: 10) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                actSelector
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                TabView(selection: $selectedActID) {
                    ForEach(Act.allCases, id: \.rawValue) { act in
                        actPage(act)
                            .tag(act.rawValue)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .opacity(appeared ? 1 : 0)
            }
            .frame(maxWidth: 660)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .animation(.easeOut(duration: 0.24), value: selectedActID)
        .animation(.spring(response: 0.58, dampingFraction: 0.84), value: appeared)
        .onAppear {
            let level = model.continueLevel
            selectedActID = Act.containing(level: level.number).rawValue
            selectedLevelNumber = level.number
            appeared = true
        }
        .onDisappear { appeared = false }
        .onChange(of: selectedActID) { _, newValue in
            guard let act = Act(rawValue: newValue) else { return }
            selectRecommendedLevel(in: act)
            model.audio.haptic(.soft)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") { model.goHome() }

            VStack(alignment: .leading, spacing: 2) {
                Text("TIMELINE ATLAS")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.2)
                Text("SWIPE OR CHOOSE A REGION")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                Label("\(model.progress.totalStars)/\(LevelCatalog.playable.count * 3)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(EchoTheme.gold)
                Text(model.progress.difficulty.shortTitle)
                    .foregroundStyle(EchoTheme.magenta)
            }
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(EchoTheme.gold.opacity(0.08), in: Capsule())
            .overlay(Capsule().stroke(EchoTheme.gold.opacity(0.20), lineWidth: 1))
        }
    }

    private var actSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Act.allCases, id: \.rawValue) { act in
                let selected = act == selectedAct
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selectedActID = act.rawValue
                    }
                    model.audio.play(.tap)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: act.atlasIcon)
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%02d", act.rawValue))
                            .font(.system(size: 8, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(selected ? .white : EchoTheme.muted)
                    .frame(width: 48)
                    .frame(height: 45)
                    .background(
                        selected
                            ? AnyShapeStyle(LinearGradient(colors: [act.atlasTint, act.atlasTint.opacity(0.58)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(selected ? act.atlasTint.opacity(0.72) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Region \(act.rawValue), \(act.atlasRegion)")
                .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(4)
        }
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.white.opacity(0.07), lineWidth: 1))
    }

    private func actPage(_ act: Act) -> some View {
        let levels = levels(in: act)
        let selectedLevel = levels.first(where: { $0.number == selectedLevelNumber }) ?? recommendedLevel(in: act)
        let progress = model.progress.progress(for: selectedLevel.id)
        let unlocked = model.progress.isUnlocked(selectedLevel)

        return ScrollView(showsIndicators: false) {
            VStack(spacing: 13) {
                ActHeroCard(
                    act: act,
                    cleared: clearedCount(in: act),
                    stars: starCount(in: act),
                    reduceMotion: reduceMotion
                )

                ActRouteCard(
                    act: act,
                    levels: levels,
                    selectedLevelNumber: selectedLevel.number,
                    progressFor: { model.progress.progress(for: $0.id) },
                    isUnlocked: { model.progress.isUnlocked($0) },
                    onSelect: { level in
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            selectedLevelNumber = level.number
                        }
                        model.audio.play(.tap)
                    }
                )

                ActLevelDetailCard(
                    act: act,
                    level: selectedLevel,
                    progress: progress,
                    unlocked: unlocked,
                    onPlay: { model.play(level: selectedLevel, daily: false) }
                )

                HStack(spacing: 10) {
                    AtlasSummaryMetric(
                        icon: "checkmark.circle.fill",
                        value: "\(clearedCount(in: act))/\(levels.count)",
                        title: "MAPS CLEARED",
                        tint: act.atlasTint
                    )
                    AtlasSummaryMetric(
                        icon: "checkmark.seal.fill",
                        value: "\(starCount(in: act))/\(levels.count * 3)",
                        title: "SEALS FOUND",
                        tint: EchoTheme.gold
                    )
                }
                .padding(.bottom, 24)
            }
            .padding(.top, 2)
        }
    }

    private func levels(in act: Act) -> [LevelDefinition] {
        LevelCatalog.playable.filter { act.range.contains($0.number) }
    }

    private func clearedCount(in act: Act) -> Int {
        levels(in: act).filter { model.progress.progress(for: $0.id).stars > 0 }.count
    }

    private func starCount(in act: Act) -> Int {
        levels(in: act).reduce(0) { $0 + model.progress.progress(for: $1.id).stars }
    }

    private func recommendedLevel(in act: Act) -> LevelDefinition {
        let values = levels(in: act)
        return values.first(where: { model.progress.isUnlocked($0) && model.progress.progress(for: $0.id).stars == 0 })
            ?? values.last(where: { model.progress.isUnlocked($0) })
            ?? values[0]
    }

    private func selectRecommendedLevel(in act: Act) {
        selectedLevelNumber = recommendedLevel(in: act).number
    }
}

private struct ActHeroCard: View {
    let act: Act
    let cleared: Int
    let stars: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(String(format: "%02d", act.rawValue))
                .font(.system(size: 108, weight: .black, design: .rounded))
                .foregroundStyle(act.atlasTint.opacity(0.055))
                .offset(x: 10, y: -23)
                .accessibilityHidden(true)

            HStack(spacing: 13) {
                AtlasRegionGlyph(act: act, reduceMotion: reduceMotion)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 4) {
                    Text("REGION \(String(format: "%02d", act.rawValue)) · \(act.title)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(act.atlasTint)
                    Text(act.atlasRegion)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    Text(act.blurb)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .lineLimit(2)

                    HStack(spacing: 5) {
                        ForEach(act.atlasTraits, id: \.self) { trait in
                            Text(trait)
                                .font(.system(size: 7, weight: .black, design: .rounded))
                                .tracking(0.6)
                                .foregroundStyle(Color.white.opacity(0.76))
                                .padding(.horizontal, 7)
                                .frame(height: 20)
                                .background(act.atlasTint.opacity(0.10), in: Capsule())
                        }
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 0)
            }

            VStack(spacing: 5) {
                HStack {
                    Text("REGION MASTERY")
                    Spacer()
                    Text("\(cleared)/\(act.range.count) · \(stars)/\(act.range.count * 3)")
                }
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(EchoTheme.muted)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.07))
                        Capsule()
                            .fill(LinearGradient(colors: [act.atlasTint, EchoTheme.cyanBright], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geometry.size.width * CGFloat(cleared) / CGFloat(act.range.count))
                            .shadow(color: act.atlasTint.opacity(0.5), radius: 4)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .frame(height: 142)
        .padding(16)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.98), act.atlasTint.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(
                    LinearGradient(colors: [act.atlasTint.opacity(0.42), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

private struct ActRouteCard: View {
    let act: Act
    let levels: [LevelDefinition]
    let selectedLevelNumber: Int
    let progressFor: (LevelDefinition) -> LevelProgress
    let isUnlocked: (LevelDefinition) -> Bool
    let onSelect: (LevelDefinition) -> Void

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("REGION ROUTE")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                    Text("Select a map node to inspect it")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer()
                Label("SWIPE REGION", systemImage: "hand.draw.fill")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(act.atlasTint)
            }
            .padding(.horizontal, 4)

            GeometryReader { geometry in
                let points = AtlasRouteLayout.points(for: act, in: geometry.size)
                let completions = levels.map { progressFor($0).stars > 0 }

                ZStack {
                    AtlasRouteBackdrop(act: act)

                    Canvas { context, _ in
                        for index in 0..<max(0, points.count - 1) {
                            let start = points[index]
                            let end = points[index + 1]
                            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                            let bend = min(35, abs(end.x - start.x) * 0.25 + 12) * direction
                            var path = Path()
                            path.move(to: start)
                            path.addCurve(
                                to: end,
                                control1: CGPoint(x: start.x + bend, y: (start.y + end.y) / 2),
                                control2: CGPoint(x: end.x - bend, y: (start.y + end.y) / 2)
                            )

                            let active = completions.indices.contains(index) && completions[index]
                            if active {
                                context.stroke(path, with: .color(act.atlasTint.opacity(0.16)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                                context.stroke(path, with: .color(act.atlasTint.opacity(0.85)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                            } else {
                                context.stroke(path, with: .color(Color.white.opacity(0.13)), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, dash: [5, 6]))
                            }
                        }
                    }
                    .allowsHitTesting(false)

                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                        AtlasLevelNode(
                            level: level,
                            progress: progressFor(level),
                            unlocked: isUnlocked(level),
                            selected: selectedLevelNumber == level.number,
                            tint: act.atlasTint,
                            action: { onSelect(level) }
                        )
                        .position(points[index])
                    }
                }
            }
            .frame(height: 302)
        }
        .padding(13)
        .background(EchoTheme.navyDeep.opacity(0.82), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(act.atlasTint.opacity(0.20), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
}

private struct AtlasRouteBackdrop: View {
    let act: Act

    var body: some View {
        Canvas { context, size in
            for x in stride(from: CGFloat(20), through: size.width, by: 54) {
                var line = Path()
                line.move(to: CGPoint(x: x, y: 0))
                line.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(line, with: .color(act.atlasTint.opacity(0.035)), lineWidth: 1)
            }
            for y in stride(from: CGFloat(18), through: size.height, by: 52) {
                var line = Path()
                line.move(to: CGPoint(x: 0, y: y))
                line.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(line, with: .color(act.atlasTint.opacity(0.035)), lineWidth: 1)
            }

            for index in 0..<3 {
                let x = size.width * CGFloat(0.22 + Double((index * 31 + act.rawValue * 7) % 55) / 100)
                let y = size.height * CGFloat(0.20 + Double((index * 23 + act.rawValue * 11) % 60) / 100)
                let radius = CGFloat(34 + index * 15)
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: rect), with: .color(act.atlasTint.opacity(0.028)))
                context.stroke(Circle().path(in: rect), with: .color(act.atlasTint.opacity(0.08)), style: StrokeStyle(lineWidth: 1, dash: [3, 8]))
            }
        }
        .background(
            RadialGradient(colors: [act.atlasTint.opacity(0.09), .clear], center: .center, startRadius: 2, endRadius: 220)
        )
        .allowsHitTesting(false)
    }
}

private struct AtlasLevelNode: View {
    let level: LevelDefinition
    let progress: LevelProgress
    let unlocked: Bool
    let selected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    if selected {
                        Circle()
                            .fill(tint.opacity(0.16))
                            .frame(width: 62, height: 62)
                            .blur(radius: 2)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    unlocked ? tint.opacity(progress.stars > 0 ? 0.72 : 0.28) : Color.white.opacity(0.04),
                                    EchoTheme.navyDeep,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 47, height: 47)

                    Circle()
                        .stroke(selected ? tint : unlocked ? tint.opacity(0.52) : Color.white.opacity(0.12), lineWidth: selected ? 2.4 : 1.2)
                        .frame(width: 47, height: 47)
                        .shadow(color: selected ? tint.opacity(0.75) : .clear, radius: 9)

                    if unlocked {
                        Text(String(format: "%02d", level.number))
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(EchoTheme.muted)
                    }
                }

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < progress.stars ? EchoTheme.gold : Color.white.opacity(0.12))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: 66, height: 68)
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(unlocked ? "Map \(level.number), \(level.name), \(progress.stars) seals" : "Locked map \(level.number)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct ActLevelDetailCard: View {
    let act: Act
    let level: LevelDefinition
    let progress: LevelProgress
    let unlocked: Bool
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            HStack(spacing: 13) {
                AtlasLevelPreview(level: level, tint: act.atlasTint)
                    .frame(width: 88, height: 96)

                VStack(alignment: .leading, spacing: 5) {
                    Text("MAP \(String(format: "%02d", level.number)) · \(act.title)")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(act.atlasTint)
                    Text(level.name)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(unlocked ? .white : EchoTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(unlocked ? level.subtitle : "Clear map \(max(1, level.number - 1)) to stabilize this route.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(unlocked ? Color.white.opacity(0.60) : EchoTheme.gold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        AtlasMapStat(icon: "sparkles", value: "\(level.sparkCount)", tint: EchoTheme.cyan)
                        AtlasMapStat(icon: "circle.dotted", value: "\(level.maxEchoes)", tint: EchoTheme.magenta)
                        if !level.movers.isEmpty {
                            AtlasMapStat(icon: "circle.hexagongrid.fill", value: "\(level.movers.count)", tint: .orange)
                        }
                        if !level.lasers.isEmpty {
                            AtlasMapStat(icon: "scope", value: "\(level.lasers.count)", tint: .red)
                        }
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: index < progress.stars ? "checkmark.seal.fill" : "seal")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(index < progress.stars ? EchoTheme.gold : EchoTheme.muted.opacity(0.45))
                    }
                    Text(progress.stars == 3 ? "ALL SEALS" : "\(progress.stars)/3 SEALS")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.7)
                        .foregroundStyle(EchoTheme.muted)
                }

                Spacer()

                if let best = progress.bestTime {
                    Label(String(format: "%.1fs", best), systemImage: "timer")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(EchoTheme.cyan)
                }
            }

            Button(action: onPlay) {
                HStack {
                    Image(systemName: unlocked ? "play.fill" : "lock.fill")
                    Text(unlocked ? "ENTER MAP" : "ROUTE LOCKED")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1)
                    Spacer()
                    Text(unlocked ? level.name.uppercased() : "MAP \(max(1, level.number - 1)) REQUIRED")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
                .foregroundStyle(unlocked ? .white : EchoTheme.muted)
                .padding(.horizontal, 15)
                .frame(height: 43)
                .background(
                    unlocked
                        ? AnyShapeStyle(LinearGradient(colors: [act.atlasTint, act.atlasTint.opacity(0.62)], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.white.opacity(0.045)),
                    in: Capsule()
                )
                .overlay(Capsule().stroke(unlocked ? act.atlasTint.opacity(0.56) : Color.white.opacity(0.07), lineWidth: 1))
            }
            .buttonStyle(PressStyle())
            .disabled(!unlocked)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [EchoTheme.panel.opacity(0.98), act.atlasTint.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 23, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(act.atlasTint.opacity(0.20), lineWidth: 1))
    }
}

private struct AtlasMapStat: View {
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

private struct AtlasSummaryMetric: View {
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

private struct AtlasLevelPreview: View {
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
                let diameter: CGFloat = 5
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: diameter, height: diameter)), with: .color(Color.orange.opacity(0.75)))
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

private struct AtlasRegionGlyph: View {
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

private struct AtlasBackground: View {
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

private enum AtlasRouteLayout {
    static func points(for act: Act, in size: CGSize) -> [CGPoint] {
        let normalized: [(Double, Double)] = switch act.rawValue % 3 {
        case 0:
            [(0.14, 0.84), (0.34, 0.70), (0.66, 0.80), (0.83, 0.60), (0.56, 0.48), (0.28, 0.31), (0.72, 0.14)]
        case 1:
            [(0.15, 0.83), (0.37, 0.69), (0.22, 0.51), (0.48, 0.38), (0.72, 0.52), (0.84, 0.29), (0.57, 0.14)]
        default:
            [(0.17, 0.82), (0.42, 0.84), (0.68, 0.70), (0.82, 0.48), (0.60, 0.34), (0.31, 0.27), (0.49, 0.12)]
        }

        return normalized.map { point in
            CGPoint(x: size.width * point.0, y: size.height * point.1)
        }
    }
}

private extension Act {
    var atlasRegion: String {
        switch self {
        case .trace: "ORIGIN GRID"
        case .drift: "ION EXPANSE"
        case .fracture: "BROKEN VEIL"
        case .debris: "METEOR BELT"
        case .paradox: "FROZEN PARADOX"
        case .singularity: "EVENT HORIZON"
        case .rift: "FOLDED VEIL"
        case .gravity: "DARK TIDE"
        case .mirage: "MIRROR GARDEN"
        case .confection: "CANDY TIMELINE"
        case .eternity: "ETERNAL LOOP"
        }
    }

    var atlasTint: Color {
        switch self {
        case .trace: EchoTheme.cyan
        case .drift: Color(red: 0.32, green: 0.88, blue: 0.70)
        case .fracture: EchoTheme.violet
        case .debris: Color(red: 1.0, green: 0.55, blue: 0.28)
        case .paradox: Color(red: 0.55, green: 0.78, blue: 1.0)
        case .singularity: EchoTheme.magenta
        case .rift: Color(red: 0.40, green: 0.62, blue: 1.0)
        case .gravity: Color(red: 1.0, green: 0.72, blue: 0.28)
        case .mirage: Color(red: 0.44, green: 0.96, blue: 0.86)
        case .confection: Color(red: 1.0, green: 0.40, blue: 0.76)
        case .eternity: Color(red: 0.92, green: 0.92, blue: 1.0)
        }
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

    var atlasTraits: [String] {
        switch self {
        case .trace: ["ECHOES", "ROUTES", "TIMERS"]
        case .drift: ["FIELDS", "ORBIT", "DASH"]
        case .fracture: ["RIFTS", "GATES", "SCARS"]
        case .debris: ["ROCKS", "BOUNCE", "PATROL"]
        case .paradox: ["FREEZE", "PHASE", "CHAINS"]
        case .singularity: ["LASERS", "SWEEPS", "ALL RULES"]
        case .rift: ["WARP", "BACKSTEP", "MIRROR"]
        case .gravity: ["PULL", "ORBIT", "DARK CORE"]
        case .mirage: ["INVERT", "PHASE", "FALSE ROUTES"]
        case .confection: ["CANDY", "SPEED", "RESONANCE"]
        case .eternity: ["77", "CYCLES", "ASCENSION"]
        }
    }
}
