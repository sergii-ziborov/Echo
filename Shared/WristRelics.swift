import Foundation

/// Rewards the iPhone game grants for clearing maps on Apple Watch.
enum WristRelic: String, CaseIterable, Identifiable, Sendable {
    case tourbillonTail
    case crownCharge
    case mainspring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tourbillonTail: "Tourbillon Tail"
        case .crownCharge: "Crown Charge"
        case .mainspring: "Mainspring"
        }
    }

    var detail: String {
        switch self {
        case .tourbillonTail: "Your comet burns ember-gold on iPhone."
        case .crownCharge: "One extra Paradox Rewind in every iPhone run."
        case .mainspring: "Echoes arrive 0.5 s later on iPhone."
        }
    }

    var symbol: String {
        switch self {
        case .tourbillonTail: "flame.fill"
        case .crownCharge: "crown.fill"
        case .mainspring: "gearshape.2.fill"
        }
    }

    /// Clears on the watch needed to unlock this relic.
    var requiredClears: Int {
        switch self {
        case .tourbillonTail: 4
        case .crownCharge: 8
        case .mainspring: 12
        }
    }
}

/// Wrist progress as both devices store and exchange it.
struct WristProgress: Codable, Equatable, Sendable {
    var cleared: Set<String> = []
    var bestTimes: [String: Double] = [:]

    static let shardsPerMap = 25
    static let echoDelayRelicBonus: TimeInterval = 0.5

    var relics: [WristRelic] {
        WristRelic.allCases.filter { cleared.count >= $0.requiredClears }
    }

    func isUnlocked(_ relic: WristRelic) -> Bool {
        cleared.count >= relic.requiredClears
    }

    /// Maps unlock in order: the next one opens after the previous is cleared.
    func isPlayable(_ level: LevelDefinition) -> Bool {
        level.number == 1 || cleared.contains("wrist-\(level.number - 1)")
    }

    mutating func record(clear id: String, time: TimeInterval) {
        cleared.insert(id)
        bestTimes[id] = min(bestTimes[id] ?? time, time)
    }

    /// Union of both sides; the faster time wins. Returns the ids that were new.
    @discardableResult
    mutating func merge(_ other: WristProgress) -> Set<String> {
        let fresh = other.cleared.subtracting(cleared)
        cleared.formUnion(other.cleared)
        for (id, time) in other.bestTimes {
            bestTimes[id] = min(bestTimes[id] ?? time, time)
        }
        return fresh
    }
}

/// Skills that only exist on the watch, unlocked by clearing wrist maps.
enum WristSkill: String, CaseIterable, Identifiable, Sendable {
    case crownRewind
    case pulseSense
    case wristDash
    case tickFreeze

    var id: String { rawValue }

    var title: String {
        switch self {
        case .crownRewind: "Crown Rewind"
        case .pulseSense: "Pulse Sense"
        case .wristDash: "Wrist Dash"
        case .tickFreeze: "Tick Freeze"
        }
    }

    var detail: String {
        switch self {
        case .crownRewind: "Turn the Digital Crown back to rewind three seconds."
        case .pulseSense: "Your wrist taps before every echo appears."
        case .wristDash: "Double-tap the arena to dash."
        case .tickFreeze: "Freeze every hazard from the skill button, or with a double tap of your fingers."
        }
    }

    var symbol: String {
        switch self {
        case .crownRewind: "digitalcrown.arrow.counterclockwise"
        case .pulseSense: "waveform.path.ecg"
        case .wristDash: "hare.fill"
        case .tickFreeze: "snowflake"
        }
    }

    var requiredClears: Int {
        switch self {
        case .crownRewind, .pulseSense: 0
        case .wristDash: 2
        case .tickFreeze: 6
        }
    }
}
