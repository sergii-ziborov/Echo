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
    case resonance(chain: Int, window: TimeInterval)
    case timeCrystalSecured(id: Int, freeze: TimeInterval)
    case sparkTimerExpired(id: Int)
    case bonusCollected(kind: BonusKind)
    case shieldBroke
    case dashed
    case laserCharging(id: Int)
    case laserFired(id: Int)
    case echoWillSpawn(index: Int, in: TimeInterval)
    case echoSpawned(index: Int)
    case exitOpened
    case riftOpened(id: Int)
    case riftEntered(kind: RiftKind)
    case timeCollision(at: Vec2)
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
    private(set) var movers: [MoverState]
    private(set) var gravityWells: [GravityWellState]
    private(set) var lasers: [LaserState]
    private(set) var rifts: [RiftState]
    private(set) var gates: [TimeGateState]
    private(set) var scars: [CollisionScar] = []
    private(set) var effects = ActiveEffects()
    private(set) var exitOpen = false
    private(set) var moves = 0
    private(set) var bonusesCollected = 0
    private(set) var timedSparksSecured = 0
    private(set) var resonanceChain = 0
    private(set) var bestResonance = 0
    private(set) var resonanceRemaining: TimeInterval = 0
    private(set) var recorder = PathRecorder()
    private(set) var snapshots: [WorldSnapshot] = []
    private(set) var nearestThreat: EchoThreat?
    private(set) var deathCause: DeathCause?
    private(set) var result: SessionResult?
    private(set) var inSlowField = false
    private(set) var hasStarted = false
    private(set) var ghosts: [ParadoxGhost] = []
    private(set) var dashed = false
    private(set) var usedItem = false
    private(set) var scarsCreated = 0
    private(set) var riftsUsed = 0
    private(set) var closestApproach = Double.infinity
    private(set) var rewindCharges = 1
    private(set) var tuning = PlayerTuning()
    private(set) var reality: RealityMode = .normal
    private(set) var realityRemaining: TimeInterval = 0

    var echoCount: Int { echoes.count }
    var sparksCollected: Int { sparks.filter(\.collected).count }
    var sparksRemaining: Int { sparks.count - sparksCollected }
    var nextEchoIndex: Int { echoCount }
    var maxEchoes: Int { level.maxEchoes }

    var nextEchoAt: TimeInterval? {
        guard echoCount < level.maxEchoes else { return nil }
        return Double(echoCount + 1) * level.echoInterval + pulseDelay
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
        var speed = level.playerSpeed * tuning.speedMultiplier
        if effects.isSurging { speed *= config.dashSpeed }
        if inSlowField { speed *= 0.52 }
        if reality == .candy { speed *= 1.12 }
        return speed
    }

    private var distanceAcc = 0.0
    private var warnedFor = -1
    private var snapshotAcc = 0.0
    private var pulseDelay: TimeInterval = 0
    private var collisionCooldown: TimeInterval = 0
    private var riftTravelCooldown: TimeInterval = 0
    private var resonanceWindow: TimeInterval { reality == .candy ? 5.0 : 3.25 }

    init(level: LevelDefinition, config: SimConfig = SimConfig()) {
        self.level = level
        self.config = config
        self.playerPosition = level.playerStart
        self.sparks = Self.makeSparks(level.sparks)
        self.bonuses = Self.makeBonuses(level.bonuses)
        self.movers = Self.makeMovers(level.movers)
        self.gravityWells = Self.makeGravityWells(level.gravityWells)
        self.lasers = Self.makeLasers(level.lasers)
        self.rifts = Self.makeRifts(level.rifts)
        self.gates = Self.makeGates(level.gates)
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    func configure(tuning: PlayerTuning) {
        guard !hasStarted else { return }
        self.tuning = tuning
        rewindCharges = tuning.rewindCharges
        effects.shieldCharges = tuning.startsShielded ? max(1, effects.shieldCharges) : effects.shieldCharges
        snapshots.removeAll()
        captureSnapshot()
    }

#if DEBUG
    func debugEnterReality(_ mode: RealityMode) {
        reality = mode
        realityRemaining = 30
        for index in rifts.indices where rifts[index].kind == .candy || rifts[index].kind == .warp {
            rifts[index].open = true
        }
    }
#endif

    func reset() {
        phase = .playing
        time = 0
        playbackTime = 0
        playerPosition = level.playerStart
        lastVelocity = .zero
        echoes = []
        sparks = Self.makeSparks(level.sparks)
        bonuses = Self.makeBonuses(level.bonuses)
        movers = Self.makeMovers(level.movers)
        gravityWells = Self.makeGravityWells(level.gravityWells)
        lasers = Self.makeLasers(level.lasers)
        rifts = Self.makeRifts(level.rifts)
        gates = Self.makeGates(level.gates)
        scars = []
        effects = ActiveEffects(shieldCharges: tuning.startsShielded ? 1 : 0)
        exitOpen = false
        moves = 0
        bonusesCollected = 0
        timedSparksSecured = 0
        resonanceChain = 0
        bestResonance = 0
        resonanceRemaining = 0
        recorder = PathRecorder()
        snapshots = []
        nearestThreat = nil
        deathCause = nil
        result = nil
        inSlowField = false
        hasStarted = false
        ghosts = []
        dashed = false
        usedItem = false
        scarsCreated = 0
        riftsUsed = 0
        closestApproach = .infinity
        rewindCharges = tuning.rewindCharges
        reality = .normal
        realityRemaining = 0
        riftTravelCooldown = 0
        distanceAcc = 0
        warnedFor = -1
        snapshotAcc = 0
        pulseDelay = 0
        collisionCooldown = 0
        recorder.record(time: 0, position: level.playerStart)
        captureSnapshot()
    }

    @discardableResult
    func rewind(seconds: TimeInterval = 3) -> Bool {
        guard rewindCharges > 0, !snapshots.isEmpty else { return false }
        let target = max(0, time - seconds)
        guard let snap = snapshots.last(where: { $0.time <= target }) ?? snapshots.first else { return false }
        let tail = recorder.slice(from: snap.time, to: time)
        restore(snap)
        if !tail.isEmpty {
            ghosts.append(ParadoxGhost(samples: tail, bornAt: time))
        }
        rewindCharges -= 1
        deathCause = nil
        phase = .playing
        effects.iFrames = max(effects.iFrames, 0.7)
        return true
    }

    private func restore(_ snap: WorldSnapshot) {
        time = snap.time
        playbackTime = snap.playbackTime
        playerPosition = snap.player
        lastVelocity = snap.lastVelocity
        echoes = snap.echoes
        sparks = snap.sparks
        bonuses = snap.bonuses
        movers = snap.movers
        lasers = snap.lasers
        rifts = snap.rifts
        gates = snap.gates
        scars = snap.scars
        effects = snap.effects
        exitOpen = snap.exitOpen
        moves = snap.moves
        bonusesCollected = snap.bonusesCollected
        timedSparksSecured = snap.timedSparksSecured
        resonanceChain = snap.resonanceChain
        bestResonance = snap.bestResonance
        resonanceRemaining = snap.resonanceRemaining
        hasStarted = snap.hasStarted
        recorder = snap.recorder
        pulseDelay = snap.pulseDelay
        warnedFor = snap.warnedFor
        distanceAcc = snap.distanceAcc
        ghosts = snap.ghosts
        dashed = snap.dashed
        usedItem = snap.usedItem
        scarsCreated = snap.scarsCreated
        riftsUsed = snap.riftsUsed
        closestApproach = snap.closestApproach
        reality = snap.reality
        realityRemaining = snap.realityRemaining
        riftTravelCooldown = snap.riftTravelCooldown
        snapshots.removeAll { $0.time > snap.time }
    }

    @discardableResult
    func tryDash() -> Bool {
        guard phase == .playing, hasStarted, effects.canDash else { return false }
        effects.surgeRemaining = max(effects.surgeRemaining, config.dashDuration)
        effects.dashCooldown = config.dashCooldown * tuning.dashCooldownMultiplier
        dashed = true
        return true
    }

    @discardableResult
    func activate(_ kind: BonusKind, fromShop: Bool = false) -> Bool {
        guard phase == .playing else { return false }
        apply(kind)
        if fromShop { usedItem = true }
        return true
    }

    @discardableResult
    func step(dt rawDt: TimeInterval, target: Vec2?) -> [SimEvent] {
        guard phase == .playing else { return [] }
        let dt = min(max(rawDt, 0), 1.0 / 20.0)
        guard dt > 0 else { return [] }

        movePlayer(dt: dt, target: target)
        if !hasStarted {
            if playerPosition.distance(to: level.playerStart) > config.inputDeadzone {
                hasStarted = true
            } else {
                recorder.record(time: 0, position: playerPosition)
                return []
            }
        }

        time += dt
        let wasFrozen = effects.isFrozen
        tickEffects(dt: dt)
        let timeIsFrozen = wasFrozen || effects.isFrozen
        let echoScale: TimeInterval = timeIsFrozen ? 0 : 1
        playbackTime += dt * echoScale
        var events: [SimEvent] = []
        events.append(contentsOf: tickTimers(dt: timeIsFrozen ? 0 : dt))
        tickResonance(dt: timeIsFrozen ? 0 : dt)
        updateOrbits()
        if !timeIsFrozen {
            stepMovers(dt: dt)
            applyGravityWells(dt: dt)
        }

        recorder.record(time: time, position: playerPosition)
        applyMagnet(dt: dt)

        events.append(contentsOf: spawnEchoesIfNeeded())
        refreshEchoPositions()
        events.append(contentsOf: collectSparks())
        events.append(contentsOf: collectBonuses())
        events.append(contentsOf: tickRifts())
        tickGates()
        events.append(contentsOf: tickLasers())
        tickScars(dt: dt)
        events.append(contentsOf: detectTimeCollision(dt: dt))
        refreshGhosts()
        refreshThreats()
        trackClosest()

        if effects.iFrames <= 0,
           !effects.isPhasing,
           let death = collideEchoes() ?? collideMovers() ?? collideGravityWells() ?? collideLasers() ?? collideRifts() ?? collideScars() ?? collideGhosts() {
            if effects.shieldCharges > 0 {
                effects.shieldCharges -= 1
                effects.iFrames = 0.55 + tuning.shieldGraceBonus
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
            var session = SessionResult(
                time: time,
                moves: moves,
                stars: 1,
                sparks: sparks.count,
                echoesFaced: echoCount,
                bonuses: bonusesCollected,
                timeCrystals: timedSparksSecured,
                resonance: bestResonance,
                dashed: dashed,
                usedItem: usedItem,
                scars: scarsCreated,
                riftsUsed: riftsUsed,
                closest: closestApproach
            )
            let seals = LevelCatalog.seals(for: level.number)
            session.control = seals.control.met(by: session, parTime: level.parTime)
            session.paradox = seals.paradox.met(by: session, parTime: level.parTime)
            session.stars = 1 + (session.control ? 1 : 0) + (session.paradox ? 1 : 0)
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
        if effects.phaseRemaining > 0 {
            effects.phaseRemaining = max(0, effects.phaseRemaining - dt)
            effects.iFrames = max(effects.iFrames, effects.phaseRemaining)
        }
        if effects.dashCooldown > 0 { effects.dashCooldown = max(0, effects.dashCooldown - dt) }
        if effects.iFrames > 0 { effects.iFrames = max(0, effects.iFrames - dt) }
        if riftTravelCooldown > 0 { riftTravelCooldown = max(0, riftTravelCooldown - dt) }
        if realityRemaining > 0 {
            realityRemaining = max(0, realityRemaining - dt)
            if realityRemaining == 0 { reality = .normal }
        }
        inSlowField = level.fields.contains { $0.area.contains(playerPosition) }
    }

    private func movePlayer(dt: TimeInterval, target: Vec2?) {
        var velocity = Vec2.zero
        if let target {
            let effectiveTarget = reality == .mirror
                ? Vec2(x: level.worldWidth - target.x, y: target.y)
                : target
            let delta = effectiveTarget - playerPosition
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
            let expandedTimer = $0.timer.map { max(12, $0 * 1.25) }
            return SparkState(
                id: $0.id,
                position: $0.position,
                collected: false,
                timerDuration: expandedTimer,
                timerRemaining: expandedTimer,
                timedOut: false,
                orbit: $0.orbit
            )
        }
    }

    private static func makeBonuses(_ spawns: [BonusSpawn]) -> [BonusState] {
        spawns.map { BonusState(id: $0.id, kind: $0.kind, position: $0.position, collected: false) }
    }

    private static func makeRifts(_ spawns: [RiftSpawn]) -> [RiftState] {
        spawns.map {
            RiftState(
                id: $0.id,
                kind: $0.kind,
                position: $0.position,
                radius: $0.radius,
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
    }

    private func tickRifts() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in rifts.indices {
            let open = rifts[i].isOpen(at: playbackTime)
            if open, !rifts[i].open {
                rifts[i].usedThisCycle = false
                events.append(.riftOpened(id: rifts[i].id))
            }
            if !open { rifts[i].usedThisCycle = false }
            rifts[i].open = open
            guard open, !rifts[i].usedThisCycle, riftTravelCooldown <= 0 else { continue }
            if playerPosition.distance(to: rifts[i].position) < config.playerRadius + rifts[i].radius {
                rifts[i].usedThisCycle = true
                events.append(.riftEntered(kind: rifts[i].kind))
                riftsUsed += 1
                switch rifts[i].kind {
                case .calm:
                    effects.freezeRemaining = max(effects.freezeRemaining, 1.6)
                case .collision:
                    break
                case .warp:
                    let folded = Vec2(
                        x: level.worldWidth - playerPosition.x,
                        y: level.worldHeight - playerPosition.y
                    )
                    playerPosition = resolveWalls(clampToArena(folded, radius: config.playerRadius), radius: config.playerRadius)
                    playbackTime = max(0, playbackTime - 1.35)
                    effects.iFrames = max(effects.iFrames, 0.75)
                    reality = .mirror
                    realityRemaining = 4.5
                    riftTravelCooldown = 1.1
                case .candy:
                    reality = .candy
                    realityRemaining = max(realityRemaining, 10)
                    effects.iFrames = max(effects.iFrames, 0.45)
                    riftTravelCooldown = 1.1
                }
            }
        }
        return events
    }

    private static func makeGravityWells(_ spawns: [GravityWellSpawn]) -> [GravityWellState] {
        spawns.map {
            GravityWellState(
                id: $0.id,
                position: $0.position,
                coreRadius: $0.coreRadius,
                influenceRadius: $0.influenceRadius,
                strength: $0.strength
            )
        }
    }

    private func applyGravityWells(dt: TimeInterval) {
        guard !effects.isFrozen else { return }
        for well in gravityWells {
            let delta = well.position - playerPosition
            let distance = delta.length
            guard distance > 0.5, distance < well.influenceRadius else { continue }
            let falloff = 1 - distance / well.influenceRadius
            let pull = min(distance, well.strength * falloff * falloff * dt)
            playerPosition = playerPosition + delta.normalized() * pull
        }
        playerPosition = resolveWalls(clampToArena(playerPosition, radius: config.playerRadius), radius: config.playerRadius)
    }

    private func collideGravityWells() -> DeathCause? {
        for well in gravityWells {
            if playerPosition.distance(to: well.position) < config.playerRadius + well.coreRadius * 0.68 {
                return .blackHole
            }
        }
        return nil
    }

    private static func makeGates(_ spawns: [TimeGateSpawn]) -> [TimeGateState] {
        spawns.map {
            TimeGateState(id: $0.id, area: $0.area, period: $0.period, openFor: $0.openFor, phase: $0.phase)
        }
    }

    private func tickGates() {
        for i in gates.indices {
            gates[i].solid = gates[i].isSolid(at: playbackTime)
        }
    }

    private func tickScars(dt: TimeInterval) {
        for i in scars.indices {
            scars[i].remaining -= dt
        }
        scars.removeAll { $0.remaining <= 0 }
    }

    private func collideScars() -> DeathCause? {
        for scar in scars {
            if playerPosition.distance(to: scar.position) < config.playerRadius + scar.radius - config.collisionSlop {
                return .collision
            }
        }
        return nil
    }

    private func collideRifts() -> DeathCause? {
        for rift in rifts where rift.open && rift.kind == .collision {
            if playerPosition.distance(to: rift.position) < config.playerRadius + rift.radius * 0.72 {
                return .rift
            }
        }
        return nil
    }

    private func detectTimeCollision(dt: TimeInterval) -> [SimEvent] {
        if collisionCooldown > 0 {
            collisionCooldown = max(0, collisionCooldown - dt)
            return []
        }
        guard echoes.count >= 2 else { return [] }
        for i in 0..<echoes.count {
            for j in (i + 1)..<echoes.count {
                if echoes[i].distance(to: echoes[j]) < config.echoRadius * 2.2 {
                    collisionCooldown = 3.2
                    let mid = echoes[i].lerp(echoes[j], 0.5)
                    scars.append(CollisionScar(id: scars.count + 17, position: mid, radius: 34, remaining: 2.8))
                    scarsCreated += 1
                    return [.timeCollision(at: mid)]
                }
            }
        }
        return []
    }

    private static func makeMovers(_ spawns: [MoverSpawn]) -> [MoverState] {
        spawns.map {
            MoverState(
                id: $0.id,
                kind: $0.kind,
                position: $0.position,
                velocity: $0.velocity,
                radius: max(34, $0.radius),
                path: $0.path
            )
        }
    }

    private static func makeLasers(_ spawns: [LaserSpawn]) -> [LaserState] {
        spawns.map {
            var state = LaserState(
                id: $0.id,
                start: $0.start,
                end: $0.end,
                beamWidth: $0.beamWidth,
                period: $0.period,
                chargeFor: $0.chargeFor,
                activeFor: $0.activeFor,
                offset: $0.phase,
                motion: $0.motion
            )
            state.updateGeometry(at: 0)
            return state
        }
    }

    private func tickLasers() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in lasers.indices {
            lasers[i].updateGeometry(at: playbackTime)
            let previous = lasers[i].phase
            let next = lasers[i].phase(at: playbackTime, warningBonus: tuning.laserWarningBonus)
            if case .charging = next, case .idle = previous {
                events.append(.laserCharging(id: lasers[i].id))
            }
            if case .firing = next, previous != .firing {
                events.append(.laserFired(id: lasers[i].id))
            }
            lasers[i].phase = next
        }
        return events
    }

    private func updateOrbits() {
        for i in sparks.indices where !sparks[i].collected {
            guard let orbit = sparks[i].orbit, orbit.period > 0 else { continue }
            let angle = orbit.phase + (playbackTime / orbit.period) * (.pi * 2)
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
            if dist < config.magnetRadius * tuning.magnetRadiusMultiplier, dist > 1 {
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

    private func tickResonance(dt: TimeInterval) {
        guard resonanceRemaining > 0 else { return }
        resonanceRemaining = max(0, resonanceRemaining - dt)
        if resonanceRemaining <= 0 {
            resonanceChain = 0
        }
    }

    private func collectSparks() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in sparks.indices where !sparks[i].collected {
            if playerPosition.distance(to: sparks[i].position) < config.playerRadius + config.sparkRadius {
                let securedCharge = sparks[i].timerDuration != nil && !sparks[i].timedOut
                sparks[i].collected = true
                let remaining = sparksRemaining
                events.append(.sparkCollected(id: sparks[i].id, remaining: remaining))
                resonanceChain = resonanceRemaining > 0 ? resonanceChain + 1 : 1
                resonanceRemaining = resonanceWindow
                bestResonance = max(bestResonance, resonanceChain)
                if resonanceChain >= 2 {
                    events.append(.resonance(chain: resonanceChain, window: resonanceWindow))
                }
                if securedCharge {
                    let reward = 1.5 + tuning.freezeBonus * 0.25
                    effects.freezeRemaining += reward
                    timedSparksSecured += 1
                    events.append(.timeCrystalSecured(id: sparks[i].id, freeze: reward))
                }
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
            effects.freezeRemaining += kind.duration + tuning.freezeBonus
        case .surge:
            effects.surgeRemaining += kind.duration
        case .pulse:
            pulseDelay += 2.4
        case .magnet:
            effects.magnetRemaining += kind.duration
        case .phase:
            effects.phaseRemaining += kind.duration
            effects.iFrames = max(effects.iFrames, kind.duration)
        case .chrono:
            pulseDelay += 3.6
        case .ward:
            effects.shieldCharges += 1
        }
    }

    private func stepMovers(dt: TimeInterval) {
        for i in movers.indices {
            switch movers[i].path {
            case .bounce:
                stepBouncingMover(at: i, dt: dt)
            case .patrol(let a, let b):
                let span = max(a.distance(to: b), 1)
                let speed = 90.0 / span
                movers[i].patrolT += dt * speed * movers[i].patrolDir
                if movers[i].patrolT >= 1 {
                    movers[i].patrolT = 1
                    movers[i].patrolDir = -1
                } else if movers[i].patrolT <= 0 {
                    movers[i].patrolT = 0
                    movers[i].patrolDir = 1
                }
                movers[i].position = a.lerp(b, movers[i].patrolT)
            case .orbit(let center, let radius, let period, let phase):
                let angle = phase + (time / max(period, 0.1)) * (.pi * 2)
                movers[i].position = Vec2(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
            }
        }
    }

    private func stepBouncingMover(at index: Int, dt: TimeInterval) {
        var mover = movers[index]
        var position = mover.position

        var xCandidate = Vec2(x: position.x + mover.velocity.x * dt, y: position.y)
        if moverIsBlocked(at: xCandidate, radius: mover.radius) {
            mover.velocity.x *= -1
            xCandidate = Vec2(x: position.x + mover.velocity.x * dt, y: position.y)
        }
        if !moverIsBlocked(at: xCandidate, radius: mover.radius) {
            position.x = xCandidate.x
        }

        var yCandidate = Vec2(x: position.x, y: position.y + mover.velocity.y * dt)
        if moverIsBlocked(at: yCandidate, radius: mover.radius) {
            mover.velocity.y *= -1
            yCandidate = Vec2(x: position.x, y: position.y + mover.velocity.y * dt)
        }
        if !moverIsBlocked(at: yCandidate, radius: mover.radius) {
            position.y = yCandidate.y
        }

        mover.position = clampToArena(position, radius: mover.radius)
        movers[index] = mover
    }

    private func moverIsBlocked(at position: Vec2, radius: Double) -> Bool {
        let inset = config.edgeInset + radius
        if position.x < inset || position.x > level.worldWidth - inset
            || position.y < inset || position.y > level.worldHeight - inset {
            return true
        }
        if level.walls.contains(where: { $0.intersectsCircle(center: position, radius: radius) }) {
            return true
        }
        return gates.contains { $0.solid && $0.area.intersectsCircle(center: position, radius: radius) }
    }

    private func collideMovers() -> DeathCause? {
        for mover in movers {
            let limit = config.playerRadius + mover.radius - config.collisionSlop
            if playerPosition.distance(to: mover.position) < limit {
                return .asteroid
            }
        }
        return nil
    }

    private func collideLasers() -> DeathCause? {
        guard !effects.isFrozen else { return nil }
        for laser in lasers where laser.phase == .firing {
            let limit = config.playerRadius + laser.beamWidth / 2 - config.collisionSlop
            if playerPosition.distance(toSegmentFrom: laser.start, to: laser.end) < limit {
                return .laser
            }
        }
        return nil
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
        for gate in gates where gate.solid {
            p = CircleMath.resolve(center: p, radius: radius, box: gate.area)
        }
        return clampToArena(p, radius: radius)
    }

    private func captureSnapshot() {
        snapshots.append(
            WorldSnapshot(
                time: time,
                playbackTime: playbackTime,
                player: playerPosition,
                lastVelocity: lastVelocity,
                echoes: echoes,
                sparks: sparks,
                bonuses: bonuses,
                movers: movers,
                lasers: lasers,
                rifts: rifts,
                gates: gates,
                scars: scars,
                effects: effects,
                exitOpen: exitOpen,
                moves: moves,
                bonusesCollected: bonusesCollected,
                timedSparksSecured: timedSparksSecured,
                resonanceChain: resonanceChain,
                bestResonance: bestResonance,
                resonanceRemaining: resonanceRemaining,
                hasStarted: hasStarted,
                recorder: recorder,
                pulseDelay: pulseDelay,
                warnedFor: warnedFor,
                distanceAcc: distanceAcc,
                ghosts: ghosts,
                dashed: dashed,
                usedItem: usedItem,
                scarsCreated: scarsCreated,
                riftsUsed: riftsUsed,
                closestApproach: closestApproach,
                reality: reality,
                realityRemaining: realityRemaining,
                riftTravelCooldown: riftTravelCooldown
            )
        )
        let keep = Int(config.snapshotWindow * config.snapshotHz) + 8
        if snapshots.count > keep {
            snapshots.removeFirst(snapshots.count - keep)
        }
    }

    private func refreshGhosts() {
        ghosts.removeAll { !$0.isAlive(at: time) }
    }

    private func collideGhosts() -> DeathCause? {
        let limit = config.playerRadius + config.echoRadius - config.collisionSlop
        for ghost in ghosts {
            if let point = ghost.position(at: time), playerPosition.distance(to: point) < limit {
                return .ghost
            }
        }
        return nil
    }

    private func trackClosest() {
        for echo in echoes {
            closestApproach = min(closestApproach, playerPosition.distance(to: echo))
        }
        for ghost in ghosts {
            if let point = ghost.position(at: time) {
                closestApproach = min(closestApproach, playerPosition.distance(to: point))
            }
        }
    }
}
