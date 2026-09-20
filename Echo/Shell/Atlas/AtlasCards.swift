import SwiftUI

struct ActHeroCard: View {
    let act: Act
    let cleared: Int
    let stars: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(String(format: "%02d", act.rawValue))
                .font(.system(size: 94, weight: .black, design: .rounded))
                .foregroundStyle(act.atlasTint.opacity(0.07))
                .offset(x: 4, y: -18)
                .accessibilityHidden(true)

            VStack(spacing: 11) {
                HStack(spacing: 12) {
                    AtlasRegionGlyph(act: act, reduceMotion: reduceMotion)
                        .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("REGION \(String(format: "%02d", act.rawValue)) · \(act.title)")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(act.atlasTint)
                        Text(act.atlasRegion)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(act.blurb)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.68))
                            .lineLimit(1)

                        HStack(spacing: 5) {
                            ForEach(act.atlasTraits, id: \.self) { trait in
                                Text(trait)
                                    .font(.system(size: 7, weight: .black, design: .rounded))
                                    .tracking(0.6)
                                    .foregroundStyle(Color.white.opacity(0.82))
                                    .padding(.horizontal, 7)
                                    .frame(height: 19)
                                    .background(act.atlasTint.opacity(0.14), in: Capsule())
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
                    .foregroundStyle(Color.white.opacity(0.62))

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.10))
                            Capsule()
                                .fill(LinearGradient(colors: [act.atlasTint, EchoTheme.cyanBright], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(cleared) / CGFloat(act.range.count))
                                .shadow(color: act.atlasTint.opacity(0.5), radius: 4)
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(16)
        }
        .frame(height: 164)
        .background {
            GeometryReader { geometry in
                Image(act.atlasCoverAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [EchoTheme.navyDeep.opacity(0.18), EchoTheme.navyDeep.opacity(0.72), EchoTheme.navyDeep.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .opacity(0.82)
                    .accessibilityHidden(true)
            }
        }
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
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
    }
}

struct ActRouteCard: View {
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

