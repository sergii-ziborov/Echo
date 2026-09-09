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
                    .padding(.horizontal, 14)
                    .padding(.top, 4)

                    Spacer()

                    if let banner = session.banner {
                        Text(banner.uppercased())
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .allowsHitTesting(false)
                            .padding(.bottom, 8)
                    }

                    InventoryBar(session: session) { kind in
                        useItem(kind)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)

                    NextEchoMeter(session: session)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 8)
                }
                .padding(.top, geo.safeAreaInsets.top)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 6))

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
        HStack(spacing: 10) {
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
            Spacer()
            VStack(spacing: 1) {
                Text(session.daily ? "DAILY" : "Level \(session.level.number)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
                Text(session.level.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button(action: onPause) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
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
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
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
                        VStack(spacing: 3) {
                            Image(systemName: kind.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(tint)
                            Text("\(model.progress.count(kind))")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 52, height: 48)
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

struct NextEchoMeter: View {
    var session: GameSession

    var body: some View {
        VStack(spacing: 8) {
            if let threat = session.threat, threat.willCollide {
                Text("Echo \(threat.echoIndex + 1) closing in")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(EchoTheme.danger)
            } else if session.warning {
                Text("Echo appearing")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(EchoTheme.magenta)
            } else if session.nextEchoIn == nil {
                Text("Four echoes fill the arena")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
            } else {
                Text("Next echo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
            }

            GeometryReader { geo in
                let remaining = session.nextEchoIn ?? 0
                let interval = session.level.echoInterval
                let progress = session.nextEchoIn == nil ? 1.0 : max(0, min(1, 1 - remaining / interval))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(session.warning ? EchoTheme.magenta : EchoTheme.cyan)
                        .frame(width: geo.size.width * progress)
                        .shadow(color: (session.warning ? EchoTheme.magenta : EchoTheme.cyan).opacity(0.7), radius: 10)
                }
            }
            .frame(height: 10)

            if let remaining = session.nextEchoIn {
                Text(String(format: "%.1f", remaining))
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: EchoTheme.cyan.opacity(0.6), radius: 10)
            }
            Text(session.effects.canDash ? "Double-tap to dash" : "Dash cooling down")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(EchoTheme.muted)
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.easeInOut(duration: 0.2), value: session.warning)
    }
}
