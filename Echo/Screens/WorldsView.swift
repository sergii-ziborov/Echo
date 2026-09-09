import SwiftUI

struct WorldsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack {
                        IconCircle(system: "chevron.left") { model.goHome() }
                        Spacer()
                        Text("TIMELINE")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(EchoTheme.muted)
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }

                    ForEach(Act.allCases, id: \.rawValue) { act in
                        actBlock(act)
                    }

                    PanelCard {
                        HStack {
                            EchoMark(size: 52, spinning: false)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SEALS")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1.5)
                                Text("\(model.progress.totalStars) / \(LevelCatalog.playable.count * 3)")
                                    .foregroundStyle(EchoTheme.muted)
                                    .font(.system(size: 13))
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(EchoTheme.gold)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
    }

    private func actBlock(_ act: Act) -> some View {
        let levels = LevelCatalog.playable.filter { act.range.contains($0.number) }
        let cleared = levels.filter { model.progress.progress(for: $0.id).stars > 0 }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(act.rawValue). \(act.title)")
                    .font(.system(size: 16, weight: .semibold))
                    .tracking(1.4)
                Spacer()
                Text("\(cleared)/\(levels.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
            Text(act.blurb)
                .font(.system(size: 13))
                .foregroundStyle(EchoTheme.muted)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(levels) { level in
                    LevelCell(
                        level: level,
                        progress: model.progress.progress(for: level.id),
                        unlocked: model.progress.isUnlocked(level)
                    ) {
                        model.play(level: level, daily: false)
                    }
                }
            }
        }
    }
}

private struct LevelCell: View {
    var level: LevelDefinition
    var progress: LevelProgress
    var unlocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if unlocked {
                    Text("\(level.number)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(level.name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(EchoTheme.muted)
                        .lineLimit(1)
                    HStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: i < progress.stars ? "checkmark.seal.fill" : "seal")
                                .font(.system(size: 8))
                                .foregroundStyle(i < progress.stars ? EchoTheme.cyan : EchoTheme.muted.opacity(0.5))
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(EchoTheme.muted)
                        .font(.system(size: 16))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 78)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(unlocked ? 0.08 : 0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(unlocked ? 0.12 : 0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PressStyle())
        .disabled(!unlocked)
        .accessibilityLabel(unlocked ? "\(level.name), level \(level.number)" : "Locked level \(level.number)")
    }
}
