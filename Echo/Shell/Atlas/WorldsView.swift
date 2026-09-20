import SwiftUI

struct WorldsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State var selectedActID: Int
    @State var selectedLevelNumber: Int
    @State var appeared: Bool

    init(act: Act = .trace, levelNumber: Int = 1, appeared: Bool = true) {
        _selectedActID = State(initialValue: act.rawValue)
        _selectedLevelNumber = State(initialValue: levelNumber)
        _appeared = State(initialValue: appeared)
    }

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

                actPage(selectedAct)
                    .id(selectedActID)
                    .transition(.opacity.combined(with: .scale(scale: 0.985)))
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 28)
                            .onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height),
                                      abs(value.translation.width) > 52 else { return }
                                moveAct(by: value.translation.width < 0 ? 1 : -1)
                            }
                    )
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
            IconCircle(system: "chevron.left") {
                model.audio.play(.tap)
                model.goHome()
            }

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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Act.allCases, id: \.rawValue) { act in
                        let selected = act == selectedAct
                        Button {
                            selectAct(act)
                            model.audio.play(.select)
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
                        .id(act.rawValue)
                        .accessibilityLabel("Region \(act.rawValue), \(act.atlasRegion)")
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
                .padding(4)
            }
            .onAppear {
                proxy.scrollTo(selectedActID, anchor: .center)
            }
            .onChange(of: selectedActID) { _, actID in
                withAnimation(.easeOut(duration: reduceMotion ? 0.01 : 0.24)) {
                    proxy.scrollTo(actID, anchor: .center)
                }
            }
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
                        model.audio.play(.select)
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

    private func selectAct(_ act: Act) {
        guard act.rawValue != selectedActID else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedActID = act.rawValue
        }
    }

    private func moveAct(by offset: Int) {
        let acts = Act.allCases
        guard let index = acts.firstIndex(of: selectedAct) else { return }
        let next = min(max(0, index + offset), acts.count - 1)
        guard next != index else { return }
        selectAct(acts[next])
        model.audio.play(.select)
    }
}
