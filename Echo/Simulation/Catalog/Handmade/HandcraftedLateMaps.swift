import Foundation

extension LevelCatalog {
    static let handcraftedLate: [LevelDefinition] = [
        make(
            number: 25,
            name: "Debris",
            subtitle: "Small rocks. Bad timing.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 860, y: 500),
            walls: [
                AABB(x: 460, y: 80, width: 80, height: 220),
                AABB(x: 460, y: 700, width: 80, height: 220),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 200), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 200)),
                SparkSpawn(id: 3, position: Vec2(x: 200, y: 800)),
                SparkSpawn(id: 4, position: Vec2(x: 800, y: 800), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 300)),
            ],
            echoInterval: 6.2,
            maxEchoes: 4,
            parTime: 36,
            parMoves: 64,
            bonuses: [
                BonusSpawn(id: 0, kind: .magnet, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 500, y: 860)),
            ],
            movers: [
                MoverSpawn.bounce(id: 0, at: Vec2(x: 280, y: 300), velocity: Vec2(x: 70, y: 80), radius: 16),
                MoverSpawn.bounce(id: 1, at: Vec2(x: 720, y: 700), velocity: Vec2(x: -85, y: -50), radius: 16),
                MoverSpawn.bounce(id: 2, at: Vec2(x: 300, y: 760), velocity: Vec2(x: 40, y: -90), radius: 14),
                MoverSpawn.bounce(id: 3, at: Vec2(x: 760, y: 240), velocity: Vec2(x: -60, y: 70), radius: 14),
            ],
            theme: .dust
        ),
        make(
            number: 26,
            name: "Emberwake",
            subtitle: "The mire and the rock share a shift.",
            playerStart: Vec2(x: 160, y: 160),
            exit: Vec2(x: 840, y: 840),
            walls: [
                AABB(x: 80, y: 360, width: 280, height: 48),
                AABB(x: 640, y: 592, width: 280, height: 48),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 500), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 200)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 800), timer: 10),
                SparkSpawn(id: 5, position: Vec2(x: 300, y: 780)),
            ],
            echoInterval: 6.1,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 840, y: 160)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 360, y: 360, width: 280, height: 280)),
            ],
            movers: [
                MoverSpawn.patrol(id: 0, from: Vec2(x: 420, y: 160), to: Vec2(x: 580, y: 840), radius: 22),
            ],
            theme: .ember
        ),
        make(
            number: 27,
            name: "Frostlane",
            subtitle: "Freeze the rock, then spend the quiet.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 860, y: 500),
            walls: [
                AABB(x: 300, y: 200, width: 48, height: 600),
                AABB(x: 652, y: 200, width: 48, height: 600),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 200), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 200)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 800)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 800), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 220)),
            ],
            echoInterval: 6.3,
            maxEchoes: 4,
            parTime: 34,
            parMoves: 60,
            bonuses: [
                BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 500, y: 860)),
                BonusSpawn(id: 2, kind: .shield, position: Vec2(x: 140, y: 140)),
            ],
            movers: [
                MoverSpawn.orbit(id: 0, center: Vec2(x: 500, y: 500), radius: 120, period: 6.5, size: 20),
                MoverSpawn.bounce(id: 1, at: Vec2(x: 180, y: 300), velocity: Vec2(x: 0, y: 95), radius: 16),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 500, y: 720), period: 6.8, openFor: 2.8),
            ],
            theme: .ice
        ),
        make(
            number: 28,
            name: "Magnetar",
            subtitle: "Pull the sparks. Dodge the rock.",
            playerStart: Vec2(x: 500, y: 140),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 140, y: 140, width: 120, height: 120),
                AABB(x: 740, y: 140, width: 120, height: 120),
                AABB(x: 140, y: 740, width: 120, height: 120),
                AABB(x: 740, y: 740, width: 120, height: 120),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 220, y: 500), timer: 12, orbit: SparkOrbit(center: Vec2(x: 220, y: 500), radius: 48, period: 5)),
                SparkSpawn(id: 2, position: Vec2(x: 780, y: 500), orbit: SparkOrbit(center: Vec2(x: 780, y: 500), radius: 48, period: 5.5)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 780), timer: 10),
                SparkSpawn(id: 4, position: Vec2(x: 340, y: 340)),
                SparkSpawn(id: 5, position: Vec2(x: 660, y: 660)),
            ],
            echoInterval: 6.1,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .magnet, position: Vec2(x: 500, y: 220)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 160, y: 500)),
                BonusSpawn(id: 2, kind: .pulse, position: Vec2(x: 840, y: 500)),
            ],
            movers: [
                MoverSpawn.bounce(id: 0, at: Vec2(x: 400, y: 700), velocity: Vec2(x: 75, y: -60)),
                MoverSpawn.bounce(id: 1, at: Vec2(x: 640, y: 280), velocity: Vec2(x: -50, y: 80), radius: 18),
            ],
            theme: .ion
        ),
        make(
            number: 29,
            name: "Sluice",
            subtitle: "Green water. Grey rock. Same delay.",
            playerStart: Vec2(x: 180, y: 180),
            exit: Vec2(x: 820, y: 820),
            walls: [
                AABB(x: 80, y: 320, width: 520, height: 48),
                AABB(x: 400, y: 632, width: 520, height: 48),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 500), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 180)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 820), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 300, y: 700)),
            ],
            echoInterval: 6.2,
            maxEchoes: 4,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 180, y: 820)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 820, y: 180)),
            ],
            movers: [
                MoverSpawn.patrol(id: 0, from: Vec2(x: 200, y: 250), to: Vec2(x: 800, y: 250)),
                MoverSpawn.patrol(id: 1, from: Vec2(x: 200, y: 750), to: Vec2(x: 800, y: 750)),
            ],
            theme: .moss
        ),
        make(
            number: 30,
            name: "Gauntlet",
            subtitle: "Echoes, rocks, mire. Leave a gap anyway.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 500, y: 500),
            walls: corridorWalls(),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180), orbit: SparkOrbit(center: Vec2(x: 820, y: 180), radius: 44, period: 6)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820), timer: 10),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 300), timer: 14),
            ],
            echoInterval: 6,
            maxEchoes: 5,
            parTime: 38,
            parMoves: 68,
            playerSpeed: 345,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 140, y: 300)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 860, y: 500)),
                BonusSpawn(id: 2, kind: .surge, position: Vec2(x: 500, y: 860)),
                BonusSpawn(id: 3, kind: .magnet, position: Vec2(x: 500, y: 140)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 420, y: 420, width: 160, height: 160)),
            ],
            movers: [
                MoverSpawn.bounce(id: 0, at: Vec2(x: 220, y: 400), velocity: Vec2(x: 40, y: 85), radius: 18),
                MoverSpawn.patrol(id: 1, from: Vec2(x: 380, y: 300), to: Vec2(x: 620, y: 300), radius: 20),
                MoverSpawn.patrol(id: 2, from: Vec2(x: 400, y: 840), to: Vec2(x: 600, y: 160), radius: 16),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .collision, position: Vec2(x: 500, y: 720), period: 7.2, openFor: 2.4, phase: 1.0),
                RiftSpawn(id: 1, kind: .calm, position: Vec2(x: 200, y: 240), period: 8, openFor: 3.0),
            ],
            theme: .ember
        ),
    ]
}
