import Foundation

struct LevelProgress: Equatable, Sendable, Codable {
    var stars: Int = 0
    var bestTime: TimeInterval?
    var bestMoves: Int?
}
