import Foundation
import WatchKit

/// One attempt at a wrist map. It steps the shared simulation, turns events
/// into wrist haptics, applies the watch-only skills and reports the clear.
@MainActor
@Observable
final class WatchRun {
    enum Phase: Equatable {
        case ready
        case playing
        case paused
        case dead(DeathCause)
        case won(time: TimeInterval, newClear: Bool)
    }

    static let freezeCooldown: TimeInterval = 18
    static let rewindSeconds = WristSkill.crownRewindSeconds

    let source: LevelDefinition
    let level: LevelDefinition
    let skills: Set<WristSkill>
    private(set) var sim: WorldSimulation
    private(set) var phase: Phase = .ready
    private(set) var collected = 0
    private(set) var echoCount = 0
    private(set) var nextEchoSecond: Int?
    private(set) var freezeReadyIn: TimeInterval = 0
    private(set) var flash = 0

    /// The held stick: the orb flies the way it points and stops when the
    /// finger lifts, like the Signal on the iPhone.
    @ObservationIgnored var stick: Vec2?
    @ObservationIgnored var onEvents: (([SimEvent]) -> Void)?
    @ObservationIgnored var onRewind: (() -> Void)?

    init(level: LevelDefinition, aspect: Double, skills: Set<WristSkill>) {
        source = level
        self.level = WristCatalog.fitted(level, aspect: aspect)
        self.skills = skills
        sim = Self.makeSimulation(self.level, skills: skills)
    }

    var rewindsLeft: Int { sim.rewindCharges }
    var canRewind: Bool { skills.contains(.crownRewind) && sim.rewindCharges > 0 }
    var canFreeze: Bool { skills.contains(.tickFreeze) && freezeReadyIn <= 0 && isLive }
    var isLive: Bool { phase == .ready || phase == .playing }

    func step(dt: TimeInterval) {
        guard isLive else { return }
#if DEBUG
        if autopilot { stick = autopilotStick() }
#endif
        if freezeReadyIn > 0 { freezeReadyIn = max(0, freezeReadyIn - dt) }
        let target = stick.flatMap { RemoteSteering.target(stick: $0, player: sim.playerPosition) }
        let events = sim.step(dt: dt, target: target)
        if phase == .ready, sim.hasStarted { phase = .playing }
        let sparks = sim.sparks.filter(\.collected).count
        if sparks != collected { collected = sparks }
        if sim.echoCount != echoCount { echoCount = sim.echoCount }
        let second = sim.nextEchoIn.map { Int($0.rounded(.up)) }
        if second != nextEchoSecond { nextEchoSecond = second }
        guard !events.isEmpty else { return }
        for event in events { react(to: event) }
        onEvents?(events)
    }

    func togglePause() {
        switch phase {
        case .playing: phase = .paused
        case .paused: phase = .playing
        default: break
        }
    }

    @discardableResult
    func rewind() -> Bool {
        guard canRewind, sim.rewind(seconds: Self.rewindSeconds) else { return false }
        phase = sim.hasStarted ? .playing : .ready
        stick = nil
        collected = sim.sparks.filter(\.collected).count
        echoCount = sim.echoCount
        flash += 1
        WKInterfaceDevice.current().play(.retry)
        onRewind?()
        return true
    }

    @discardableResult
    func dash() -> Bool {
        guard skills.contains(.wristDash), phase == .playing, sim.tryDash() else { return false }
        WKInterfaceDevice.current().play(.directionUp)
        onEvents?([.dashed])
        return true
    }

    @discardableResult
    func freeze() -> Bool {
        guard canFreeze, sim.activate(.freeze) else { return false }
        freezeReadyIn = Self.freezeCooldown
        WKInterfaceDevice.current().play(.click)
        onEvents?([.bonusCollected(kind: .freeze)])
        return true
    }

    func restart() {
        sim = Self.makeSimulation(level, skills: skills)
        phase = .ready
        stick = nil
        collected = 0
        echoCount = 0
        nextEchoSecond = nil
        freezeReadyIn = 0
        flash += 1
    }

    private func react(to event: SimEvent) {
        let device = WKInterfaceDevice.current()
        switch event {
        case .sparkCollected, .timeCrystalSecured:
            device.play(.click)
        case .bonusCollected:
            device.play(.directionUp)
        case .echoWillSpawn:
            if skills.contains(.pulseSense) { device.play(.notification) }
        case .echoSpawned:
            device.play(.directionDown)
        case .exitOpened:
            device.play(.start)
        case .asteroidShattered, .shieldBroke:
            device.play(.click)
        case .died(let cause):
            phase = .dead(cause)
            device.play(.failure)
        case .won(let result):
            let fresh = WatchStore.shared.record(source, time: result.time)
            phase = .won(time: result.time, newClear: fresh)
            device.play(.success)
        default:
            break
        }
    }

#if DEBUG
    @ObservationIgnored private let autopilot = ProcessInfo.processInfo.arguments.contains("-wrist-autopilot")

    /// Review aid: steer to the nearest spark, then to the exit.
    private func autopilotStick() -> Vec2? {
        let open = sim.sparks.filter { !$0.collected }
        let here = sim.playerPosition
        let goal = open.min { $0.position.distance(to: here) < $1.position.distance(to: here) }?.position ?? level.exit
        let way = goal - here
        return way.length > 1 ? way / way.length : nil
    }
#endif

    private static func makeSimulation(_ level: LevelDefinition, skills: Set<WristSkill>) -> WorldSimulation {
        let sim = WorldSimulation(level: level)
        var tuning = PlayerTuning()
        tuning.rewindSeconds = rewindSeconds
        tuning.rewindCharges = skills.contains(.crownRewind) ? 2 : 0
        sim.configure(tuning: tuning)
        return sim
    }
}
