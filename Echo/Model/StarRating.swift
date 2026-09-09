import Foundation

enum StarRating {
    static func stars(time: TimeInterval, moves: Int, parTime: TimeInterval, parMoves: Int) -> Int {
        if time <= parTime && moves <= parMoves { return 3 }
        if time <= parTime * 1.35 || moves <= Int(Double(parMoves) * 1.35) { return 2 }
        return 1
    }

    static func points(stars: Int, bonuses: Int) -> Int {
        max(0, stars) * 50 + max(0, bonuses) * 20 + 10
    }
}

struct SessionResult: Equatable, Sendable {
    var time: TimeInterval
    var moves: Int
    var stars: Int
    var sparks: Int
    var echoesFaced: Int
    var bonuses: Int = 0

    var points: Int {
        StarRating.points(stars: stars, bonuses: bonuses)
    }
}

enum DeathCause: Equatable, Sendable {
    case echo(index: Int, delay: TimeInterval)

    var echoIndex: Int? {
        switch self {
        case .echo(let index, _): index
        }
    }

    var headline: String {
        switch self {
        case .echo(let index, let delay):
            let seconds = Int(delay.rounded())
            return "You met echo \(index + 1)"
                + " — your path from \(seconds)s ago"
        }
    }
}

struct EchoThreat: Equatable, Sendable {
    var echoIndex: Int
    var distance: Double
    var eta: TimeInterval
    var willCollide: Bool
}

struct WorldSnapshot: Equatable, Sendable {
    var time: TimeInterval
    var player: Vec2
    var echoes: [Vec2]
    var sparkCollected: [Bool]
    var exitOpen: Bool
}
