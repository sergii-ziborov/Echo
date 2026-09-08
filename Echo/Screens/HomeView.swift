import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack {
                        IconCircle(system: "gearshape") { model.openSettings() }
                        Spacer()
                        HStack(spacing: 14) {
                            Label("\(model.progress.totalStars)", systemImage: "star.fill")
                                .foregroundStyle(EchoTheme.gold)
                            Label("\(model.progress.shards)", systemImage: "diamond.fill")
                                .foregroundStyle(EchoTheme.magenta)
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }

                    EchoMark(size: 160, spinning: true)
                    Wordmark()

                    PrimaryButton(title: "Play") { model.playPrimary() }

                    HStack(spacing: 12) {
                        SecondaryButton(title: "Daily Challenge", systemImage: "calendar") {
                            model.openDaily()
                        }
                        SecondaryButton(title: "Levels", systemImage: "square.grid.2x2") {
                            model.openWorlds()
                        }
                    }

                    HStack(spacing: 12) {
                        PanelCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(EchoTheme.muted)
                                Text("Level \(model.continueLevel.number)")
                                    .font(.system(size: 20, weight: .semibold))
                                EchoMark(size: 56, spinning: false)
                                    .frame(maxWidth: .infinity)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onTapGesture { model.playPrimary() }

                        PanelCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Next Reward")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(EchoTheme.muted)
                                Image(systemName: "star.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(EchoTheme.gold)
                                ProgressView(value: shardProgress)
                                    .tint(EchoTheme.cyan)
                                Text("\(model.progress.shards % 10)/10")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(EchoTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Text("Your past is part of the puzzle.")
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(EchoTheme.muted)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
        }
    }

    private var shardProgress: Double {
        Double(model.progress.shards % 10) / 10.0
    }
}
