import SpriteKit
import SwiftUI
import UIKit

struct GameView: View {
    @Environment(AppModel.self) private var model
    let request: PlayRequest

    @State private var session: GameSession
    @State private var scene: GameScene

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
        let level = raw.fitted(aspect: aspect)
        let session = GameSession(level: level, daily: request.daily)
        _session = State(initialValue: session)
        _scene = State(initialValue: GameScene(session: session, size: bounds))
    }

    var body: some View {
        GeometryReader { geo in
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
                .padding(.top, (geo.safeAreaInsets.top > 20 ? geo.safeAreaInsets.top : 62) + 4)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))

                if case .paused = session.phase {
                    PauseView(
                        levelName: session.level.name,
                        onResume: { session.togglePause() },
                        onRestart: restart,
                        onSettings: { model.openSettings() },
                        onMenu: { model.goHome() }
                    )
                }

                if case .won(let result) = session.phase {
                    ResultsView(
                        levelName: session.level.name,
                        result: result,
                        bestTime: model.progress.progress(for: resultKey).bestTime,
                        bestMoves: model.progress.progress(for: resultKey).bestMoves,
                        onReplay: restart,
                        onNext: nextLevel,
                        onMenu: { model.goHome() }
                    )
                }

                if case .dead(let cause) = session.phase {
                    DeathView(
                        cause: cause,
                        onRestart: restart,
                        onMenu: { model.goHome() }
                    )
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
            scene.onEvents = { events in handle(events) }
            session.autoReplay = model.progress.autoReplayEnabled
            model.audio.setHapticsEnabled(model.progress.hapticsEnabled)
            model.audio.enabled = model.progress.soundEnabled
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

    private var resultKey: String {
        request.daily ? "daily" : session.level.id
    }

    private func handle(_ events: [SimEvent]) {
        for event in events {
            switch event {
            case .sparkCollected(let id, _):
                model.audio.play(.collect)
                model.audio.haptic(.light)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    scene.burst(at: spark.position, color: UIColor(red: 0.5, green: 0.95, blue: 1, alpha: 1))
                }
            case .sparkTimerExpired(let id):
                model.audio.haptic(.soft)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    scene.timerPop(at: spark.position)
                }
            case .bonusCollected(let kind):
                model.audio.play(.collect)
                model.audio.haptic(.medium)
                scene.burst(at: session.sim.playerPosition, color: UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1))
                _ = kind
            case .shieldBroke:
                model.audio.haptic(.rigid)
                scene.burst(at: session.sim.playerPosition, color: UIColor(red: 0.4, green: 1, blue: 0.65, alpha: 1))
            case .dashed:
                break
            case .echoWillSpawn:
                model.audio.play(.warn)
                model.audio.haptic(.medium)
            case .echoSpawned:
                model.audio.play(.spawn)
                model.audio.haptic(.rigid)
                scene.burst(at: session.level.playerStart, color: UIColor(red: 0.75, green: 0.4, blue: 1, alpha: 1))
            case .exitOpened:
                model.audio.haptic(.soft)
            case .died:
                model.audio.play(.death)
                model.audio.notify(.error)
            case .won(let result):
                model.recordWin(levelID: session.level.id, result: result, daily: request.daily)
                model.audio.notify(.success)
            }
        }
    }

    private func restart() {
        model.audio.play(.tap)
        session.restart()
        scene.rebuild()
    }

    private func useItem(_ kind: BonusKind) {
        guard session.phase == .playing else { return }
        guard model.progress.consume(kind) else { return }
        if session.useBonus(kind) {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            scene.burst(at: session.sim.playerPosition, color: UIColor(red: 1, green: 0.85, blue: 0.4, alpha: 1))
        } else {
            model.progress.refund(kind)
        }
    }

    private func nextLevel() {
        model.audio.play(.tap)
        if request.daily {
            model.goHome()
            return
        }
        if let next = LevelCatalog.level(number: session.level.number + 1), model.progress.isUnlocked(next) {
            model.play(level: next, daily: false)
        } else {
            model.goHome()
        }
    }
}

struct HUDBar: View {
    var session: GameSession
    var onPause: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            HUDChip(icon: "sparkle", tint: EchoTheme.cyan) {
                Text("\(session.sparksCollected)/\(session.sparksTotal)")
            }
            HUDChip(icon: "circle.dotted", tint: EchoTheme.magenta) {
                Text("\(session.echoCount)/\(session.maxEchoes)")
            }
            if session.effects.shieldCharges > 0 {
                HUDChip(icon: "shield.fill", tint: Color.green) {
                    Text("\(session.effects.shieldCharges)")
                }
            }
            if session.effects.isFrozen {
                HUDChip(icon: "snowflake", tint: EchoTheme.cyan) {
                    Text(String(format: "%.0f", session.effects.freezeRemaining))
                }
            }
            if session.effects.isSurging {
                HUDChip(icon: "bolt.fill", tint: EchoTheme.gold) {
                    Text(String(format: "%.0f", session.effects.surgeRemaining))
                }
            }
            if session.effects.isMagnet {
                HUDChip(icon: "magnet", tint: EchoTheme.magenta) {
                    Text(String(format: "%.0f", session.effects.magnetRemaining))
                }
            }
            Spacer(minLength: 8)
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause")
        }
    }
}

struct HUDChip<Content: View>: View {
    var icon: String
    var tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            content
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
    }
}

struct InventoryBar: View {
    @Environment(AppModel.self) private var model
    var session: GameSession
    var onUse: (BonusKind) -> Void

    var body: some View {
        let owned = BonusKind.allCases.filter { model.progress.count($0) > 0 }
        if !owned.isEmpty, session.phase == .playing || session.phase == .paused {
            HStack(spacing: 8) {
                ForEach(owned, id: \.self) { kind in
                    let tint = Color(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b)
                    Button {
                        onUse(kind)
                    } label: {
                        VStack(spacing: 2) {
                            Image(kind.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                            Text("\(model.progress.count(kind))")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 46, height: 44)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(tint.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(session.phase != .playing)
                    .accessibilityLabel("Use \(kind.title), \(model.progress.count(kind)) owned")
                }
                Spacer()
            }
        }
    }
}


