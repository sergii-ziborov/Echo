import Foundation

struct SimConfig: Equatable, Sendable {
    var playerRadius: Double = 16
    var echoRadius: Double = 16
    var sparkRadius: Double = 12
    var exitRadius: Double = 30
    var moveQuantum: Double = 24
    var inputDeadzone: Double = 12
    var collisionSlop: Double = 1.2
    var lookAhead: TimeInterval = 0.75
    var snapshotWindow: TimeInterval = 3.0
    var snapshotHz: Double = 60
    var edgeInset: Double = 36
}

enum SimPhase: Equatable, Sendable {
    case playing
    case dead
    case won
}

enum SimEvent: Equatable, Sendable {
    case sparkCollected(id: Int, remaining: Int)
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
}

final class WorldSimulation {
    let level: LevelDefinition
    let config: SimConfig

    private(set) var phase: SimPhase = .playing
    private(set) var time: TimeInterval = 0
    private(set) var playerPosition: Vec2
    private(set) var lastVelocity: Vec2 = .zero
    private(set) var echoes: [Vec2] = []
    private(set) var sparks: [SparkState]
    private(set) var exitOpen = false
    private(set) var moves = 0
    private(set) var recorder = PathRecorder()
    private(set) var snapshots: [WorldSnapshot] = []
    private(set) var nearestThreat: EchoThreat?
    private(set) var deathCause: DeathCause?
    private(set) var result: SessionResult?

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
        return max(0, at - time)
    }

    var isWarning: Bool {
        guard let remaining = nextEchoIn else { return false }
        return remaining <= level.warningLead
    }

    private var distanceAcc = 0.0
    private var warnedFor = -1
    private var snapshotAcc = 0.0

    init(level: LevelDefinition, config: SimConfig = SimConfig()) {
        self.level = level
        self.config = config
        self.playerPosition = level.playerStart
        self.sparks = level.sparks.map { SparkState(id: $0.id, position: $0.position, collected: false) }
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    func reset() {
        phase = .playing
        time = 0
        playerPosition = level.playerStart
        lastVelocity = .zero
        echoes = []
        sparks = level.sparks.map { SparkState(id: $0.id, position: $0.position, collected: false) }
        exitOpen = false
        moves = 0
        recorder = PathRecorder()
        snapshots = []
        nearestThreat = nil
        deathCause = nil
        result = nil
        distanceAcc = 0
        warnedFor = -1
        snapshotAcc = 0
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    @discardableResult
    func step(dt rawDt: TimeInterval, target: Vec2?) -> [SimEvent] {
        guard phase == .playing else { return [] }
        let dt = min(max(rawDt, 0), 1.0 / 20.0)
        guard dt > 0 else { return [] }

        time += dt
        var events: [SimEvent] = []

        movePlayer(dt: dt, target: target)
        recorder.record(time: time, position: playerPosition)

        events.append(contentsOf: spawnEchoesIfNeeded())
        refreshEchoPositions()
        events.append(contentsOf: collectSparks())
        refreshThreats()

        if let death = collideEchoes() {
            phase = .dead
            deathCause = death
            events.append(.died(death))
            captureSnapshot()
            return events
        }

        if exitOpen, playerPosition.distance(to: level.exit) < config.playerRadius + config.exitRadius {
            let session = SessionResult(
                time: time,
                moves: moves,
                stars: StarRating.stars(
                    time: time,
                    moves: moves,
                    parTime: level.parTime,
                    parMoves: level.parMoves
                ),
                sparks: sparks.count,
                echoesFaced: echoCount
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
        return recorder.polyline(from: max(0, time - delay), duration: duration)
    }

    func recentPlayerPath(duration: TimeInterval = 8) -> [Vec2] {
        recorder.polyline(from: max(0, time - duration), duration: min(duration, time), stride: 0.08)
    }

    // MARK: - Internals

    private func movePlayer(dt: TimeInterval, target: Vec2?) {
        var velocity = Vec2.zero
        if let target {
            let delta = target - playerPosition
            let dist = delta.length
            if dist > config.inputDeadzone {
                let stepLen = min(level.playerSpeed * dt, dist)
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
        let desired = min(level.maxEchoes, Int(time / level.echoInterval))

        if desired > echoCount {
            let previous = echoCount
            echoes = Array(repeating: level.playerStart, count: desired)
            for i in previous..<desired {
                events.append(.echoSpawned(index: i))
            }
        }

        if echoCount < level.maxEchoes {
            let remaining = (Double(echoCount + 1) * level.echoInterval) - time
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
            echoes[i] = recorder.position(at: max(0, time - delay)) ?? level.playerStart
        }
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
            let futureEcho = recorder.position(at: max(0, time - delay + config.lookAhead)) ?? echo
            let futurePlayer: Vec2
            if lastVelocity.length > 1 {
                futurePlayer = playerPosition + lastVelocity * config.lookAhead
            } else {
                futurePlayer = playerPosition
            }
            let futureDist = futurePlayer.distance(to: futureEcho)
            let collide = futureDist < (config.playerRadius + config.echoRadius) * 1.8
            let eta = lastVelocity.length > 1 ? dist / max(level.playerSpeed, 1) : dist / 120
            let threat = EchoThreat(echoIndex: index, distance: dist, eta: eta, willCollide: collide)
            if best == nil || threat.distance < best!.distance || (threat.willCollide && !(best!.willCollide)) {
                if best == nil || threat.willCollide && !best!.willCollide || threat.distance < best!.distance {
                    best = threat
                }
            }
        }
        nearestThreat = best
    }

    private func clampToArena(_ position: Vec2, radius: Double) -> Vec2 {
        let inset = config.edgeInset + radius
        return position.clamped(
            minX: inset,
            minY: inset,
            maxX: level.worldSize - inset,
            maxY: level.worldSize - inset
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
