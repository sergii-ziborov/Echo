import SpriteKit
import SwiftUI
import UIKit

struct GameView: View {
    @Environment(AppModel.self) var model
#if DEBUG
    var modelOverride: AppModel?
#endif
    let request: PlayRequest
    /// How this run's level was made, so a watch remote can build the same arena.
    let remoteLevel: RemoteLevel

    var activeModel: AppModel {
#if DEBUG
        if let modelOverride { return modelOverride }
#endif
        return model
    }

    @State var session: GameSession
    @State var scene: GameScene
    @State var overlay: InRunOverlay = .none
    @State var awardedPoints = 0
    @State var archiveFinds: [ArchiveDiscovery] = []
    @State var archiveFocus: ArchiveDiscovery?
    @Environment(\.scenePhase) var scenePhase

    init(
        request: PlayRequest,
        overlay: InRunOverlay = .none,
        viewport: CGSize? = nil
    ) {
        self.request = request
        let bounds = viewport ?? UIScreen.main.bounds.size
        var recipe = RemoteLevel(
            id: request.levelID,
            daily: request.daily ? Date() : nil,
            cycle: request.difficultyCycle,
            aspect: Double(bounds.height / max(bounds.width, 1)),
            endless: request.endless
        )
        let fitted = recipe.fitted()
        recipe.bands = Self.interfaceBands(for: fitted, screen: bounds)
        remoteLevel = recipe
        let level = recipe.build()
        let session = GameSession(level: level, daily: request.daily)
        _session = State(initialValue: session)
        _scene = State(initialValue: GameScene(session: session, size: bounds))
        _overlay = State(initialValue: overlay)
    }

    static func interfaceTopInset(_ insets: EdgeInsets) -> CGFloat {
        insets.top > 20 ? insets.top : 62
    }

    /// The arena is the whole screen. Callers that still ask for a playfield
    /// get that full size; the HUD floats over it.
    static func playfieldSize(in screen: CGSize, insets: EdgeInsets = EdgeInsets()) -> CGSize {
        _ = insets
        return screen
    }

    static func arenaRect(for level: LevelDefinition, screen: CGSize, insets: EdgeInsets = EdgeInsets()) -> CGRect {
        _ = (level, insets)
        return CGRect(origin: .zero, size: screen)
    }

    /// The strip the HUD covers, in world units, so a bonus token is not
    /// parked under the chips. The arena itself runs to the screen edges.
    static func interfaceBands(for level: LevelDefinition, screen: CGSize, insets: EdgeInsets = EdgeInsets()) -> InterfaceBands {
        let scale = screen.width / max(CGFloat(level.worldWidth), 1)
        let pickup = GameScene.pickupScale(worldScale: scale)
        let chipsBottom = interfaceTopInset(insets) + 4 + 36
        let overflow = max(0, CGFloat(level.worldHeight) * scale - screen.height)
        let top = chipsBottom + 28 * pickup
        let home = max(insets.bottom, 8)
        return InterfaceBands(
            top: Double((overflow + top) / scale),
            bottom: Double((home + 16 * pickup) / scale),
            token: Double(30 * pickup / scale)
        )
    }

