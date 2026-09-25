import SwiftUI

/// One stop on a region's route. The disc is opaque so the road beneath
/// never shows through, and its centre sits exactly on the route point.
struct AtlasLevelNode: View {
    let level: LevelDefinition
    let progress: LevelProgress
    let unlocked: Bool
    let selected: Bool
    let tint: Color
    let action: () -> Void

    private var cleared: Bool { progress.stars > 0 }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(EchoTheme.navyDeep)
                Circle().fill(
                    RadialGradient(
                        colors: cleared
                            ? [tint.opacity(0.95), tint.opacity(0.42), tint.opacity(0.12)]
                            : unlocked
                                ? [tint.opacity(0.5), tint.opacity(0.16), .clear]
                                : [Color.white.opacity(0.1), Color.white.opacity(0.03), .clear],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: 30
                    )
                )
                Circle()
                    .inset(by: 4.5)
                    .stroke(unlocked ? Color.white.opacity(cleared ? 0.28 : 0.14) : Color.white.opacity(0.05), lineWidth: 0.8)
                Circle()
                    .strokeBorder(
                        selected ? Color.white : unlocked ? tint.opacity(cleared ? 0.9 : 0.6) : Color.white.opacity(0.14),
                        lineWidth: selected ? 2.2 : 1.3
                    )

                if unlocked {
                    Text(String(format: "%02d", level.number))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(cleared ? EchoTheme.navyDeep : .white)
                        .shadow(color: cleared ? Color.white.opacity(0.4) : .clear, radius: 3)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(EchoTheme.muted)
                }
            }
            .frame(width: 48, height: 48)
            .shadow(color: selected ? tint.opacity(0.8) : cleared ? tint.opacity(0.35) : .clear, radius: selected ? 10 : 6)
            .overlay(alignment: .bottom) {
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < progress.stars ? EchoTheme.gold : Color.white.opacity(0.16))
                            .frame(width: 4, height: 4)
                            .shadow(color: index < progress.stars ? EchoTheme.gold.opacity(0.7) : .clear, radius: 2)
                    }
                }
                .offset(y: 11)
            }
            .frame(width: 58, height: 58)
            .contentShape(Circle())
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

