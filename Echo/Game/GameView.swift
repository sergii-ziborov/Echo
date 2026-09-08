import SpriteKit
import SwiftUI

struct GameView: View {
    @Environment(AppModel.self) private var model
    let request: PlayRequest

    @State private var session: GameSession
    @State private var scene: GameScene

    init(request: PlayRequest) {
        self.request = request
        let level: LevelDefinition
        if request.daily {
            level = LevelCatalog.daily()
        } else {
            level = LevelCatalog.level(id: request.levelID) ?? LevelCatalog.prototype
        }
        let session = GameSession(level: level, daily: request.daily)
        _session = State(initialValue: session)
        _scene = State(initialValue: GameScene(session: session, size: CGSize(width: 1000, height: 1000)))
    }

    var body: some View {
        GeometryReader { geo in
            let top = geo.safeAreaInsets.top + 8
            let bottom = max(geo.safeAreaInsets.bottom, 12) + 72
            let side = min(geo.size.width - 16, geo.size.height - top - bottom)
            ZStack {
                LinearGradient.screenBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    HUDBar(session: session) {
                        session.togglePause()
                        model.audio.play(.tap)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 6)

                    Spacer(minLength: 8)

                    SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                        .frame(width: side, height: side)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: EchoTheme.cyan.opacity(0.12), radius: 24)

                    Spacer(minLength: 8)

                    NextEchoMeter(session: session)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 10)
                }

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
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(EchoTheme.magenta)
                            .padding(.bottom, 110)
                    }
                    .allowsHitTesting(false)
                }
            }
        }
        .onAppear {
            scene.onEvents = { events in
                handle(events)
            }
            session.autoReplay = model.progress.autoReplayEnabled
            model.audio.setHapticsEnabled(model.progress.hapticsEnabled)
            model.audio.enabled = model.progress.soundEnabled
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
                    scene.burst(at: spark.position, color: UIColor(red: 0.5, green: 0.9, blue: 1, alpha: 1))
                }
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
            HUDChip(icon: "circle.hexagongrid.fill", tint: EchoTheme.cyan) {
                Text("\(session.sparksCollected)/\(session.sparksTotal)")
            }
            HUDChip(icon: "circle.dotted", tint: EchoTheme.magenta) {
                Text("\(session.echoCount)/\(session.maxEchoes)")
            }
            Spacer()
            VStack(spacing: 2) {
                Text(session.daily ? "DAILY" : "Level \(session.level.number)")
                    .font(.system(size: 12, weight: .medium))
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
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pause")
        }
        .padding(.top, 4)
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
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
    }
}

struct NextEchoMeter: View {
    var session: GameSession

    var body: some View {
        VStack(spacing: 8) {
            if let threat = session.threat, threat.willCollide {
                Text("Echo \(threat.echoIndex + 1) closing in")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EchoTheme.danger)
                    .transition(.opacity)
            } else if session.warning {
                Text("Echo appearing at your origin")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(EchoTheme.magenta)
            } else if session.nextEchoIn == nil {
                Text("Four echoes fill the arena")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
            } else {
                Text("Next echo")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(EchoTheme.muted)
            }

            GeometryReader { geo in
                let remaining = session.nextEchoIn ?? 0
                let interval = session.level.echoInterval
                let progress = session.nextEchoIn == nil ? 1.0 : max(0, min(1, 1 - remaining / interval))
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(session.warning ? EchoTheme.magenta : EchoTheme.cyan)
                        .frame(width: geo.size.width * progress)
                        .shadow(color: (session.warning ? EchoTheme.magenta : EchoTheme.cyan).opacity(0.6), radius: 8)
                }
            }
            .frame(height: 8)

            if let remaining = session.nextEchoIn {
                Text(String(format: "%.1fs", remaining))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.warning)
    }
}
