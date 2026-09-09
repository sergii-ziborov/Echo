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
                        IconCircle(system: "bag.fill") { model.openShop() }
                        Spacer()
                        HStack(spacing: 14) {
                            Label("\(model.progress.lives)", systemImage: "heart.fill")
                                .foregroundStyle(EchoTheme.danger)
                            Label("\(model.progress.totalStars)", systemImage: "star.fill")
                                .foregroundStyle(EchoTheme.gold)
                            Label("\(model.progress.points)", systemImage: "diamond.fill")
                                .foregroundStyle(EchoTheme.magenta)
                        }
                        .font(.system(size: 15, weight: .semibold))
                    }

                    EchoMark(size: 160, spinning: true)
                    Wordmark()

                    PrimaryButton(title: "Play") { model.playPrimary() }

                    HStack(spacing: 12) {
                        SecondaryButton(title: "Daily", systemImage: "calendar") {
                            model.openDaily()
                        }
                        SecondaryButton(title: "Levels", systemImage: "square.grid.2x2") {
                            model.openWorlds()
                        }
                        SecondaryButton(title: "Shop", systemImage: "bag.fill") {
                            model.openShop()
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
                                Text("Shop")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(EchoTheme.muted)
                                Image(systemName: "bag.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(EchoTheme.gold)
                                Text("\(model.progress.points) pts")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                Text(ownedSummary)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(EchoTheme.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .onTapGesture { model.openShop() }
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

    private var ownedSummary: String {
        let total = BonusKind.allCases.reduce(0) { $0 + model.progress.count($1) }
        if total == 0 { return "Buy freeze, dash, shield" }
        return "\(total) item\(total == 1 ? "" : "s") ready"
    }
}
