import Foundation

enum RenderMode: Equatable, Sendable {
    case live
    case replay
    case ballet
}

struct RenderFrame: Equatable, Sendable {
    var time: TimeInterval
    var playbackTime: TimeInterval
    var player: Vec2
    var lastVelocity: Vec2
    var lastAim: Vec2
    var echoes: [Vec2]
    var sparks: [SparkState]
    var bonuses: [BonusState]
    var movers: [MoverState]
    var lasers: [LaserState]
    var rifts: [RiftState]
    var gates: [TimeGateState]
    var scars: [CollisionScar]
    var effects: ActiveEffects
    var exitOpen: Bool
    var ghosts: [ParadoxGhost]
    var reality: RealityMode
    var gravityWells: [GravityWellState]
    var timelineScale: Double

    init(
        time: TimeInterval,
        playbackTime: TimeInterval,
        player: Vec2,
        lastVelocity: Vec2,
        lastAim: Vec2,
        echoes: [Vec2],
        sparks: [SparkState],
        bonuses: [BonusState],
        movers: [MoverState],
        lasers: [LaserState],
        rifts: [RiftState],
        gates: [TimeGateState],
        scars: [CollisionScar],
        effects: ActiveEffects,
        exitOpen: Bool,
        ghosts: [ParadoxGhost],
        reality: RealityMode,
        gravityWells: [GravityWellState],
        timelineScale: Double
    ) {
        self.time = time
        self.playbackTime = playbackTime
        self.player = player
        self.lastVelocity = lastVelocity
        self.lastAim = lastAim
        self.echoes = echoes
        self.sparks = sparks
        self.bonuses = bonuses
        self.movers = movers
        self.lasers = lasers
        self.rifts = rifts
        self.gates = gates
        self.scars = scars
        self.effects = effects
        self.exitOpen = exitOpen
        self.ghosts = ghosts
        self.reality = reality
        self.gravityWells = gravityWells
        self.timelineScale = timelineScale
    }

    init(simulation sim: WorldSimulation) {
        self.init(
            time: sim.time,
            playbackTime: sim.playbackTime,
            player: sim.playerPosition,
            lastVelocity: sim.lastVelocity,
            lastAim: sim.lastAim,
            echoes: sim.echoes,
            sparks: sim.sparks,
            bonuses: sim.bonuses,
            movers: sim.movers,
            lasers: sim.lasers,
            rifts: sim.rifts,
            gates: sim.gates,
            scars: sim.scars,
            effects: sim.effects,
            exitOpen: sim.exitOpen,
            ghosts: sim.ghosts,
            reality: sim.reality,
            gravityWells: sim.gravityWells,
            timelineScale: sim.timelineScale
        )
    }

    init(snapshot: WorldSnapshot, gravityWells: [GravityWellState], anchoredScale: Double) {
        let scale: Double
        if snapshot.effects.isFrozen {
            scale = 0
        } else if snapshot.effects.isAnchored {
            scale = anchoredScale
        } else {
            scale = 1
        }
        self.init(
            time: snapshot.time,
            playbackTime: snapshot.playbackTime,
            player: snapshot.player,
            lastVelocity: snapshot.lastVelocity,
            lastAim: snapshot.lastAim,
            echoes: snapshot.echoes,
            sparks: snapshot.sparks,
            bonuses: snapshot.bonuses,
            movers: snapshot.movers,
            lasers: snapshot.lasers,
            rifts: snapshot.rifts,
            gates: snapshot.gates,
            scars: snapshot.scars,
            effects: snapshot.effects,
            exitOpen: snapshot.exitOpen,
            ghosts: snapshot.ghosts,
            reality: snapshot.reality,
            gravityWells: gravityWells,
            timelineScale: scale
        )
    }

    static func nearest(in frames: [RenderFrame], time: TimeInterval) -> RenderFrame? {
        guard let first = frames.first else { return nil }
        if time <= first.time { return first }
        var lo = 0
        var hi = frames.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if frames[mid].time <= time + 1e-9 {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        if lo + 1 < frames.count {
            let left = frames[lo]
            let right = frames[lo + 1]
            return abs(right.time - time) < abs(time - left.time) ? right : left
        }
        return frames[lo]
    }
}

enum ReplayTiming {
    static let rate: TimeInterval = 0.45

    static func index(times: [TimeInterval], elapsed: TimeInterval) -> Int {
        guard let start = times.first else { return 0 }
        let target = start + elapsed
        var lo = 0
        var hi = times.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if times[mid] <= target + 1e-9 {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        return lo
    }
}
