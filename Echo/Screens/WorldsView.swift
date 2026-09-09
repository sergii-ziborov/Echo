import SwiftUI

struct WorldsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                HStack {
                    IconCircle(system: "chevron.left") { model.goHome() }
                    Spacer()
                    Text("WORLDS")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(EchoTheme.muted)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { i in
                        Text("\(i)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(i == 1 ? .white : EchoTheme.muted)
                            .frame(width: 36, height: 36)
                            .background(
                                Capsule().fill(i == 1 ? EchoTheme.primaryBlue : Color.white.opacity(0.06))
                            )
                    }
                }

                VStack(spacing: 4) {
                    Text("1. \(LevelCatalog.worldName.uppercased())")
                        .font(.system(size: 18, weight: .semibold))
                    Text(LevelCatalog.worldTagline)
                        .font(.system(size: 13))
                        .foregroundStyle(EchoTheme.muted)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(LevelCatalog.all) { level in
                        LevelCell(level: level, progress: model.progress.progress(for: level.id), unlocked: model.progress.isUnlocked(level)) {
                            model.play(level: level, daily: false)
                        }
                    }
                }

                Spacer()

                PanelCard {
                    HStack {
                        EchoMark(size: 52, spinning: false)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A BRIGHTER YOU")
                                .font(.system(size: 12, weight: .semibold))
                                .tracking(1.5)
                            Text("\(model.progress.totalStars) / \(LevelCatalog.playable.count * 3)")
                                .foregroundStyle(EchoTheme.muted)
                                .font(.system(size: 13))
                        }
                        Spacer()
                        Image(systemName: "star.fill")
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
}

private struct LevelCell: View {
    var level: LevelDefinition
    var progress: LevelProgress
    var unlocked: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if unlocked {
                    Text("\(level.number)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(i < progress.stars ? EchoTheme.gold : EchoTheme.goldDim.opacity(0.4))
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(EchoTheme.muted)
                        .font(.system(size: 16))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
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
        .accessibilityLabel(unlocked ? "Level \(level.number)" : "Locked level \(level.number)")
    }
}
