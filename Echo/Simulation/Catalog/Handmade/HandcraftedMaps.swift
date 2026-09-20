import Foundation

extension LevelCatalog {
    static var handcrafted: [LevelDefinition] {
        [prototype] + handcraftedEarly + handcraftedMid + handcraftedPressure + handcraftedLate + handcraftedCore
    }
}
