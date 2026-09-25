import Foundation

/// One endless run: a seed that fixes every arena, and the depth being played.
struct EndlessKey: Codable, Equatable, Hashable, Sendable {
    var seed: UInt64
    var depth: Int

    var levelID: String { "endless-\(String(seed, radix: 16))-\(depth)" }
    var next: EndlessKey { EndlessKey(seed: seed, depth: depth + 1) }
    /// A short code players can recognise a run by.
    var code: String { String(format: "%04X", UInt16(truncatingIfNeeded: seed ^ (seed >> 16) ^ (seed >> 32))) }

    static func fresh() -> EndlessKey {
        EndlessKey(seed: UInt64.random(in: 1 ... .max), depth: 1)
    }
}

/// What endless play has banked on this device.
struct EndlessRecord: Codable, Equatable, Sendable {
    var bestDepth = 0
    var runs = 0
    var depthsCleared = 0
    /// The run to resume, pointing at the next depth to play.
    var current: EndlessKey?

    mutating func start(_ key: EndlessKey) {
        runs += 1
        current = key
    }

    mutating func cleared(_ key: EndlessKey) {
        bestDepth = max(bestDepth, key.depth)
        depthsCleared += 1
        current = key.next
    }

    /// A crash with nothing left to rewind ends the run for good.
    mutating func end(_ key: EndlessKey) {
        if current?.seed == key.seed { current = nil }
    }
}

/// How hard a depth is. Everything ramps gently, then levels off, so a long
/// run stays dense without becoming impossible.
struct EndlessPressure: Equatable, Sendable {
    let depth: Int

    var sparks: Int { 4 + min(4, depth / 3) }
    var timedSparks: Int { depth >= 8 ? 2 : (depth >= 3 ? 1 : 0) }
    var echoInterval: TimeInterval { max(4.6, 7.4 - 0.14 * Double(depth)) }
    var maxEchoes: Int { min(7, 3 + depth / 3) }
    var rocks: Int { min(6, 1 + depth / 2) }
    var rockSpeed: Double { 62 + min(90, Double(depth) * 6) }
    var lasers: Int { depth >= 9 ? 2 : (depth >= 4 ? 1 : 0) }
    var bonuses: Int { depth >= 6 ? 2 : (depth >= 2 ? 1 : 0) }
    var playerSpeed: Double { 320 + min(30, Double(depth) * 1.5) }

    var materials: [AsteroidMaterial] {
        switch depth {
        case ..<3: [.basalt, .ice, .crystal, .alloy]
        case ..<6: [.basalt, .ice, .magma, .alloy, .crystal, .iron]
        default: AsteroidMaterial.allCases
        }
    }

    var bonusKinds: [BonusKind] {
        depth >= 8
            ? [.shield, .freeze, .surge, .magnet, .pulse, .phase, .chrono, .repulse, .blink]
            : [.shield, .freeze, .surge, .magnet, .pulse, .phase]
    }
}
