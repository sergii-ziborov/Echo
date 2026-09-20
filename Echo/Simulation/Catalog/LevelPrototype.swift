import Foundation

extension LevelCatalog {
    /// The prototype the design brief asks to test first: one arena, six sparks, four echoes.
    static let prototype: LevelDefinition = make(
        number: 1,
        name: "Trace",
        subtitle: "Leave the center open for your future self.",
        playerStart: Vec2(x: 500, y: 140),
        exit: Vec2(x: 500, y: 500),
        walls: fourPillars(),
        sparks: [
            SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
            SparkSpawn(id: 1, position: Vec2(x: 220, y: 500), timer: 12),
            SparkSpawn(id: 2, position: Vec2(x: 780, y: 500)),
            SparkSpawn(id: 3, position: Vec2(x: 500, y: 780), timer: 16),
            SparkSpawn(id: 4, position: Vec2(x: 340, y: 340)),
            SparkSpawn(id: 5, position: Vec2(x: 660, y: 660), timer: 10),
        ],
        echoInterval: 8,
        maxEchoes: 4,
        parTime: 22,
        parMoves: 38,
        bonuses: [
            BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 160, y: 820)),
        ]
    )
}
