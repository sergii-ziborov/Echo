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
                        .homeEntrance(appeared, delay: 0.00, reduceMotion: reduceMotion)

                    HomeHero(act: act, cleared: cleared, reduceMotion: reduceMotion)
                        .homeEntrance(appeared, delay: 0.04, reduceMotion: reduceMotion)

                    HomePlayButton(level: level, act: act, reduceMotion: reduceMotion) {
                        model.playPrimary()
                    }
                    .homeEntrance(appeared, delay: 0.09, reduceMotion: reduceMotion)

                    routeBar
                        .homeEntrance(appeared, delay: 0.14, reduceMotion: reduceMotion)

                    continueCard
                        .homeEntrance(appeared, delay: 0.19, reduceMotion: reduceMotion)

                    tagline
                        .homeEntrance(appeared, delay: 0.24, reduceMotion: reduceMotion)
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
