import Foundation

struct SimConfig: Equatable, Sendable {
    var playerRadius: Double = 24
    var echoRadius: Double = 24
    var sparkRadius: Double = 22
    var bonusRadius: Double = 26
    var exitRadius: Double = 44
    var moveQuantum: Double = 24
    var inputDeadzone: Double = 18
    var collisionSlop: Double = 2.0
    var lookAhead: TimeInterval = 0.75
    var snapshotWindow: TimeInterval = 3.0
    var snapshotHz: Double = 60
    var edgeInset: Double = 28
    var dashDuration: TimeInterval = 1.15
    var dashCooldown: TimeInterval = 2.6
    var dashSpeed: Double = 1.55
    var magnetRadius: Double = 160
}

enum SimPhase: Equatable, Sendable {
    case playing
    case dead
    case won
}

enum SimEvent: Equatable, Sendable {
    case sparkCollected(id: Int, remaining: Int)
    case sparkTimerExpired(id: Int)
    case bonusCollected(kind: BonusKind)
    case shieldBroke
    case dashed
    case echoWillSpawn(index: Int, in: TimeInterval)
    case echoSpawned(index: Int)
    case exitOpened
    case died(DeathCause)
    case won(SessionResult)
}

struct SparkState: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var collected: Bool
    var timerDuration: TimeInterval?
    var timerRemaining: TimeInterval?
    var timedOut: Bool
    var orbit: SparkOrbit?
}

final class WorldSimulation {
    let level: LevelDefinition
    let config: SimConfig

    private(set) var phase: SimPhase = .playing
    private(set) var time: TimeInterval = 0
    private(set) var playbackTime: TimeInterval = 0
    private(set) var playerPosition: Vec2
    private(set) var lastVelocity: Vec2 = .zero
    private(set) var echoes: [Vec2] = []
    private(set) var sparks: [SparkState]
    private(set) var bonuses: [BonusState]
    private(set) var effects = ActiveEffects()
    private(set) var exitOpen = false
    private(set) var moves = 0
    private(set) var bonusesCollected = 0
    private(set) var recorder = PathRecorder()
    private(set) var snapshots: [WorldSnapshot] = []
    private(set) var nearestThreat: EchoThreat?
    private(set) var deathCause: DeathCause?
    private(set) var result: SessionResult?
    private(set) var inSlowField = false

    var echoCount: Int { echoes.count }
    var sparksCollected: Int { sparks.filter(\.collected).count }
    var sparksRemaining: Int { sparks.count - sparksCollected }
    var nextEchoIndex: Int { echoCount }
    var maxEchoes: Int { level.maxEchoes }

    var nextEchoAt: TimeInterval? {
        guard echoCount < level.maxEchoes else { return nil }
        return Double(echoCount + 1) * level.echoInterval
    }

    var nextEchoIn: TimeInterval? {
        guard let at = nextEchoAt else { return nil }
        return max(0, at - playbackTime)
    }

    var isWarning: Bool {
        guard let remaining = nextEchoIn else { return false }
        return remaining <= level.warningLead
    }

    var currentSpeed: Double {
        var speed = level.playerSpeed
        if effects.isSurging { speed *= config.dashSpeed }
        if inSlowField { speed *= 0.52 }
        return speed
    }

    private var distanceAcc = 0.0
    private var warnedFor = -1
    private var snapshotAcc = 0.0
    private var pulseDelay: TimeInterval = 0

