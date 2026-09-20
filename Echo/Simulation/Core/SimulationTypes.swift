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
    case asteroidImpacted(id: Int, material: AsteroidMaterial, at: Vec2)
    case asteroidShattered(id: Int, material: AsteroidMaterial, at: Vec2)
    case echoWillSpawn(index: Int, in: TimeInterval)
    case echoSpawned(index: Int)
    case exitOpened
    case riftOpened(id: Int)
    case riftEntered(kind: RiftKind)
    case playerTeleported(from: Vec2, to: Vec2, reason: TeleportReason)
    case timeCollision(at: Vec2)
    case died(DeathCause)
    case won(SessionResult)
}

enum TeleportReason: Equatable, Sendable {
    case blink
    case warp
}

struct SparkState: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var collected: Bool
    var timerDuration: TimeInterval?
    var timerRemaining: TimeInterval?
    var timedOut: Bool
    var orbit: SparkOrbit?
    var magnetHeld: Bool = false
}
