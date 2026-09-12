import Foundation
import QuartzCore

enum GamePhase: Equatable {
    case playing
    case paused
    case replaying
    case ballet(SessionResult)
    case dead(DeathCause)
    case won(SessionResult)
}

@MainActor
@Observable
final class GameSession {
    let level: LevelDefinition
    let daily: Bool
    let sim: WorldSimulation

    var phase: GamePhase = .playing
    var sparksCollected = 0
    var echoCount = 0
    var nextEchoIn: TimeInterval?
    var warning = false
    var threat: EchoThreat?
    var exitOpen = false
    var elapsed: TimeInterval = 0
    var moves = 0
    var inputTarget: Vec2?
    var replaySnapshots: [WorldSnapshot] = []
    var replayIndex = 0
    var deathCause: DeathCause?
    var autoReplay = true
    var effects = ActiveEffects()
    var inSlowField = false
    var banner: String?
    var hasStarted = false
    var balletClock: TimeInterval = 0
    var balletDuration: TimeInterval = 0
    var abilityCooldowns: [BonusKind: TimeInterval] = [:]
    var resonanceChain = 0
    var resonanceRemaining: TimeInterval = 0
    var reality: RealityMode = .normal
    var realityRemaining: TimeInterval = 0
    private(set) var tuning = PlayerTuning()

    var sparksTotal: Int { level.sparkCount }
    var maxEchoes: Int { level.maxEchoes }

    init(level: LevelDefinition, daily: Bool) {
        self.level = level
        self.daily = daily
        self.sim = WorldSimulation(level: level)
        publish()
    }

    func configure(tuning: PlayerTuning) {
        guard !hasStarted else { return }
        self.tuning = tuning
        sim.configure(tuning: tuning)
        publish()
    }

    func restart() {
        sim.reset()
        phase = .playing
        inputTarget = nil
        replaySnapshots = []
        replayIndex = 0
        deathCause = nil
        balletClock = 0
        balletDuration = 0
        abilityCooldowns = [:]
        publish()
    }

    @discardableResult
    func paradoxRewind() -> Bool {
        guard sim.rewind(seconds: tuning.rewindSeconds) else { return false }
        phase = .playing
        deathCause = nil
        replaySnapshots = []
        replayIndex = 0
        banner = "Paradox"
        publish()
        return true
    }

    func togglePause() {
        switch phase {
        case .playing: phase = .paused
        case .paused: phase = .playing
        default: break
        }
    }

    @discardableResult
    func useBonus(_ kind: BonusKind) -> Bool {
        guard phase == .playing,
              cooldownRemaining(for: kind) <= 0,
              sim.activate(kind, fromShop: true) else { return false }
        abilityCooldowns[kind] = kind.cooldown * tuning.cooldownMultiplier
        banner = kind.title
        publish()
        return true
    }

    func cooldownRemaining(for kind: BonusKind) -> TimeInterval {
        max(0, abilityCooldowns[kind] ?? 0)
    }

    func advanceCooldowns(dt: TimeInterval) {
        guard dt > 0, !abilityCooldowns.isEmpty else { return }
        for kind in Array(abilityCooldowns.keys) {
            let remaining = max(0, (abilityCooldowns[kind] ?? 0) - dt)
            if remaining <= 0 {
                abilityCooldowns.removeValue(forKey: kind)
            } else {
                abilityCooldowns[kind] = remaining
            }
        }
    }

    func handle(events: [SimEvent], autoReplay: Bool) {
        for event in events {
            switch event {
            case .sparkCollected, .dashed, .laserCharging, .laserFired:
                break
            case .resonance(let chain, _):
                banner = "Resonance ×\(chain)"
            case .timeCrystalSecured(_, let freeze):
                banner = String(format: "Freeze +%.1fs", freeze)
            case .sparkTimerExpired:
                banner = "Freeze charge expired"
            case .bonusCollected(let kind):
                banner = kind.title
            case .shieldBroke:
                banner = "Shield broke"
            case .echoWillSpawn:
                break
            case .echoSpawned:
                break
            case .exitOpened:
                exitOpen = true
            case .riftOpened:
                banner = "Rift"
            case .riftEntered(let kind):
                banner = switch kind {
                case .calm: "TIME HELD"
                case .collision: "COLLAPSING RIFT"
                case .warp: "MIRROR SHIFT"
                case .candy: "CANDY TIMELINE"
                }
            case .timeCollision:
                banner = "Time collision"
            case .died(let cause):
                deathCause = cause
                replaySnapshots = sim.snapshots
                replayIndex = 0
                if autoReplay, replaySnapshots.count > 8 {
                    phase = .replaying
                } else {
                    phase = .dead(cause)
                }
            case .won(let result):
                startBallet(result)
            }
        }
        publish()
    }

    func startBallet(_ result: SessionResult) {
        balletClock = 0
        balletDuration = min(4.0, max(2.2, result.time / 7))
        phase = .ballet(result)
    }

    func advanceBallet(dt: TimeInterval) -> Bool {
        guard case .ballet(let result) = phase else { return false }
        balletClock += dt
        if balletClock >= balletDuration {
            phase = .won(result)
            return true
        }
        return false
    }

    var balletPlaybackTime: TimeInterval {
        guard case .ballet(let result) = phase, balletDuration > 0 else { return 0 }
        return min(result.time, (balletClock / balletDuration) * result.time)
    }

    func advanceReplay(dt: TimeInterval) -> Bool {
        guard phase == .replaying else { return false }
        let frames = max(1, Int((dt * 0.45) * 60))
        replayIndex = min(replayIndex + frames, max(replaySnapshots.count - 1, 0))
        if replayIndex >= replaySnapshots.count - 1 {
            if let cause = deathCause {
                phase = .dead(cause)
            }
            return true
        }
        return false
    }

    func skipReplay() {
        if let cause = deathCause {
            phase = .dead(cause)
        }
    }

    private func publish() {
        sparksCollected = sim.sparksCollected
        echoCount = sim.echoCount
        nextEchoIn = sim.nextEchoIn
        warning = sim.isWarning
        threat = sim.nearestThreat
        exitOpen = sim.exitOpen
        elapsed = sim.time
        moves = sim.moves
        effects = sim.effects
        inSlowField = sim.inSlowField
        hasStarted = sim.hasStarted
        resonanceChain = sim.resonanceChain
        resonanceRemaining = sim.resonanceRemaining
        reality = sim.reality
        realityRemaining = sim.realityRemaining
    }
}
