import Foundation

extension LevelCatalog {
    static let handcraftedPressure: [LevelDefinition] = [
        make(
            number: 19,
            name: "Needle",
            subtitle: "Thin lanes. Fat echoes.",
            playerStart: Vec2(x: 160, y: 500),
            exit: Vec2(x: 840, y: 500),
            walls: [
                AABB(x: 80, y: 80, width: 840, height: 40),
                AABB(x: 80, y: 880, width: 840, height: 40),
                AABB(x: 300, y: 200, width: 40, height: 240),
                AABB(x: 660, y: 560, width: 40, height: 240),
                AABB(x: 460, y: 360, width: 80, height: 280),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 200)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 800)),
            ],
            echoInterval: 6.1,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 64,
            playerSpeed: 345,
            bonuses: [
                BonusSpawn(id: 0, kind: .pulse, position: Vec2(x: 500, y: 500)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 160, y: 300)),
                BonusSpawn(id: 2, kind: .magnet, position: Vec2(x: 840, y: 700)),
            ]
        ),
        make(
            number: 20,
            name: "Storm",
            subtitle: "Everything moves. You still have to be still somewhere.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 300, y: 160, width: 80, height: 80),
                AABB(x: 620, y: 160, width: 80, height: 80),
                AABB(x: 300, y: 760, width: 80, height: 80),
                AABB(x: 620, y: 760, width: 80, height: 80),
                AABB(x: 460, y: 360, width: 80, height: 80),
                AABB(x: 200, y: 460, width: 70, height: 80),
                AABB(x: 730, y: 460, width: 70, height: 80),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 220, y: 220), timer: 12, orbit: SparkOrbit(center: Vec2(x: 220, y: 220), radius: 56, period: 5.5)),
                SparkSpawn(id: 2, position: Vec2(x: 780, y: 220), orbit: SparkOrbit(center: Vec2(x: 780, y: 220), radius: 56, period: 6.2)),
                SparkSpawn(id: 3, position: Vec2(x: 220, y: 780), orbit: SparkOrbit(center: Vec2(x: 220, y: 780), radius: 56, period: 7)),
                SparkSpawn(id: 4, position: Vec2(x: 780, y: 780), timer: 10, orbit: SparkOrbit(center: Vec2(x: 780, y: 780), radius: 56, period: 5)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 180), timer: 14),
            ],
            echoInterval: 6,
            maxEchoes: 5,
            parTime: 38,
            parMoves: 68,
            playerSpeed: 350,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 140, y: 140)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 860, y: 140)),
                BonusSpawn(id: 2, kind: .surge, position: Vec2(x: 140, y: 860)),
                BonusSpawn(id: 3, kind: .magnet, position: Vec2(x: 860, y: 860)),
                BonusSpawn(id: 4, kind: .pulse, position: Vec2(x: 500, y: 860)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 420, y: 620, width: 160, height: 120)),
            ],
            movers: [
                MoverSpawn.bounce(id: 0, at: Vec2(x: 360, y: 500), velocity: Vec2(x: 70, y: 55), radius: 20),
                MoverSpawn.orbit(id: 1, center: Vec2(x: 500, y: 500), radius: 195, period: 9, phase: 1.2, size: 18),
            ]
        ),
        make(
            number: 21,
            name: "Drift",
            subtitle: "Rocks do not care about your plan.",
            playerStart: Vec2(x: 160, y: 160),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 430, y: 120, width: 140, height: 40),
                AABB(x: 430, y: 840, width: 140, height: 40),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 500), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 200)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 800), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 780, y: 220)),
            ],
            echoInterval: 6.4,
            maxEchoes: 4,
            parTime: 34,
            parMoves: 58,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 160, y: 820)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 840, y: 160)),
            ],
            movers: [
                MoverSpawn.bounce(id: 0, at: Vec2(x: 700, y: 360), velocity: Vec2(x: -80, y: 60)),
                MoverSpawn.bounce(id: 1, at: Vec2(x: 300, y: 720), velocity: Vec2(x: 55, y: -75), radius: 18),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 500, y: 320), period: 8, openFor: 3.0),
            ],
            theme: .dust
        ),
        make(
            number: 22,
            name: "Belt",
            subtitle: "A patrol already owns the lane you want.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 860, y: 500),
            walls: [
                AABB(x: 280, y: 80, width: 52, height: 360),
                AABB(x: 668, y: 560, width: 52, height: 360),
                AABB(x: 440, y: 430, width: 120, height: 140),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820), timer: 10),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 220)),
            ],
            echoInterval: 6.3,
            maxEchoes: 4,
            parTime: 36,
            parMoves: 60,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 140, y: 140)),
                BonusSpawn(id: 1, kind: .pulse, position: Vec2(x: 860, y: 860)),
            ],
            movers: [
                MoverSpawn.patrol(id: 0, from: Vec2(x: 180, y: 520), to: Vec2(x: 620, y: 820), radius: 20),
                MoverSpawn.bounce(id: 1, at: Vec2(x: 500, y: 160), velocity: Vec2(x: 90, y: 0), radius: 16),
            ],
            theme: .ember
        ),
        make(
            number: 23,
            name: "Comet",
            subtitle: "The moon around the exit is not scenery.",
            playerStart: Vec2(x: 160, y: 840),
            exit: Vec2(x: 500, y: 500),
            walls: fourPillars(),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 220, y: 500), timer: 14),
                SparkSpawn(id: 2, position: Vec2(x: 780, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 220)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 780), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 300, y: 300)),
            ],
            echoInterval: 6.2,
            maxEchoes: 4,
            parTime: 34,
            parMoves: 58,
            bonuses: [
                BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 160, y: 160)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 840, y: 840)),
            ],
            movers: [
                MoverSpawn.orbit(id: 0, center: Vec2(x: 500, y: 500), radius: 170, period: 7.5, size: 22),
                MoverSpawn.orbit(id: 1, center: Vec2(x: 500, y: 500), radius: 250, period: 11, phase: 2.4, size: 16),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 180, y: 500), period: 7.5, openFor: 2.6, phase: 1.5),
            ],
            theme: .ice
        ),
        make(
            number: 24,
            name: "Crossfire",
            subtitle: "Two belts. One body.",
            playerStart: Vec2(x: 500, y: 120),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 80, y: 300, width: 200, height: 44),
                AABB(x: 720, y: 656, width: 200, height: 44),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820), timer: 10),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 780)),
            ],
            echoInterval: 6.1,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 220)),
                BonusSpawn(id: 1, kind: .surge, position: Vec2(x: 160, y: 500)),
                BonusSpawn(id: 2, kind: .freeze, position: Vec2(x: 840, y: 500)),
            ],
            movers: [
                MoverSpawn.patrol(id: 0, from: Vec2(x: 160, y: 400), to: Vec2(x: 840, y: 400)),
                MoverSpawn.patrol(id: 1, from: Vec2(x: 160, y: 600), to: Vec2(x: 840, y: 600)),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .collision, position: Vec2(x: 500, y: 300), period: 6.5, openFor: 2.2),
            ],
            theme: .ion
        ),
    ]
}
