import Foundation

final class WorldSimulation {
    let level: LevelDefinition
    let config: SimConfig

    var phase: SimPhase = .playing
    var time: TimeInterval = 0
    var playbackTime: TimeInterval = 0
    var playerPosition: Vec2
    var lastVelocity: Vec2 = .zero
    var lastAim: Vec2 = .zero
    var echoes: [Vec2] = []
    var sparks: [SparkState]
    var bonuses: [BonusState]
    var movers: [MoverState]
    var gravityWells: [GravityWellState]
    var lasers: [LaserState]
    var rifts: [RiftState]
    var gates: [TimeGateState]
    var scars: [CollisionScar] = []
    var effects = ActiveEffects()
    var exitOpen = false
    var moves = 0
    var bonusesCollected = 0
    var timedSparksSecured = 0
    var resonanceChain = 0
    var bestResonance = 0
    var resonanceRemaining: TimeInterval = 0
    var recorder = PathRecorder()
    var snapshots: [WorldSnapshot] = []
    var reviewFrames: [RenderFrame] = []
    var lastReviewTime: TimeInterval = -1
    var appliedEvents: [SimEvent] = []
    var nearestThreat: EchoThreat?
    var deathCause: DeathCause?
    var result: SessionResult?
    var inSlowField = false
    var hasStarted = false
    var ghosts: [ParadoxGhost] = []
    var dashed = false
    var usedItem = false
    var scarsCreated = 0
    var riftsUsed = 0
    var closestApproach = Double.infinity
    var rewindCharges = 1
    var tuning = PlayerTuning()
    var reality: RealityMode = .normal
    var realityRemaining: TimeInterval = 0

    var echoCount: Int { echoes.count }
    var sparksCollected: Int { sparks.filter(\.collected).count }
    var sparksRemaining: Int { sparks.count - sparksCollected }
    var nextEchoIndex: Int { echoCount }
    var maxEchoes: Int { level.maxEchoes }

    var nextEchoAt: TimeInterval? {
        guard echoCount < level.maxEchoes else { return nil }
        return Double(echoCount + 1) * level.echoInterval + tuning.echoDelayBonus + pulseDelay
    }

    var echoClock: TimeInterval {
        max(0, playbackTime - pulseDelay - tuning.echoDelayBonus)
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

    var timelineScale: Double {
        if effects.isFrozen { return 0 }
        if effects.isAnchored { return tuning.anchorTimeScale }
        return 1
    }

    var distanceAcc = 0.0
    var warnedFor = -1
    var snapshotAcc = 0.0
    var pulseDelay: TimeInterval = 0
    var collisionCooldown: TimeInterval = 0
    var riftTravelCooldown: TimeInterval = 0
    var resonanceWindow: TimeInterval { reality == .candy ? Self.candyResonanceWindow : Self.normalResonanceWindow }

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
        effects.shieldCharges = tuning.startsShielded
            ? max(tuning.shieldChargesPerUse, effects.shieldCharges)
            : effects.shieldCharges
        snapshots.removeAll()
        reviewFrames.removeAll()
        lastReviewTime = -1
        appliedEvents.removeAll()
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

    func debugPreviewAsteroidFractures() {
        hasStarted = true
        for index in movers.indices where movers[index].material.isBreakable {
            if let duration = movers[index].material.fractureDuration,
               let maxHits = movers[index].material.wallHitsToShatter {
                movers[index].fractureRemaining = duration * 0.72
                movers[index].hitsRemaining = max(1, maxHits - 1)
            }
        }
    }

    func debugPreviewAsteroidMotion() {
        hasStarted = true
    }
#endif

    func reset() {
        phase = .playing
        time = 0
        playbackTime = 0
        playerPosition = level.playerStart
        lastVelocity = .zero
        lastAim = .zero
        echoes = []
        sparks = Self.makeSparks(level.sparks)
        bonuses = Self.makeBonuses(level.bonuses)
        movers = Self.makeMovers(level.movers)
        gravityWells = Self.makeGravityWells(level.gravityWells)
        lasers = Self.makeLasers(level.lasers)
        rifts = Self.makeRifts(level.rifts)
        gates = Self.makeGates(level.gates)
        scars = []
        effects = ActiveEffects(shieldCharges: tuning.startsShielded ? tuning.shieldChargesPerUse : 0)
        exitOpen = false
        moves = 0
        bonusesCollected = 0
        timedSparksSecured = 0
        resonanceChain = 0
        bestResonance = 0
        resonanceRemaining = 0
        recorder = PathRecorder()
        snapshots = []
        reviewFrames = []
        lastReviewTime = -1
        appliedEvents.removeAll()
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

    func restore(_ snap: WorldSnapshot) {
        time = snap.time
        playbackTime = snap.playbackTime
        playerPosition = snap.player
        lastVelocity = snap.lastVelocity
        lastAim = snap.lastAim
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
        reviewFrames.removeAll { $0.time > snap.time }
        lastReviewTime = reviewFrames.last?.time ?? -1
    }

    @discardableResult
    func tryDash() -> Bool {
        guard phase == .playing, hasStarted, effects.canDash else { return false }
        effects.surgeRemaining = max(effects.surgeRemaining, config.dashDuration + tuning.dashDurationBonus)
        effects.dashCooldown = config.dashCooldown * tuning.dashCooldownMultiplier
        dashed = true
        return true
    }

    @discardableResult
    func activate(_ kind: BonusKind, fromShop: Bool = false) -> Bool {
        guard phase == .playing else { return false }
        switch kind {
        case .pulse, .chrono:
            guard echoCount < level.maxEchoes else { return false }
        case .blink:
            guard blinkDirection() != nil else { return false }
        default:
            break
        }
        appliedEvents = apply(kind)
        if fromShop { usedItem = true }
        return true
    }

    func drainAppliedEvents() -> [SimEvent] {
        defer { appliedEvents.removeAll() }
        return appliedEvents
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
        let wasAnchored = effects.isAnchored
        tickEffects(dt: dt)
        let timeIsFrozen = wasFrozen || effects.isFrozen
        let timeIsAnchored = wasAnchored || effects.isAnchored
        let temporalScale: TimeInterval = timeIsFrozen ? 0 : timeIsAnchored ? tuning.anchorTimeScale : 1
        let temporalDt = dt * temporalScale
        playbackTime += temporalDt
        var events: [SimEvent] = []
        events.append(contentsOf: tickTimers(dt: temporalDt))
        tickResonance(dt: temporalDt)
        updateOrbits()
        if temporalDt > 0 {
            events.append(contentsOf: stepMovers(dt: temporalDt))
            applyGravityWells(dt: temporalDt)
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
        tickScars(dt: temporalDt)
        events.append(contentsOf: detectTimeCollision(dt: temporalDt))
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

}
