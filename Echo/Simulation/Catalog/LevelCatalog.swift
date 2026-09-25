import Foundation

enum LevelCatalog {
    static let worldName = "Awakening"
    static let worldTagline = "You don't cooperate with your past. You survive it."

    static let all: [LevelDefinition] = playable

    static func level(id: String) -> LevelDefinition? {
        all.first { $0.id == id }
    }

    static func level(number: Int) -> LevelDefinition? {
        all.first { $0.number == number }
    }

    static let playable: [LevelDefinition] = (handcrafted + (37...77).map(expandedLevel))
        .map { $0.assigningAsteroidMaterials().withReadableAsteroids().inRegion() }
}
