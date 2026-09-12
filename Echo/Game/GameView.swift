import SpriteKit
import SwiftUI
import UIKit

struct GameView: View {
    @Environment(AppModel.self) private var model
    let request: PlayRequest

    @State private var session: GameSession
    @State private var scene: GameScene
    @State private var overlay: InRunOverlay = .none
    @State private var hint: EncounterHint?
    @Environment(\.scenePhase) private var scenePhase

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
                .padding(.top, (geo.safeAreaInsets.top > 20 ? geo.safeAreaInsets.top : 62) + 4)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 10))

                if case .paused = session.phase, overlay == .none {
                    PauseView(
                        levelName: session.level.name,
                        rewindCharges: session.sim.rewindCharges,
                        onResume: { session.togglePause() },
                        onRestart: restart,
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
                        onWatch: { session.startBallet(result) },
                        onNext: nextLevel,
                        onMenu: { model.goHome() }
                    )
                }

                if case .dead(let cause) = session.phase, overlay == .none {
                    DeathView(
                        cause: cause,
                        rewindCharges: session.sim.rewindCharges,
                        rewindSeconds: session.tuning.rewindSeconds,
                        onRewind: paradoxRewind,
                        onRestart: restart,
                        onMenu: { model.goHome() }
                    )
                }

                if overlay == .shop {
                    ShopView(onBack: { overlay = .none })
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

    private var resultKey: String {
        session.level.id
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
            case .resonance(let chain, _):
                model.audio.haptic(chain >= 4 ? .rigid : .soft)
                scene.resonanceEffect(chain: chain, at: session.sim.playerPosition)
                if chain == 2 { offerHint(.resonance) }
            case .timeCrystalSecured:
                model.audio.haptic(.medium)
                scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
            case .sparkTimerExpired(let id):
                model.audio.haptic(.soft)
                if let spark = session.sim.sparks.first(where: { $0.id == id }) {
                    scene.timerPop(at: spark.position)
                }
            case .bonusCollected(let kind):
                model.audio.play(.collect)
                model.audio.haptic(.medium)
                scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
                if kind == .freeze { offerHint(.freeze) }
                if kind == .phase { offerHint(.phase) }
            case .shieldBroke:
                model.audio.haptic(.rigid)
                scene.burst(at: session.sim.playerPosition, color: UIColor(red: 0.4, green: 1, blue: 0.65, alpha: 1))
            case .dashed:
                break
            case .laserCharging:
                model.audio.play(.warn)
                model.audio.haptic(.soft)
            case .laserFired(let id):
                model.audio.haptic(.rigid)
                scene.laserDischarge(id: id)
            case .echoWillSpawn:
                model.audio.play(.warn)
                model.audio.haptic(.medium)
            case .echoSpawned:
                model.audio.play(.spawn)
                model.audio.haptic(.rigid)
                scene.burst(at: session.level.playerStart, color: UIColor(red: 0.75, green: 0.4, blue: 1, alpha: 1))
                offerHint(.echo)
            case .exitOpened:
                model.audio.haptic(.soft)
            case .riftOpened:
                model.audio.haptic(.soft)
                offerHint(.rift)
            case .riftEntered(let kind):
                model.audio.play(.collect)
                if kind == .calm {
                    scene.abilityEffect(kind: .freeze, at: session.sim.playerPosition)
                } else if kind == .warp || kind == .candy {
                    scene.realityShift(kind: kind, at: session.sim.playerPosition)
                    offerHint(.realityShift)
                }
            case .timeCollision(let at):
                model.audio.haptic(.rigid)
                scene.burst(at: at, color: UIColor(red: 0.9, green: 0.4, blue: 1, alpha: 1))
                offerHint(.collision)
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
        overlay = .none
        session.restart()
        scene.rebuild()
    }

    private func paradoxRewind() {
        model.audio.play(.tap)
        overlay = .none
        if session.paradoxRewind() {
            scene.rebuild()
        } else {
            restart()
        }
    }

    private func useItem(_ kind: BonusKind) {
        guard session.phase == .playing else { return }
        guard session.cooldownRemaining(for: kind) <= 0 else {
            session.banner = String(format: "Recharging %.1fs", session.cooldownRemaining(for: kind))
            model.audio.play(.tap)
            return
        }
        guard model.progress.consume(kind) else { return }
        if session.useBonus(kind) {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            scene.abilityEffect(kind: kind, at: session.sim.playerPosition)
            if kind == .freeze { offerHint(.freeze) }
            if kind == .phase { offerHint(.phase) }
        } else {
            model.progress.refund(kind)
        }
    }

    private func offerHint(_ value: EncounterHint) {
        guard hint == nil, model.progress.markHint(value.rawValue) else { return }
        hint = value
        if session.phase == .playing {
            session.togglePause()
        }
    }

    private func dismissHint() {
        hint = nil
        if session.phase == .paused {
            session.togglePause()
        }
    }

    private func nextLevel() {
        model.audio.play(.tap)
        if request.daily {
            model.goHome()
            return
        }
        if session.level.number == LevelCatalog.playable.count,
           model.progress.advanceDifficultyIfComplete() {
            model.play(level: LevelCatalog.prototype, daily: false)
            return
        }
        if let next = LevelCatalog.level(number: session.level.number + 1), model.progress.isUnlocked(next) {
            model.play(level: next, daily: false)
        } else {
            model.goHome()
        }
    }
}

private struct EncounterCard: View {
    var hint: EncounterHint
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("FIRST CONTACT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(EchoTheme.muted)
                Text(hint.title)
                    .font(.system(size: 26, weight: .ultraLight))
                    .tracking(1)
                Text(hint.detail)
                    .font(.system(size: 15))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Got it", systemImage: "checkmark", action: onDismiss)
            }
            .padding(26)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }
}

