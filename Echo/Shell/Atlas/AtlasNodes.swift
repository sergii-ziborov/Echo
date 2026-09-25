import SwiftUI

struct AtlasRouteBackdrop: View {
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

struct AtlasLevelNode: View {
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

struct ActLevelDetailCard: View {
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
                    Text("MAP \(String(format: "%02d", level.number)) · \((LevelLore.entry(for: level.number)?.place ?? act.title).uppercased())")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(act.atlasTint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(level.name)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(unlocked ? .white : EchoTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    if unlocked, let lore = LevelLore.entry(for: level.number) {
                        Text(lore.log)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.72))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(unlocked ? level.subtitle : "Clear map \(max(1, level.number - 1)) to stabilize this route.")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(unlocked ? act.atlasTint.opacity(0.85) : EchoTheme.gold)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 5) {
                        AtlasMapStat(icon: "sparkles", value: "\(level.sparkCount)", tint: EchoTheme.cyan)
                        AtlasMapStat(icon: "circle.dotted", value: "\(level.maxEchoes)", tint: EchoTheme.magenta)
                        if !level.movers.isEmpty {
                            let hasFixedCore = level.movers.contains {
                                if case .stationary = $0.path { return true }
                                return false
                            }
                            AtlasMapStat(icon: "circle.hexagongrid.fill", value: hasFixedCore ? "CORE" : "\(level.movers.count)", tint: .orange)
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