    init(level: LevelDefinition, config: SimConfig = SimConfig()) {
        self.level = level
        self.config = config
        self.playerPosition = level.playerStart
        self.sparks = Self.makeSparks(level.sparks)
        self.bonuses = Self.makeBonuses(level.bonuses)
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    func reset() {
        phase = .playing
        time = 0
        playbackTime = 0
        playerPosition = level.playerStart
        lastVelocity = .zero
        echoes = []
        sparks = Self.makeSparks(level.sparks)
        bonuses = Self.makeBonuses(level.bonuses)
        effects = ActiveEffects()
        exitOpen = false
        moves = 0
        bonusesCollected = 0
        recorder = PathRecorder()
        snapshots = []
        nearestThreat = nil
        deathCause = nil
        result = nil
        inSlowField = false
        distanceAcc = 0
        warnedFor = -1
        snapshotAcc = 0
        pulseDelay = 0
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    @discardableResult
    func tryDash() -> Bool {
        guard phase == .playing, effects.canDash else { return false }
        effects.surgeRemaining = max(effects.surgeRemaining, config.dashDuration)
        effects.dashCooldown = config.dashCooldown
        return true
    }

    @discardableResult
    func activate(_ kind: BonusKind) -> Bool {
        guard phase == .playing else { return false }
        apply(kind)
        return true
    }

    @discardableResult
    func step(dt rawDt: TimeInterval, target: Vec2?) -> [SimEvent] {
        guard phase == .playing else { return [] }
        let dt = min(max(rawDt, 0), 1.0 / 20.0)
        guard dt > 0 else { return [] }

        time += dt
        tickEffects(dt: dt)
        let echoScale: TimeInterval = effects.isFrozen ? 0 : 1
        playbackTime += dt * echoScale
        var events: [SimEvent] = []
        events.append(contentsOf: tickTimers(dt: dt))
        updateOrbits()

        movePlayer(dt: dt, target: target)
        recorder.record(time: time, position: playerPosition)
        applyMagnet(dt: dt)

        events.append(contentsOf: spawnEchoesIfNeeded())
        refreshEchoPositions()
        events.append(contentsOf: collectSparks())
        events.append(contentsOf: collectBonuses())
        refreshThreats()

        if effects.iFrames <= 0, let death = collideEchoes() {
            if effects.shieldCharges > 0 {
                effects.shieldCharges -= 1
                effects.iFrames = 0.55
                events.append(.shieldBroke)
            } else {
                phase = .dead
                deathCause = death
                events.append(.died(death))
                captureSnapshot()
                return events
            }
        }

        if exitOpen, playerPosition.distance(to: level.exit) < config.playerRadius + config.exitRadius {
            var stars = StarRating.stars(
                time: time,
                moves: moves,
                parTime: level.parTime,
                parMoves: level.parMoves
            )
            if !bonuses.isEmpty, bonusesCollected == bonuses.count {
                stars = min(3, stars + 1)
            }
            let session = SessionResult(
                time: time,
                moves: moves,
                stars: stars,
                sparks: sparks.count,
                echoesFaced: echoCount,
                bonuses: bonusesCollected
            )
            phase = .won
            result = session
            events.append(.won(session))
        }

        snapshotAcc += dt
        let snapshotDt = 1.0 / config.snapshotHz
        if snapshotAcc >= snapshotDt {
            snapshotAcc = 0
            captureSnapshot()
        }

        return events
    }

    func predictedPath(forEcho index: Int, duration: TimeInterval = 0.8) -> [Vec2] {
        let delay = Double(index + 1) * level.echoInterval
        return recorder.polyline(from: max(0, playbackTime - delay), duration: duration)
    }

    // MARK: - Internals

    private func tickEffects(dt: TimeInterval) {
        if effects.freezeRemaining > 0 { effects.freezeRemaining = max(0, effects.freezeRemaining - dt) }
        if effects.surgeRemaining > 0 { effects.surgeRemaining = max(0, effects.surgeRemaining - dt) }
        if effects.magnetRemaining > 0 { effects.magnetRemaining = max(0, effects.magnetRemaining - dt) }
        if effects.dashCooldown > 0 { effects.dashCooldown = max(0, effects.dashCooldown - dt) }
        if effects.iFrames > 0 { effects.iFrames = max(0, effects.iFrames - dt) }
        inSlowField = level.fields.contains { $0.area.contains(playerPosition) }
    }

    private func movePlayer(dt: TimeInterval, target: Vec2?) {
        var velocity = Vec2.zero
        if let target {
            let delta = target - playerPosition
            let dist = delta.length
            if dist > config.inputDeadzone {
                let stepLen = min(currentSpeed * dt, dist)
                playerPosition = playerPosition + delta.normalized() * stepLen
                velocity = delta.normalized() * (stepLen / max(dt, 0.0001))
            }
        }
        lastVelocity = velocity
        playerPosition = clampToArena(playerPosition, radius: config.playerRadius)
        playerPosition = resolveWalls(playerPosition, radius: config.playerRadius)

        if velocity.length > 1 {
            distanceAcc += velocity.length * dt
            while distanceAcc >= config.moveQuantum {
                moves += 1
                distanceAcc -= config.moveQuantum
            }
        }
    }

    private func spawnEchoesIfNeeded() -> [SimEvent] {
        var events: [SimEvent] = []
        let clock = max(0, playbackTime - pulseDelay)
        let desired = min(level.maxEchoes, Int(clock / level.echoInterval))

        if desired > echoCount {
            let previous = echoCount
            echoes = Array(repeating: level.playerStart, count: desired)
            for i in previous..<desired {
                events.append(.echoSpawned(index: i))
            }
        }

        if echoCount < level.maxEchoes {
            let remaining = (Double(echoCount + 1) * level.echoInterval) - clock
            if remaining <= level.warningLead, remaining > 0, warnedFor != echoCount {
                warnedFor = echoCount
                events.append(.echoWillSpawn(index: echoCount, in: remaining))
            }
        }
        return events
    }

    private func refreshEchoPositions() {
        guard echoCount > 0 else { return }
        for i in 0..<echoCount {
            let delay = Double(i + 1) * level.echoInterval
            echoes[i] = recorder.position(at: max(0, playbackTime - delay)) ?? level.playerStart
        }
    }

    private static func makeSparks(_ spawns: [SparkSpawn]) -> [SparkState] {
        spawns.map {
            SparkState(
                id: $0.id,
                position: $0.position,
                collected: false,
                timerDuration: $0.timer,
                timerRemaining: $0.timer,
                timedOut: false,
                orbit: $0.orbit
            )
        }
    }

    private static func makeBonuses(_ spawns: [BonusSpawn]) -> [BonusState] {
        spawns.map { BonusState(id: $0.id, kind: $0.kind, position: $0.position, collected: false) }
    }

    private func updateOrbits() {
        for i in sparks.indices where !sparks[i].collected {
            guard let orbit = sparks[i].orbit, orbit.period > 0 else { continue }
            let angle = orbit.phase + (time / orbit.period) * (.pi * 2)
            sparks[i].position = Vec2(
                x: orbit.center.x + cos(angle) * orbit.radius,
                y: orbit.center.y + sin(angle) * orbit.radius
            )
        }
    }

    private func applyMagnet(dt: TimeInterval) {
        guard effects.isMagnet else { return }
        for i in sparks.indices where !sparks[i].collected {
            let delta = playerPosition - sparks[i].position
            let dist = delta.length
            if dist < config.magnetRadius, dist > 1 {
                sparks[i].position = sparks[i].position + delta.normalized() * min(280 * dt, dist)
            }
        }
    }

    private func tickTimers(dt: TimeInterval) -> [SimEvent] {
        var events: [SimEvent] = []
        for i in sparks.indices where !sparks[i].collected {
            guard let remaining = sparks[i].timerRemaining else { continue }
            let next = remaining - dt
            if next <= 0, !sparks[i].timedOut {
                sparks[i].timerRemaining = 0
                sparks[i].timedOut = true
                events.append(.sparkTimerExpired(id: sparks[i].id))
            } else if next > 0 {
                sparks[i].timerRemaining = next
            }
        }
        return events
    }

    private func collectSparks() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in sparks.indices where !sparks[i].collected {
            if playerPosition.distance(to: sparks[i].position) < config.playerRadius + config.sparkRadius {
                sparks[i].collected = true
                let remaining = sparksRemaining
                events.append(.sparkCollected(id: sparks[i].id, remaining: remaining))
                if remaining == 0, !exitOpen {
                    exitOpen = true
                    events.append(.exitOpened)
                }
            }
        }
        return events
    }

    private func collectBonuses() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in bonuses.indices where !bonuses[i].collected {
            if playerPosition.distance(to: bonuses[i].position) < config.playerRadius + config.bonusRadius {
                bonuses[i].collected = true
                bonusesCollected += 1
                apply(bonuses[i].kind)
                events.append(.bonusCollected(kind: bonuses[i].kind))
            }
        }
        return events
    }

