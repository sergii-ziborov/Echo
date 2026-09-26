import Foundation

/// One part of a rating: what was counted, how much each one is worth.
struct RatingLine: Identifiable, Equatable {
    /// The catalog key of the line's label, also its identity.
    let id: String
    let count: Int
    let weight: Int

    var points: Int { count * weight }
}

/// The two ratings: the campaign on iPhone and the rooms on Apple Watch.
/// Each is a plain sum of visible parts, so a player can see exactly what
/// raised it, and both only grow as records improve.
enum Ratings {
    static let sealPoints = 100
    static let depthPoints = 250
    static let passPoints = 1000
    static let roomPoints = 100
    static let parSecondPoints = 10

    @MainActor
    static func phone(_ progress: ProgressStore) -> [RatingLine] {
        [
            RatingLine(id: "records.line.seals", count: progress.lifetimeStars, weight: sealPoints),
            RatingLine(id: "records.line.depth", count: progress.endless.bestDepth, weight: depthPoints),
            RatingLine(id: "records.line.passes", count: progress.completedDifficultyCycles, weight: passPoints),
        ]
    }

    static func watch(_ wrist: WristProgress) -> [RatingLine] {
        [
            RatingLine(id: "records.line.rooms", count: clearedRooms(wrist).count, weight: roomPoints),
            RatingLine(id: "records.line.speed", count: secondsUnderPar(wrist), weight: parSecondPoints),
        ]
    }

    static func total(_ lines: [RatingLine]) -> Int {
        lines.reduce(0) { $0 + $1.points }
    }

    static func clearedRooms(_ wrist: WristProgress) -> [LevelDefinition] {
        WristCatalog.maps.filter { wrist.cleared.contains($0.id) }
    }

    /// Whole seconds the best times beat each cleared room's par, summed.
    static func secondsUnderPar(_ wrist: WristProgress) -> Int {
        let seconds = clearedRooms(wrist).reduce(0.0) { sum, room in
            sum + max(0, room.parTime - (wrist.bestTimes[room.id] ?? room.parTime))
        }
        return Int(seconds.rounded(.down))
    }
}
