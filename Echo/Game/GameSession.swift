import Foundation
import QuartzCore

enum GamePhase: Equatable {
    case playing
    case paused
    case replaying
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

    var sparksTotal: Int { level.sparkCount }
    var maxEchoes: Int { level.maxEchoes }

    init(level: LevelDefinition, daily: Bool) {
        self.level = level
        self.daily = daily
        self.sim = WorldSimulation(level: level)
        publish()
    }

    func restart() {
        sim.reset()
        phase = .playing
        inputTarget = nil
        replaySnapshots = []
        replayIndex = 0
        deathCause = nil
        publish()
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
        guard phase == .playing, sim.activate(kind) else { return false }
        banner = kind.title
        publish()
        return true
    }

    func handle(events: [SimEvent], autoReplay: Bool) {
        for event in events {
            switch event {
            case .sparkCollected, .sparkTimerExpired, .dashed:
                break
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
                banner = kind == .calm ? "Time skip" : "Rift"
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
                phase = .won(result)
            }
        }
        publish()
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
    }
}
