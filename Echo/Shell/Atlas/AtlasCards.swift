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

/// The seven stops of a region on the Fold Road, under the region's own
/// sky, with the Signal looping round the selected stop.
struct ActRouteCard: View {
    let act: Act
    let levels: [LevelDefinition]
    let selectedLevelNumber: Int
    var reduceMotion = false
    let progressFor: (LevelDefinition) -> LevelProgress
    let isUnlocked: (LevelDefinition) -> Bool
    let onSelect: (LevelDefinition) -> Void
    @State private var selectedAt = Date()

    var body: some View {
        let stops = levels.map { AtlasStop(cleared: progressFor($0).stars > 0, unlocked: isUnlocked($0)) }
        let selected = levels.firstIndex { $0.number == selectedLevelNumber }
        let cleared = stops.filter(\.cleared).count

        VStack(spacing: 7) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FOLD ROAD")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                    Text("\(act.region.capitalized) · \(cleared)/\(levels.count) stops cleared")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
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

                ZStack {
                    AtlasRouteLayer(pass: .under, points: points, stops: stops, selected: selected, selectedAt: selectedAt, tint: act.atlasTint, reduceMotion: reduceMotion)

                    ForEach(Array(levels.enumerated()), id: \.element.id) { index, level in
                        AtlasLevelNode(
                            level: level,
                            progress: progressFor(level),
                            unlocked: stops[index].unlocked,
                            selected: selectedLevelNumber == level.number,
                            tint: act.atlasTint,
                            action: { onSelect(level) }
                        )
                        .position(points[index])
                    }

                    AtlasRouteLayer(pass: .over, points: points, stops: stops, selected: selected, selectedAt: selectedAt, tint: act.atlasTint, reduceMotion: reduceMotion)
                }
            }
            .frame(height: 302)
        }
        .padding(13)
        .background {
            AtlasRouteSky(act: act, progress: Double(cleared) / Double(max(1, levels.count)), motion: !reduceMotion)
        }
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(act.atlasTint.opacity(0.24), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .onChange(of: selectedLevelNumber) { _, _ in
            selectedAt = Date()
        }
    }
}
