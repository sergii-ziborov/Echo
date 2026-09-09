import Foundation

struct SparkSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
    var timer: TimeInterval? = nil
    var orbit: SparkOrbit? = nil
}

struct LevelDefinition: Equatable, Sendable, Identifiable {
    var id: String
    var number: Int
    var name: String
    var subtitle: String
    var worldSize: Double
    var worldHeight: Double
    var playerStart: Vec2
    var exit: Vec2
    var walls: [AABB]
    var sparks: [SparkSpawn]
    var bonuses: [BonusSpawn]
    var fields: [SlowField]
    var movers: [MoverSpawn]
    var rifts: [RiftSpawn]
    var gates: [TimeGateSpawn]
    var theme: ArenaTheme
    var echoInterval: TimeInterval
    var maxEchoes: Int
    var warningLead: TimeInterval
    var parTime: TimeInterval
    var parMoves: Int
    var playerSpeed: Double
    var locked: Bool

    var sparkCount: Int { sparks.count }
    var worldWidth: Double { worldSize }

    static let worldSize: Double = 1000

    /// Stretch the 1000×1000 layout to the screen aspect so the arena fills the phone.
    func fitted(aspect: Double) -> LevelDefinition {
        let a = min(max(aspect, 1.45), 2.25)
        let height = Self.worldSize * a
        let sy = height / Self.worldSize
        var copy = self
        copy.worldHeight = height
        copy.playerStart = Vec2(x: playerStart.x, y: playerStart.y * sy)
        copy.exit = Vec2(x: exit.x, y: exit.y * sy)
        copy.walls = walls.map {
            AABB(minX: $0.minX, minY: $0.minY * sy, maxX: $0.maxX, maxY: $0.maxY * sy)
        }
        copy.sparks = sparks.map {
            var orbit = $0.orbit
            if var ring = orbit {
                ring.center = Vec2(x: ring.center.x, y: ring.center.y * sy)
                orbit = ring
            }
            return SparkSpawn(
                id: $0.id,
                position: Vec2(x: $0.position.x, y: $0.position.y * sy),
                timer: $0.timer,
                orbit: orbit
            )
        }
        copy.bonuses = bonuses.map {
            BonusSpawn(id: $0.id, kind: $0.kind, position: Vec2(x: $0.position.x, y: $0.position.y * sy))
        }
        copy.fields = fields.map {
            SlowField(
                id: $0.id,
                area: AABB(minX: $0.area.minX, minY: $0.area.minY * sy, maxX: $0.area.maxX, maxY: $0.area.maxY * sy)
            )
        }
        copy.movers = movers.map { $0.scaled(sy: sy) }
        copy.rifts = rifts.map {
            RiftSpawn(
                id: $0.id,
                kind: $0.kind,
                position: Vec2(x: $0.position.x, y: $0.position.y * sy),
                radius: $0.radius,
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
        copy.gates = gates.map {
            TimeGateSpawn(
                id: $0.id,
                area: AABB(minX: $0.area.minX, minY: $0.area.minY * sy, maxX: $0.area.maxX, maxY: $0.area.maxY * sy),
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
        return copy.sanitized()
    }

    /// Push sparks, the exit, and the start out of walls so pickups are always reachable.
    func sanitized(clearance: Double = 34) -> LevelDefinition {
        var copy = self
        copy.playerStart = LayoutSafety.nudge(playerStart, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: clearance)
        copy.exit = LayoutSafety.nudge(exit, walls: walls, worldWidth: worldWidth, worldHeight: worldHeight, clearance: clearance + 8)
        copy.sparks = sparks.map { spark in
            var next = spark
            if var ring = spark.orbit {
                ring.center = LayoutSafety.nudge(
                    ring.center,
                    walls: walls,
                    worldWidth: worldWidth,
                    worldHeight: worldHeight,
                    clearance: clearance + ring.radius
                )
                next.orbit = ring
                next.position = ring.center
            } else {
                next.position = LayoutSafety.nudge(
                    spark.position,
                    walls: walls,
                    worldWidth: worldWidth,
                    worldHeight: worldHeight,
                    clearance: clearance
                )
            }
            return next
        }
        copy.bonuses = bonuses.map { bonus in
            var next = bonus
            next.position = LayoutSafety.nudge(
                bonus.position,
                walls: walls,
                worldWidth: worldWidth,
                worldHeight: worldHeight,
                clearance: clearance
            )
            return next
        }
        return copy
    }
}

enum LayoutSafety {
    static func nudge(
        _ point: Vec2,
        walls: [AABB],
        worldWidth: Double,
        worldHeight: Double,
        clearance: Double
    ) -> Vec2 {
        var p = point.clamped(
            minX: clearance + 24,
            minY: clearance + 24,
            maxX: worldWidth - clearance - 24,
            maxY: worldHeight - clearance - 24
        )
        for _ in 0..<8 {
            var moved = false
            for wall in walls {
                let box = wall.expanded(clearance)
                if box.intersectsCircle(center: p, radius: 1) {
                    p = CircleMath.resolve(center: p, radius: clearance, box: wall)
                    p = p.clamped(
                        minX: clearance + 24,
                        minY: clearance + 24,
                        maxX: worldWidth - clearance - 24,
                        maxY: worldHeight - clearance - 24
                    )
                    moved = true
                }
            }
            if !moved { break }
        }
        return p
    }

    static func isClear(
        _ point: Vec2,
        walls: [AABB],
        clearance: Double
    ) -> Bool {
        walls.allSatisfy { !$0.expanded(clearance).intersectsCircle(center: point, radius: 1) }
    }
}

enum LevelCatalog {
    static let worldName = "Awakening"
    static let worldTagline = "You don't cooperate with your past. You survive it."

    static func seals(for number: Int) -> (control: SealKind, paradox: SealKind) {
        switch number {
        case 1: (.beforeEcho(3), .noDash)
        case 2: (.noDash, .parTime)
        case 3: (.maxEchoes(3), .parTime)
        case 4: (.useRift, .noShop)
        case 5: (.beforeEcho(4), .parTime)
        case 6: (.noDash, .maxEchoes(3))
        case 7: (.noShop, .parTime)
        case 8: (.maxEchoes(3), .noDash)
        case 9: (.parTime, .noShop)
        case 10: (.beforeEcho(4), .noDash)
        case 11: (.maxEchoes(3), .parTime)
        case 12: (.noShop, .avoidScar)
        case 13: (.useRift, .parTime)
        case 14: (.causeScar, .noShop)
        case 15: (.avoidScar, .parTime)
        case 16: (.useRift, .noDash)
        case 17: (.useRift, .parTime)
        case 18: (.causeScar, .noShop)
        case 19: (.noShop, .parTime)
        case 20: (.avoidScar, .noDash)
        case 21: (.maxEchoes(4), .parTime)
        case 22: (.noShop, .avoidScar)
        case 23: (.noDash, .parTime)
        case 24: (.avoidScar, .maxEchoes(4))
        case 25: (.causeScar, .parTime)
        case 26: (.noShop, .maxEchoes(4))
        case 27: (.avoidScar, .parTime)
        case 28: (.causeScar, .noDash)
        case 29: (.useRift, .noShop)
        case 30: (.noShop, .parTime)
        default: (.parTime, .noDash)
        }
    }

    static let all: [LevelDefinition] = playable

    static func level(id: String) -> LevelDefinition? {
        all.first { $0.id == id }
    }

    static func level(number: Int) -> LevelDefinition? {
        all.first { $0.number == number }
    }

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

    static let playable: [LevelDefinition] = [
        prototype,
        make(
            number: 2,
            name: "Corridor",
            subtitle: "The long way around is not always safer.",
            playerStart: Vec2(x: 180, y: 180),
            exit: Vec2(x: 500, y: 500),
            walls: corridorWalls(),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 820, y: 180), timer: 14),
                SparkSpawn(id: 2, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 3, position: Vec2(x: 820, y: 820), timer: 11),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 280)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 720)),
            ],
            echoInterval: 7.5,
            maxEchoes: 4,
            parTime: 24,
            parMoves: 42,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .magnet, position: Vec2(x: 500, y: 860)),
            ]
        ),
        make(
            number: 3,
            name: "Cross",
            subtitle: "Your first loop will cut the second.",
            playerStart: Vec2(x: 500, y: 120),
            exit: Vec2(x: 500, y: 500),
            walls: crossWalls(),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 500), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 800), timer: 9),
                SparkSpawn(id: 4, position: Vec2(x: 280, y: 280)),
                SparkSpawn(id: 5, position: Vec2(x: 720, y: 720), timer: 15),
            ],
            echoInterval: 7,
            maxEchoes: 4,
            parTime: 26,
            parMoves: 44,
            bonuses: [
                BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 160, y: 160)),
                BonusSpawn(id: 1, kind: .pulse, position: Vec2(x: 840, y: 840)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 430, y: 430, width: 140, height: 140)),
            ]
        ),
        make(
            number: 4,
            name: "Afterimage",
            subtitle: "Four copies. No empty air.",
            playerStart: Vec2(x: 160, y: 500),
            exit: Vec2(x: 500, y: 500),
            walls: fourPillars() + [
                AABB(x: 430, y: 200, width: 140, height: 36),
                AABB(x: 430, y: 764, width: 140, height: 36),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 840, y: 500), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 500, y: 160)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 840), timer: 10),
                SparkSpawn(id: 4, position: Vec2(x: 300, y: 300)),
                SparkSpawn(id: 5, position: Vec2(x: 700, y: 700), timer: 16),
            ],
            echoInterval: 6.5,
            maxEchoes: 4,
            parTime: 28,
            parMoves: 48,
            playerSpeed: 340,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 300)),
                BonusSpawn(id: 1, kind: .surge, position: Vec2(x: 500, y: 700)),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 300, y: 500), period: 8, openFor: 3.2, phase: 1.0),
            ]
        ),
        make(
            number: 5,
            name: "Orbit",
            subtitle: "Sparks refuse to sit still.",
            playerStart: Vec2(x: 160, y: 160),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 120, y: 420, width: 180, height: 160),
                AABB(x: 700, y: 420, width: 180, height: 160),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 280, y: 280), timer: 14, orbit: SparkOrbit(center: Vec2(x: 280, y: 280), radius: 70, period: 5.5)),
                SparkSpawn(id: 2, position: Vec2(x: 720, y: 280), orbit: SparkOrbit(center: Vec2(x: 720, y: 280), radius: 70, period: 6.5)),
                SparkSpawn(id: 3, position: Vec2(x: 280, y: 720), orbit: SparkOrbit(center: Vec2(x: 280, y: 720), radius: 70, period: 7)),
                SparkSpawn(id: 4, position: Vec2(x: 720, y: 720), timer: 12, orbit: SparkOrbit(center: Vec2(x: 720, y: 720), radius: 70, period: 5)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 180), timer: 16),
            ],
            echoInterval: 7.2,
            maxEchoes: 4,
            parTime: 30,
            parMoves: 50,
            bonuses: [
                BonusSpawn(id: 0, kind: .magnet, position: Vec2(x: 500, y: 820)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 160, y: 500)),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .calm, position: Vec2(x: 500, y: 700), period: 7.5, openFor: 2.8),
            ]
        ),
        make(
            number: 6,
            name: "Mire",
            subtitle: "The middle of the arena steals your speed.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 860, y: 500),
            walls: [
                AABB(x: 220, y: 80, width: 70, height: 280),
                AABB(x: 710, y: 640, width: 70, height: 280),
                AABB(x: 440, y: 200, width: 120, height: 50),
                AABB(x: 440, y: 750, width: 120, height: 50),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 300)),
            ],
            echoInterval: 7,
            maxEchoes: 4,
            parTime: 32,
            parMoves: 52,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 500, y: 860)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 360, y: 360, width: 280, height: 280)),
            ]
        ),
        make(
            number: 7,
            name: "Vault",
            subtitle: "Take the shield before you cut the first loop.",
            playerStart: Vec2(x: 500, y: 120),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 80, y: 300, width: 280, height: 54),
                AABB(x: 640, y: 300, width: 280, height: 54),
                AABB(x: 80, y: 646, width: 280, height: 54),
                AABB(x: 640, y: 646, width: 280, height: 54),
                AABB(x: 458, y: 160, width: 84, height: 200),
                AABB(x: 458, y: 640, width: 84, height: 200),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 160, y: 160), timer: 15),
                SparkSpawn(id: 2, position: Vec2(x: 840, y: 160)),
                SparkSpawn(id: 3, position: Vec2(x: 160, y: 840)),
                SparkSpawn(id: 4, position: Vec2(x: 840, y: 840), timer: 12),
                SparkSpawn(id: 5, position: Vec2(x: 240, y: 500)),
            ],
            echoInterval: 6.8,
            maxEchoes: 4,
            parTime: 30,
            parMoves: 54,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 220)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 500, y: 780)),
                BonusSpawn(id: 2, kind: .pulse, position: Vec2(x: 760, y: 500)),
            ]
        ),
        make(
            number: 8,
            name: "Twin",
            subtitle: "Two rooms. One recorded life.",
            playerStart: Vec2(x: 180, y: 500),
            exit: Vec2(x: 820, y: 500),
            walls: [
                AABB(x: 460, y: 80, width: 80, height: 340),
                AABB(x: 460, y: 580, width: 80, height: 340),
                AABB(x: 120, y: 200, width: 200, height: 48),
                AABB(x: 680, y: 752, width: 200, height: 48),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 220, y: 320)),
                SparkSpawn(id: 1, position: Vec2(x: 220, y: 700), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 780, y: 320)),
                SparkSpawn(id: 3, position: Vec2(x: 780, y: 700), timer: 11),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 180)),
            ],
            echoInterval: 6.6,
            maxEchoes: 4,
            parTime: 32,
            parMoves: 56,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 180, y: 180)),
                BonusSpawn(id: 1, kind: .magnet, position: Vec2(x: 820, y: 820)),
            ],
            gates: [
                TimeGateSpawn(id: 0, area: AABB(x: 460, y: 420, width: 80, height: 160), period: 5.2, openFor: 2.3),
            ]
        ),
        make(
            number: 9,
            name: "Switchback",
            subtitle: "A pretty zigzag is a future wall.",
            playerStart: Vec2(x: 140, y: 140),
            exit: Vec2(x: 860, y: 860),
            walls: [
                AABB(x: 220, y: 220, width: 520, height: 48),
                AABB(x: 260, y: 460, width: 520, height: 48),
                AABB(x: 220, y: 700, width: 520, height: 48),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 140)),
                SparkSpawn(id: 1, position: Vec2(x: 140, y: 360), timer: 14),
                SparkSpawn(id: 2, position: Vec2(x: 860, y: 360)),
                SparkSpawn(id: 3, position: Vec2(x: 140, y: 600)),
                SparkSpawn(id: 4, position: Vec2(x: 860, y: 600), timer: 12),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 860)),
            ],
            echoInterval: 6.4,
            maxEchoes: 5,
            parTime: 34,
            parMoves: 60,
            bonuses: [
                BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 500, y: 360)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 500, y: 600)),
                BonusSpawn(id: 2, kind: .pulse, position: Vec2(x: 500, y: 820)),
            ],
            gates: [
                TimeGateSpawn(id: 0, area: AABB(x: 80, y: 460, width: 180, height: 48), period: 4.8, openFor: 2.1, phase: 0.8),
            ]
        ),
        make(
            number: 10,
            name: "Lattice",
            subtitle: "Leave gaps. You will need them twice.",
            playerStart: Vec2(x: 120, y: 500),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 250, y: 180, width: 90, height: 90),
                AABB(x: 460, y: 180, width: 90, height: 90),
                AABB(x: 670, y: 180, width: 90, height: 90),
                AABB(x: 250, y: 455, width: 90, height: 90),
                AABB(x: 670, y: 455, width: 90, height: 90),
                AABB(x: 250, y: 730, width: 90, height: 90),
                AABB(x: 460, y: 730, width: 90, height: 90),
                AABB(x: 670, y: 730, width: 90, height: 90),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820), timer: 10),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 320), orbit: SparkOrbit(center: Vec2(x: 500, y: 320), radius: 55, period: 6)),
            ],
            echoInterval: 6.5,
            maxEchoes: 5,
            parTime: 34,
            parMoves: 58,
            bonuses: [
                BonusSpawn(id: 0, kind: .magnet, position: Vec2(x: 500, y: 860)),
                BonusSpawn(id: 1, kind: .surge, position: Vec2(x: 880, y: 500)),
                BonusSpawn(id: 2, kind: .freeze, position: Vec2(x: 120, y: 820)),
            ]
        ),
        make(
            number: 11,
            name: "Bloom",
            subtitle: "Spend bonuses like extra lives. They are.",
            playerStart: Vec2(x: 500, y: 120),
            exit: Vec2(x: 500, y: 500),
            walls: fourPillars(),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 500), timer: 11, orbit: SparkOrbit(center: Vec2(x: 200, y: 500), radius: 50, period: 5)),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 500), orbit: SparkOrbit(center: Vec2(x: 800, y: 500), radius: 50, period: 5.5)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 800), timer: 13),
                SparkSpawn(id: 4, position: Vec2(x: 340, y: 340)),
                SparkSpawn(id: 5, position: Vec2(x: 660, y: 660), timer: 9),
            ],
            echoInterval: 6.2,
            maxEchoes: 5,
            parTime: 32,
            parMoves: 55,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 160, y: 160)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 840, y: 160)),
                BonusSpawn(id: 2, kind: .freeze, position: Vec2(x: 160, y: 840)),
                BonusSpawn(id: 3, kind: .pulse, position: Vec2(x: 840, y: 840)),
                BonusSpawn(id: 4, kind: .surge, position: Vec2(x: 500, y: 220)),
            ]
        ),
        make(
            number: 12,
            name: "Overload",
            subtitle: "Five copies. Every bonus. No empty air.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 500, y: 500),
            walls: corridorWalls() + [
                AABB(x: 430, y: 160, width: 140, height: 36),
                AABB(x: 430, y: 804, width: 140, height: 36),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180), orbit: SparkOrbit(center: Vec2(x: 820, y: 180), radius: 48, period: 6)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820), timer: 10),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 300), timer: 14),
            ],
            echoInterval: 6,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 64,
            playerSpeed: 350,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 140, y: 300)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 860, y: 500)),
                BonusSpawn(id: 2, kind: .surge, position: Vec2(x: 500, y: 860)),
                BonusSpawn(id: 3, kind: .magnet, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 4, kind: .pulse, position: Vec2(x: 140, y: 700)),
            ],
            fields: [
                SlowField(id: 0, area: AABB(x: 420, y: 420, width: 160, height: 160)),
            ]
        ),
        make(
            number: 13,
            name: "Fork",
            subtitle: "Pick a branch. You will walk the other later.",
            playerStart: Vec2(x: 500, y: 120),
            exit: Vec2(x: 500, y: 820),
            walls: [
                AABB(x: 120, y: 280, width: 280, height: 52),
                AABB(x: 600, y: 280, width: 280, height: 52),
                AABB(x: 360, y: 280, width: 52, height: 280),
                AABB(x: 588, y: 440, width: 52, height: 280),
                AABB(x: 200, y: 700, width: 240, height: 48),
                AABB(x: 560, y: 700, width: 240, height: 48),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 180, y: 180), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 180, y: 820), timer: 11),
                SparkSpawn(id: 4, position: Vec2(x: 820, y: 820)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 360)),
            ],
            echoInterval: 6.4,
            maxEchoes: 4,
            parTime: 34,
            parMoves: 58,
            bonuses: [
                BonusSpawn(id: 0, kind: .pulse, position: Vec2(x: 500, y: 220)),
                BonusSpawn(id: 1, kind: .shield, position: Vec2(x: 500, y: 860)),
            ]
        ),
        make(
            number: 14,
            name: "Slalom",
            subtitle: "Offset gates. Your return path is already taken.",
            playerStart: Vec2(x: 140, y: 500),
            exit: Vec2(x: 860, y: 500),
            walls: [
                AABB(x: 250, y: 80, width: 56, height: 420),
                AABB(x: 470, y: 500, width: 56, height: 420),
                AABB(x: 690, y: 80, width: 56, height: 420),
                AABB(x: 360, y: 760, width: 90, height: 90),
                AABB(x: 560, y: 150, width: 90, height: 90),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 160, y: 180), timer: 14),
                SparkSpawn(id: 2, position: Vec2(x: 840, y: 180)),
                SparkSpawn(id: 3, position: Vec2(x: 160, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 840, y: 820), timer: 12),
                SparkSpawn(id: 5, position: Vec2(x: 360, y: 360)),
            ],
            echoInterval: 6.3,
            maxEchoes: 4,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 140, y: 140)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 860, y: 860)),
                BonusSpawn(id: 2, kind: .magnet, position: Vec2(x: 500, y: 140)),
            ]
        ),
        make(
            number: 15,
            name: "Harbor",
            subtitle: "A U you will have to leave twice.",
            playerStart: Vec2(x: 180, y: 180),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 80, y: 80, width: 48, height: 620),
                AABB(x: 80, y: 652, width: 840, height: 48),
                AABB(x: 872, y: 80, width: 48, height: 620),
                AABB(x: 280, y: 280, width: 440, height: 48),
                AABB(x: 280, y: 280, width: 48, height: 260),
                AABB(x: 672, y: 280, width: 48, height: 260),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 200), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 200)),
                SparkSpawn(id: 3, position: Vec2(x: 200, y: 780)),
                SparkSpawn(id: 4, position: Vec2(x: 800, y: 780), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 180), timer: 15),
            ],
            echoInterval: 6.5,
            maxEchoes: 4,
            parTime: 34,
            parMoves: 60,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 780)),
                BonusSpawn(id: 1, kind: .pulse, position: Vec2(x: 180, y: 500)),
            ]
        ),
        make(
            number: 16,
            name: "Well",
            subtitle: "Gaps on opposite walls. Remember which.",
            playerStart: Vec2(x: 140, y: 140),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 220, y: 220, width: 240, height: 44),
                AABB(x: 540, y: 220, width: 240, height: 44),
                AABB(x: 220, y: 220, width: 44, height: 240),
                AABB(x: 736, y: 540, width: 44, height: 240),
                AABB(x: 220, y: 736, width: 240, height: 44),
                AABB(x: 540, y: 736, width: 240, height: 44),
                AABB(x: 360, y: 360, width: 44, height: 140),
                AABB(x: 596, y: 500, width: 44, height: 140),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 140, y: 500), timer: 14),
                SparkSpawn(id: 2, position: Vec2(x: 860, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 140)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 860), timer: 12),
                SparkSpawn(id: 5, position: Vec2(x: 300, y: 300)),
            ],
            echoInterval: 6.2,
            maxEchoes: 5,
            parTime: 36,
            parMoves: 64,
            bonuses: [
                BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 140, y: 860)),
                BonusSpawn(id: 1, kind: .surge, position: Vec2(x: 860, y: 140)),
                BonusSpawn(id: 2, kind: .shield, position: Vec2(x: 500, y: 300)),
            ]
        ),
        make(
            number: 17,
            name: "Ridge",
            subtitle: "Steps you climb become walls on the way down.",
            playerStart: Vec2(x: 140, y: 860),
            exit: Vec2(x: 860, y: 140),
            walls: [
                AABB(x: 80, y: 700, width: 280, height: 48),
                AABB(x: 280, y: 540, width: 280, height: 48),
                AABB(x: 480, y: 380, width: 280, height: 48),
                AABB(x: 640, y: 220, width: 280, height: 48),
                AABB(x: 420, y: 800, width: 90, height: 90),
                AABB(x: 200, y: 300, width: 90, height: 90),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 160, y: 160), timer: 13),
                SparkSpawn(id: 2, position: Vec2(x: 840, y: 160)),
                SparkSpawn(id: 3, position: Vec2(x: 160, y: 620)),
                SparkSpawn(id: 4, position: Vec2(x: 840, y: 820), timer: 11),
                SparkSpawn(id: 5, position: Vec2(x: 700, y: 500)),
            ],
            echoInterval: 6.4,
            maxEchoes: 4,
            parTime: 36,
            parMoves: 62,
            bonuses: [
                BonusSpawn(id: 0, kind: .magnet, position: Vec2(x: 500, y: 140)),
                BonusSpawn(id: 1, kind: .pulse, position: Vec2(x: 500, y: 860)),
            ]
        ),
        make(
            number: 18,
            name: "Clover",
            subtitle: "Four pockets. One recorded life.",
            playerStart: Vec2(x: 500, y: 140),
            exit: Vec2(x: 500, y: 500),
            walls: [
                AABB(x: 140, y: 140, width: 160, height: 160),
                AABB(x: 700, y: 140, width: 160, height: 160),
                AABB(x: 140, y: 700, width: 160, height: 160),
                AABB(x: 700, y: 700, width: 160, height: 160),
                AABB(x: 430, y: 250, width: 140, height: 40),
                AABB(x: 430, y: 710, width: 140, height: 40),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 500, y: 500)),
                SparkSpawn(id: 1, position: Vec2(x: 220, y: 500), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 780, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 220)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 780), timer: 10),
                SparkSpawn(id: 5, position: Vec2(x: 340, y: 340), orbit: SparkOrbit(center: Vec2(x: 340, y: 340), radius: 48, period: 6)),
            ],
            echoInterval: 6.3,
            maxEchoes: 5,
            parTime: 34,
            parMoves: 60,
            bonuses: [
                BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 500, y: 300)),
                BonusSpawn(id: 1, kind: .freeze, position: Vec2(x: 180, y: 500)),
                BonusSpawn(id: 2, kind: .surge, position: Vec2(x: 820, y: 500)),
            ]
        ),
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
                MoverSpawn.orbit(id: 1, center: Vec2(x: 500, y: 500), radius: 210, period: 9, phase: 1.2, size: 18),
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
                MoverSpawn.patrol(id: 0, from: Vec2(x: 200, y: 280), to: Vec2(x: 800, y: 720), radius: 20),
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
                MoverSpawn.patrol(id: 1, from: Vec2(x: 160, y: 620), to: Vec2(x: 840, y: 620)),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .collision, position: Vec2(x: 500, y: 300), period: 6.5, openFor: 2.2),
            ],
            theme: .ion
        ),
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
                MoverSpawn.patrol(id: 0, from: Vec2(x: 180, y: 260), to: Vec2(x: 820, y: 740), radius: 22),
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
                MoverSpawn.orbit(id: 0, center: Vec2(x: 500, y: 500), radius: 140, period: 6.5, size: 20),
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
                MoverSpawn.orbit(id: 1, center: Vec2(x: 500, y: 500), radius: 190, period: 8.5, phase: 0.6, size: 20),
                MoverSpawn.patrol(id: 2, from: Vec2(x: 160, y: 860), to: Vec2(x: 840, y: 140), radius: 16),
            ],
            rifts: [
                RiftSpawn(id: 0, kind: .collision, position: Vec2(x: 500, y: 720), period: 7.2, openFor: 2.4, phase: 1.0),
                RiftSpawn(id: 1, kind: .calm, position: Vec2(x: 240, y: 240), period: 8, openFor: 3.0),
            ],
            theme: .ember
        ),
    ]

    static func daily(on day: Date = Date(), calendar: Calendar = .current) -> LevelDefinition {
        let start = calendar.startOfDay(for: day)
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let dayNum = calendar.component(.day, from: start)
        let seed = UInt64(year) * 10_000 + UInt64(month) * 100 + UInt64(dayNum)
        var rng = SplitMix64(seed: seed)

        let templates = [1, 3, 8, 13, 16, 21, 25, 30]
        let pick = templates[Int(rng.next() % UInt64(templates.count))]
        var level = playable.first { $0.number == pick } ?? prototype
        let templateName = level.name
        level.id = "daily-\(Self.dayKey(start, calendar: calendar))"
        level.name = "Daily Rift"
        level.subtitle = "\(templateName) · \(Act.containing(level: pick).title)"

        let positions = level.sparks.map(\.position).shuffled(using: &rng)
        for i in level.sparks.indices {
            level.sparks[i].position = positions[i]
        }
        if !level.sparks.contains(where: { $0.position.distance(to: Vec2(x: 500, y: 500)) < 1 }) {
            level.sparks[0].position = Vec2(x: 500, y: 500)
        }
        level.theme = ArenaTheme.forLevel(Int(rng.next() % 6) + 1)
        return level.sanitized()
    }

    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func nextMidnight(after date: Date = Date(), calendar: Calendar = .current) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(86_400)
    }

    private static func make(
        number: Int,
        name: String,
        subtitle: String,
        playerStart: Vec2,
        exit: Vec2,
        walls: [AABB],
        sparks: [SparkSpawn],
        echoInterval: TimeInterval,
        maxEchoes: Int,
        parTime: TimeInterval,
        parMoves: Int,
        playerSpeed: Double = 320,
        bonuses: [BonusSpawn] = [],
        fields: [SlowField] = [],
        movers: [MoverSpawn] = [],
        rifts: [RiftSpawn] = [],
        gates: [TimeGateSpawn] = [],
        theme: ArenaTheme? = nil
    ) -> LevelDefinition {
        LevelDefinition(
            id: "awakening-\(number)",
            number: number,
            name: name,
            subtitle: subtitle,
            worldSize: LevelDefinition.worldSize,
            worldHeight: LevelDefinition.worldSize,
            playerStart: playerStart,
            exit: exit,
            walls: walls,
            sparks: sparks,
            bonuses: bonuses,
            fields: fields,
            movers: movers,
            rifts: rifts,
            gates: gates,
            theme: theme ?? .forLevel(number),
            echoInterval: echoInterval,
            maxEchoes: maxEchoes,
            warningLead: 1.6,
            parTime: parTime,
            parMoves: parMoves,
            playerSpeed: playerSpeed,
            locked: false
        ).sanitized()
    }

    /// Four inner pillars. They break a clean outer lap and force interior routing to the exit.
    private static func fourPillars() -> [AABB] {
        [
            AABB(x: 90, y: 160, width: 150, height: 210),
            AABB(x: 760, y: 160, width: 150, height: 210),
            AABB(x: 90, y: 630, width: 150, height: 210),
            AABB(x: 760, y: 630, width: 150, height: 210),
        ]
    }

    private static func corridorWalls() -> [AABB] {
        [
            AABB(x: 280, y: 70, width: 56, height: 330),
            AABB(x: 664, y: 70, width: 56, height: 330),
            AABB(x: 280, y: 600, width: 56, height: 330),
            AABB(x: 664, y: 600, width: 56, height: 330),
            AABB(x: 350, y: 448, width: 72, height: 104),
            AABB(x: 578, y: 448, width: 72, height: 104),
        ]
    }

    private static func crossWalls() -> [AABB] {
        [
            AABB(x: 80, y: 456, width: 250, height: 88),
            AABB(x: 670, y: 456, width: 250, height: 88),
            AABB(x: 456, y: 80, width: 88, height: 250),
            AABB(x: 456, y: 670, width: 88, height: 250),
        ]
    }
}

/// Tiny deterministic RNG so the daily layout is stable for a given calendar day.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
