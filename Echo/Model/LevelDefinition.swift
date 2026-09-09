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
    static let worldTagline = "Where every path leaves a trace."

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
    ]

    static func daily(on day: Date = Date(), calendar: Calendar = .current) -> LevelDefinition {
        let start = calendar.startOfDay(for: day)
        var hasher = Hasher()
        hasher.combine(calendar.component(.year, from: start))
        hasher.combine(calendar.component(.month, from: start))
        hasher.combine(calendar.component(.day, from: start))
        let seed = hasher.finalize()
        var rng = SplitMix64(seed: UInt64(bitPattern: Int64(seed)))

        var level = prototype
        level.id = "daily-\(Self.dayKey(start, calendar: calendar))"
        level.name = "Daily Challenge"
        level.subtitle = "Complete the challenge to earn a special reward."
        level.echoInterval = 7.5
        level.parTime = 24
        level.parMoves = 40

        let candidates: [Vec2] = [
            Vec2(x: 500, y: 500),
            Vec2(x: 220, y: 500),
            Vec2(x: 780, y: 500),
            Vec2(x: 500, y: 780),
            Vec2(x: 500, y: 220),
            Vec2(x: 340, y: 340),
            Vec2(x: 660, y: 660),
            Vec2(x: 340, y: 660),
            Vec2(x: 660, y: 340),
            Vec2(x: 220, y: 780),
            Vec2(x: 780, y: 220),
        ]
        let picked = Array(candidates.shuffled(using: &rng).prefix(6))
        level.sparks = picked.enumerated().map { SparkSpawn(id: $0.offset, position: $0.element) }
        // The center spark stays — otherwise the outer ring becomes a winning strategy.
        if !level.sparks.contains(where: { $0.position.distance(to: Vec2(x: 500, y: 500)) < 1 }) {
            level.sparks[0].position = Vec2(x: 500, y: 500)
        }
        for i in level.sparks.indices where i == 1 || i == 3 || i == 5 {
            level.sparks[i].timer = [12, 10, 15][min(i / 2, 2)]
        }
        level.bonuses = [
            BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 160, y: 820)),
            BonusSpawn(id: 1, kind: .surge, position: Vec2(x: 840, y: 180)),
        ]
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
        fields: [SlowField] = []
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