private enum InRunOverlay {
    case none
    case shop
    case settings
}

struct HUDBar: View {
    var session: GameSession
    var onPause: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                HUDChip(icon: "sparkle", tint: EchoTheme.cyan) {
                    Text("\(session.sparksCollected)/\(session.sparksTotal)")
                }
                .accessibilityLabel("Sparks \(session.sparksCollected) of \(session.sparksTotal)")

                HUDChip(icon: "circle.dotted", tint: EchoTheme.magenta) {
                    Text("\(session.echoCount)/\(session.maxEchoes)")
                }
                .accessibilityLabel("Echoes \(session.echoCount) of \(session.maxEchoes)")

                HUDChip(icon: "clock.arrow.circlepath", tint: EchoTheme.cyan) {
                    Text("\(session.sim.rewindCharges)")
                }
                .accessibilityLabel("\(session.sim.rewindCharges) rewind charges")

                Spacer(minLength: 4)

                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pause")
            }

            if hasActiveStatus {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        Text("STATUS")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.44))
                            .padding(.leading, 3)

                        if session.effects.shieldCharges > 0 {
                            HUDEffectBadge(
                                icon: "shield.fill",
                                value: "×\(session.effects.shieldCharges)",
                                tint: .green,
                                accessibilityText: "Shield, \(session.effects.shieldCharges) charges"
                            )
                        }
                        if session.effects.isFrozen {
                            HUDEffectBadge(
                                icon: "snowflake",
                                value: seconds(session.effects.freezeRemaining),
                                tint: EchoTheme.cyan,
                                accessibilityText: "Freeze, \(seconds(session.effects.freezeRemaining)) remaining"
                            )
                        }
                        if session.effects.isSurging {
                            HUDEffectBadge(
                                icon: "bolt.fill",
                                value: seconds(session.effects.surgeRemaining),
                                tint: EchoTheme.gold,
                                accessibilityText: "Surge, \(seconds(session.effects.surgeRemaining)) remaining"
                            )
                        }
                        if session.effects.isMagnet {
                            HUDEffectBadge(
                                icon: "magnet.fill",
                                value: seconds(session.effects.magnetRemaining),
                                tint: EchoTheme.magenta,
                                accessibilityText: "Magnet, \(seconds(session.effects.magnetRemaining)) remaining"
                            )
                        }
                        if session.effects.isPhasing {
                            HUDEffectBadge(
                                icon: "sparkles",
                                value: seconds(session.effects.phaseRemaining),
                                tint: .white,
                                accessibilityText: "Phase, \(seconds(session.effects.phaseRemaining)) remaining"
                            )
                        }
                        if session.resonanceChain >= 2 {
                            HUDEffectBadge(
                                icon: "link",
                                value: "×\(session.resonanceChain)",
                                tint: EchoTheme.gold,
                                progress: max(0, min(1, session.resonanceRemaining / 3.25)),
                                accessibilityText: "Resonance chain \(session.resonanceChain)"
                            )
                        }
                        if session.reality != .normal {
                            HUDEffectBadge(
                                icon: session.reality == .candy ? "birthday.cake.fill" : "arrow.left.and.right.righttriangle.left.righttriangle.right.fill",
                                value: seconds(session.realityRemaining),
                                tint: session.reality == .candy ? EchoTheme.magenta : EchoTheme.cyan,
                                accessibilityText: "\(session.reality.rawValue) reality, \(seconds(session.realityRemaining)) remaining"
                            )
                        }
                    }
                    .padding(5)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    )
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.18), value: hasActiveStatus)
    }

    private var hasActiveStatus: Bool {
        session.effects.shieldCharges > 0
            || session.effects.isFrozen
            || session.effects.isSurging
            || session.effects.isMagnet
            || session.effects.isPhasing
            || session.resonanceChain >= 2
            || session.reality != .normal
    }

    private func seconds(_ value: TimeInterval) -> String {
        "\(max(1, Int(ceil(value))))s"
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
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct HUDEffectBadge: View {
    let icon: String
    let value: String
    let tint: Color
    var progress: Double? = nil
    let accessibilityText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 7)
        .frame(height: 26)
        .background(tint.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
        .overlay(alignment: .bottomLeading) {
            if let progress {
                GeometryReader { geometry in
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * progress, height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .padding(.horizontal, 4)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(accessibilityText)
    }
}

struct InventoryBar: View {
    @Environment(AppModel.self) private var model
    var session: GameSession
    var onUse: (BonusKind) -> Void

    var body: some View {
        let equipped = model.progress.equippedSkills
        if session.phase == .playing || session.phase == .paused {
            HStack(spacing: 8) {
                ForEach(0..<model.progress.skillSlotCount, id: \.self) { index in
                    if equipped.indices.contains(index) {
                        let kind = equipped[index]
                        let tint = Color(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b)
                        let cooldown = session.cooldownRemaining(for: kind)
                        let stock = model.progress.count(kind)
                        Button {
                            onUse(kind)
                        } label: {
                            ZStack {
                                VStack(spacing: 1) {
                                    Image(kind.assetName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                    Text("×\(stock)")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundStyle(stock > 0 ? .white : EchoTheme.muted)
                                }
                                if cooldown > 0 {
                                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                                        .fill(Color.black.opacity(0.58))
                                    Text(String(format: "%.1f", cooldown))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(tint.opacity(stock > 0 ? 0.55 : 0.20), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(session.phase != .playing || stock == 0 || cooldown > 0)
                        .accessibilityLabel("Use \(kind.title), \(stock) owned")
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(EchoTheme.muted.opacity(0.65))
                            .frame(width: 46, height: 46)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            )
                    }
                }
                Spacer()
            }
        }
    }
}
