import SpriteKit
import SwiftUI
import UIKit

struct GameView: View {
    @Environment(AppModel.self) var model
    let request: PlayRequest

    @State var session: GameSession
    @State var scene: GameScene
    @State var overlay: InRunOverlay = .none
    @State var awardedPoints = 0
    @State var hint: EncounterHint? = ProcessInfo.processInfo.arguments.contains("-shot-hint") ? .echo : nil
    @Environment(\.scenePhase) var scenePhase

    init(request: PlayRequest) {
        self.request = request
        let raw: LevelDefinition
        if request.daily {
            raw = LevelCatalog.daily()
        } else {
            raw = LevelCatalog.level(id: request.levelID) ?? LevelCatalog.prototype
        }
        let bounds = UIScreen.main.bounds.size
        let aspect = Double(bounds.height / max(bounds.width, 1))
        let level = raw
            .difficultyAdjusted(for: request.difficultyCycle)
            .fitted(aspect: aspect)
        let session = GameSession(level: level, daily: request.daily)
        _session = State(initialValue: session)
        _scene = State(initialValue: GameScene(session: session, size: bounds))
    }

    var body: some View {
        GeometryReader { geo in
            let interfaceTopInset = geo.safeAreaInsets.top > 20 ? geo.safeAreaInsets.top : 62

            ZStack {
                SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                    .ignoresSafeArea()
                    .onAppear { scene.resize(to: geo.size) }
                    .onChange(of: geo.size) { _, size in scene.resize(to: size) }

                VStack(spacing: 0) {
                    HUDBar(session: session) {
                        session.togglePause()
                        model.audio.play(.tap)
                    }
                    .padding(.horizontal, 12)

                    if case .ballet = session.phase {
                        Label("TEMPORAL REPLAY", systemImage: "waveform.path.ecg")
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

                    HStack(alignment: .bottom) {
                        InventoryBar(session: session) { kind in
                            useItem(kind)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)

                    if !session.hasStarted {
                        Text("Drag to move")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 6)
                    }
                }
                .padding(.top, interfaceTopInset + 4)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))

                if case .paused = session.phase, overlay == .none {
                    PauseView(
                        levelName: session.level.name,
                        rewindCharges: session.sim.rewindCharges,
                        onResume: { session.togglePause() },
                        onRestart: { restart() },
                        onShop: { overlay = .shop },
                        onSettings: { overlay = .settings },
                        onMenu: { model.goHome() }
                    )
                }

                if case .won(let result) = session.phase {
                    let seals = LevelCatalog.seals(for: session.level.number)
                    ResultsView(
                        levelName: session.level.name,
                        result: result,
                        controlSeal: seals.control,
                        paradoxSeal: seals.paradox,
                        bestTime: model.progress.progress(for: resultKey).bestTime,
                        bestMoves: model.progress.progress(for: resultKey).bestMoves,
                        cycleComplete: session.level.number == LevelCatalog.playable.count
                            && model.progress.isCurrentDifficultyComplete,
                        nextDifficulty: DifficultyProfile(cycle: request.difficultyCycle + 1),
                        awardedPoints: awardedPoints,
                        onWatch: { session.startBallet(result) },
                        onRetry: { restart() },
                        onNext: nextLevel,
                        onNextCycle: session.level.number == LevelCatalog.playable.count
                            ? { model.startNextCycle() }
                            : nil,
                        onMenu: { model.goHome() }
                    )
                }

                if case .dead(let cause) = session.phase, overlay == .none {
                    DeathView(
                        cause: cause,
                        rewindCharges: session.sim.rewindCharges,
                        rewindSeconds: session.tuning.rewindSeconds,
                        onRewind: paradoxRewind,
                        onRestart: { restart() },
                        onMenu: { model.goHome() }
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

                if let hint {
                    EncounterCard(hint: hint) {
                        dismissHint()
                    }
                }

                if session.phase == .replaying {
                    VStack {
                        Spacer()
                        Text("YOUR PAST")
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
        .onAppear {
            session.configure(tuning: model.progress.playerTuning)
            scene.onEvents = { events in handle(events) }
            session.autoReplay = model.progress.autoReplayEnabled
            model.audio.setHapticsEnabled(model.progress.hapticsEnabled)
            model.audio.enabled = model.progress.soundEnabled
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
            if model.progress.consume(.ward) {
                _ = session.sim.activate(.ward)
                session.banner = "Ward"
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