    private func apply(_ kind: BonusKind) {
        switch kind {
        case .shield:
            effects.shieldCharges += 1
        case .freeze:
            effects.freezeRemaining += kind.duration
        case .surge:
            effects.surgeRemaining += kind.duration
        case .pulse:
            pulseDelay += 2.4
        case .magnet:
            effects.magnetRemaining += kind.duration
        }
    }

    private func collideEchoes() -> DeathCause? {
        for (index, echo) in echoes.enumerated() {
            let limit = config.playerRadius + config.echoRadius - config.collisionSlop
            if playerPosition.distance(to: echo) < limit {
                return .echo(index: index, delay: Double(index + 1) * level.echoInterval)
            }
        }
        return nil
    }

    private func refreshThreats() {
        var best: EchoThreat?
        for (index, echo) in echoes.enumerated() {
            let dist = playerPosition.distance(to: echo)
            let delay = Double(index + 1) * level.echoInterval
            let futureEcho = recorder.position(at: max(0, playbackTime - delay + config.lookAhead)) ?? echo
            let futurePlayer: Vec2
            if lastVelocity.length > 1 {
                futurePlayer = playerPosition + lastVelocity * config.lookAhead
            } else {
                futurePlayer = playerPosition
            }
            let futureDist = futurePlayer.distance(to: futureEcho)
            let collide = futureDist < (config.playerRadius + config.echoRadius) * 1.8
            let eta = lastVelocity.length > 1 ? dist / max(currentSpeed, 1) : dist / 120
            let threat = EchoThreat(echoIndex: index, distance: dist, eta: eta, willCollide: collide)
            if best == nil || threat.willCollide && !(best!.willCollide) || threat.distance < (best?.distance ?? .infinity) {
                best = threat
            }
        }
        nearestThreat = best
    }

    private func clampToArena(_ position: Vec2, radius: Double) -> Vec2 {
        let inset = config.edgeInset + radius
        return position.clamped(
            minX: inset,
            minY: inset,
            maxX: level.worldWidth - inset,
            maxY: level.worldHeight - inset
        )
    }

    private func resolveWalls(_ position: Vec2, radius: Double) -> Vec2 {
        var p = position
        for wall in level.walls {
            p = CircleMath.resolve(center: p, radius: radius, box: wall)
        }
        return clampToArena(p, radius: radius)
    }

    private func captureSnapshot() {
        snapshots.append(
            WorldSnapshot(
                time: time,
                player: playerPosition,
                echoes: echoes,
                sparkCollected: sparks.map(\.collected),
                exitOpen: exitOpen
            )
        )
        let keep = Int(config.snapshotWindow * config.snapshotHz) + 8
        if snapshots.count > keep {
            snapshots.removeFirst(snapshots.count - keep)
        }
    }
}
