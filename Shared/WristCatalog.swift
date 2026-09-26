import Foundation

/// Rooms built for the wrist: a smaller, nearly square world, fewer
/// objectives and shorter runs, named after the parts and trials of a watch.
/// Three movements of twelve rooms tune the Keeper Chronometer: calibration,
/// regulation and certification. Shared with the phone so it can count clears
/// and grant rewards. Room IDs (`wrist-N`) are save data and never change.
enum WristCatalog {
    static let worldSize: Double = 700
    /// The three movements of the Keeper Chronometer.
    static var actTitles: [String] { (1...3).map { Copy.text("wrist.act\($0)") } }
    static let mapsPerAct = 12

    static let maps: [LevelDefinition] = calibration + regulation + certification

    static func map(id: String) -> LevelDefinition? {
        maps.first { $0.id == id }
    }

    static func act(of level: LevelDefinition) -> Int {
        max(0, min(actTitles.count - 1, (level.number - 1) / mapsPerAct))
    }

    /// The watch face is almost square; keep its stretch gentle.
    static func fitted(_ level: LevelDefinition, aspect: Double) -> LevelDefinition {
        level.fitted(aspect: aspect, range: 1.0...1.4)
    }

    static func room(
        _ number: Int,
        _ name: String,
        _ subtitle: String,
        start: Vec2,
        exit: Vec2,
        walls: [AABB] = [],
        sparks: [Vec2],
        bonuses: [BonusSpawn] = [],
        movers: [MoverSpawn] = [],
        gates: [TimeGateSpawn] = [],
        lasers: [LaserSpawn] = [],
        echoInterval: TimeInterval,
        maxEchoes: Int,
        par: TimeInterval,
        theme: ArenaTheme = .void
    ) -> LevelDefinition {
        room(
            number, name, subtitle,
            start: start, exit: exit, walls: walls,
            sparks: sparks.enumerated().map { SparkSpawn(id: $0.offset, position: $0.element) },
            bonuses: bonuses, movers: movers, gates: gates, lasers: lasers,
            echoInterval: echoInterval, maxEchoes: maxEchoes, par: par, theme: theme
        )
    }

    static func room(
        _ number: Int,
        _ name: String,
        _ subtitle: String,
        start: Vec2,
        exit: Vec2,
        walls: [AABB] = [],
        sparks: [SparkSpawn],
        bonuses: [BonusSpawn] = [],
        movers: [MoverSpawn] = [],
        gates: [TimeGateSpawn] = [],
        lasers: [LaserSpawn] = [],
        echoInterval: TimeInterval,
        maxEchoes: Int,
        par: TimeInterval,
        theme: ArenaTheme = .void
    ) -> LevelDefinition {
        LevelDefinition(
            id: "wrist-\(number)",
            number: number,
            name: name,
            subtitle: subtitle,
            worldSize: worldSize,
            worldHeight: worldSize,
            playerStart: start,
            exit: exit,
            walls: walls,
            sparks: sparks,
            bonuses: bonuses,
            fields: [],
            movers: movers,
            rifts: [],
            gates: gates,
            lasers: lasers,
            decorations: [],
            theme: theme,
            atmosphere: .clear,
            echoInterval: echoInterval,
            maxEchoes: maxEchoes,
            warningLead: 1.4,
            parTime: par,
            parMoves: 30,
            playerSpeed: 260,
            locked: false
        )
    }
}