    var body: some View {
        GeometryReader { geo in
            let interfaceTopInset = Self.interfaceTopInset(geo.safeAreaInsets)

            ZStack {
                Color(uiColor: session.level.theme.sky.uiColor).ignoresSafeArea()
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                    .onAppear { scene.resize(to: geo.size) }
                    .onChange(of: geo.size) { _, size in scene.resize(to: size) }

                VStack(spacing: 0) {
                    HUDBar(session: session) {
                        session.togglePause()
                        activeModel.audio.play(.tap)
                    }
                    .padding(.horizontal, 12)

                    if case .ballet = session.phase {
                        Label(Copy.text("play.routeReplay"), systemImage: "waveform.path.ecg")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(2.1)
                            .foregroundStyle(EchoTheme.cyan)
                            .padding(.horizontal, 12)
                            .frame(height: 29)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(EchoTheme.cyan.opacity(0.25), lineWidth: 1))
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }

                    Spacer()

                    if let banner = session.banner {
                        Text(banner.uppercased())
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .allowsHitTesting(false)
                            .padding(.bottom, 8)
                    }

                    if !session.hasStarted {
                        Text(Copy.text("play.dragToMove"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 6)
                    }
                }
                .padding(.top, interfaceTopInset + 4)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))

                if case .paused = session.phase, overlay == .none {
                    PauseView(
                        levelName: session.level.title,
                        rewindCharges: session.sim.rewindCharges,
                        onResume: { session.togglePause() },
                        onRestart: { restart() },
                        onShop: { overlay = .shop },
                        onSettings: { overlay = .settings },
                        onMenu: { activeModel.goHome() },
                        place: storyPlace,
                        log: storyLog
                    )
                }

                if case .won(let result) = session.phase {
                    let seals = LevelCatalog.seals(for: session.level.number)
                    ResultsView(
                        levelName: request.endless.map { Copy.format("play.depthTitle", $0.depth) } ?? session.level.title,
                        result: result,
                        controlSeal: seals.control,
                        paradoxSeal: seals.paradox,
                        bestTime: activeModel.progress.progress(for: resultKey).bestTime,
                        bestMoves: activeModel.progress.progress(for: resultKey).bestMoves,
                        cycleComplete: session.level.number == LevelCatalog.playable.count
                            && activeModel.progress.isCurrentDifficultyComplete,
                        nextDifficulty: DifficultyProfile(cycle: request.difficultyCycle + 1),
                        awardedPoints: awardedPoints,
                        onWatch: { acknowledgeFinds(); session.startBallet(result) },
                        onRetry: { acknowledgeFinds(); restart() },
                        onNext: { acknowledgeFinds(); nextLevel() },
                        onNextCycle: session.level.number == LevelCatalog.playable.count
                            ? { acknowledgeFinds(); activeModel.startNextCycle() }
                            : nil,
                        onMenu: { acknowledgeFinds(); activeModel.goHome() },
                        nextTitle: request.endless.map { Copy.format("endless.depth", $0.depth + 1) } ?? Copy.text("button.next"),
                        archiveFinds: archiveFinds,
                        onArchive: presentArchiveFinds,
                        adMayAppear: activeModel.monetization.decision(adContext) == .allow
                    )
                }

                if case .dead(let cause) = session.phase, overlay == .none {
                    DeathView(
                        cause: cause,
                        rewindCharges: session.sim.rewindCharges,
                        rewindSeconds: session.tuning.rewindSeconds,
                        onRewind: { acknowledgeFinds(); paradoxRewind() },
                        onRestart: { acknowledgeFinds(); request.endless == nil ? restart() : newEndlessRun() },
                        onMenu: { acknowledgeFinds(); leaveAfterCrash() },
                        restartTitle: Copy.text(request.endless == nil ? "button.restartMap" : "button.newExpedition"),
                        note: request.endless.map { Copy.format("play.endlessNote", $0.depth, activeModel.progress.endless.bestDepth) },
                        archiveFinds: archiveFinds,
                        onArchive: presentArchiveFinds
                    )
                }

                if overlay == .shop {
                    ShopView(
                        onBack: { overlay = .none },
                        hostTopInset: interfaceTopInset
                    )
                }

                if overlay == .settings {
                    SettingsView(onBack: { overlay = .none })
                }

                if overlay == .archive {
                    WikiView(section: archiveFocus?.section ?? .basics, focusID: archiveFocus?.id, onBack: { overlay = .none })
                }

                if hasFinishedAttempt, overlay == .finds, !archiveFinds.isEmpty {
                    ArchiveRecoveryView(finds: archiveFinds, onRead: { item in
                        acknowledgeFinds()
                        archiveFocus = item
                        overlay = .archive
                    }, onContinue: acknowledgeFinds)
                }

                if session.phase == .replaying {
                    VStack {
                        Spacer()
                        Text(Copy.text("play.routeReplay"))
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(4)
                            .foregroundStyle(EchoTheme.magenta)
                            .padding(.bottom, 96)
                    }
                    .allowsHitTesting(false)
                }

            }
        }
        .ignoresSafeArea()
        .onDisappear { disappearedFromGame() }
        .onChange(of: session.phase) { _, phase in
            if case .won = phase { prepareResultAdvertising() }
        }
        .onChange(of: LanguagePreference.shared.selection) {
            // SpriteKit captions are nodes, so refresh them without restarting
            // the simulation or changing this run's route and results.
            scene.rebuild()
        }
        .onAppear {
            PhoneWatchLink.shared.attach(
                session: session,
                scene: scene,
                level: remoteLevel,
                actions: PhoneWatchLink.RunActions(rewind: { paradoxRewind() }, retry: { restart() })
            )
            guard !session.viewSetupComplete else { return }
            session.viewSetupComplete = true
            session.configure(tuning: activeModel.progress.playerTuning)
            if let landing = ArrivalCard.Arrival.first(for: request, level: session.level, seen: activeModel.progress.seenHints) {
                _ = activeModel.progress.markHint(landing.key)
            }
            if let key = request.endless {
                session.banner = Copy.format("play.depthTitle", key.depth)
            }
            scene.onEvents = { events in handle(events) }
            scene.onActiveSoloTime = { duration in
                guard request.endless == nil, !request.daily,
                      !session.usedWatchRemote, activeModel.monetization.isForeground else { return }
                activeModel.monetization.budget.addActiveSeconds(duration)
            }
            scene.cometStyle = activeModel.progress.usesTourbillonTail ? .tourbillon : .classic

            session.autoReplay = activeModel.progress.autoReplayEnabled
            activeModel.audio.setHapticsEnabled(activeModel.progress.hapticsEnabled)
            activeModel.audio.enabled = activeModel.progress.soundEnabled
            if session.level.sparks.contains(where: { $0.timer != nil }) {
                offerHint(.timeCrystal)
            }
            if !session.level.movers.isEmpty {
                offerHint(.asteroid)
            }
            if !session.level.gates.isEmpty {
                offerHint(.gate)
            }
            if !session.level.lasers.isEmpty {
                offerHint(.laser)
            }
            if !session.level.gravityWells.isEmpty {
                offerHint(.blackHole)
            }
            if activeModel.progress.consume(.ward) {
                _ = session.sim.activate(.ward)
                session.banner = BonusKind.ward.title
            }
#if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-shot-candy") {
                session.sim.debugEnterReality(.candy)
            }
            let args = ProcessInfo.processInfo.arguments
            let previewKind: BonusKind? = args.contains("-shot-vfx-freeze")
                ? .freeze
                : (args.contains("-shot-vfx-surge") ? .surge : (args.contains("-shot-vfx-shield") ? .shield : nil))
            if let previewKind, session.useBonus(previewKind) {
                scene.abilityEffect(kind: previewKind, at: session.sim.playerPosition)
            }
            if ProcessInfo.processInfo.arguments.contains("-shot-active") {
                session.inputTarget = Vec2(x: 500, y: 300)
                for kind in [BonusKind.shield, .freeze, .surge, .magnet, .phase] {
                    _ = session.useBonus(kind)
                }
                session.resonanceChain = 6
                session.resonanceRemaining = 2.4
            }
#endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, session.phase == .playing {
                session.togglePause()
            }
        }
        .onChange(of: session.banner) { _, new in
            guard new != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1200))
                if session.banner == new {
                    session.banner = nil
                }
            }
        }
    }
}
