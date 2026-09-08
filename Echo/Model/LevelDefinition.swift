import Foundation

struct SparkSpawn: Equatable, Sendable, Identifiable {
    var id: Int
    var position: Vec2
}

struct LevelDefinition: Equatable, Sendable, Identifiable {
    var id: String
    var number: Int
    var name: String
    var subtitle: String
    var worldSize: Double
    var playerStart: Vec2
    var exit: Vec2
    var walls: [AABB]
    var sparks: [SparkSpawn]
    var echoInterval: TimeInterval
    var maxEchoes: Int
    var warningLead: TimeInterval
    var parTime: TimeInterval
    var parMoves: Int
    var playerSpeed: Double
    var locked: Bool

    var sparkCount: Int { sparks.count }

    static let worldSize: Double = 1000
}

enum LevelCatalog {
    static let worldName = "Awakening"
    static let worldTagline = "Where every path leaves a trace."

    static let all: [LevelDefinition] = {
        var levels = playable
        for n in (playable.count + 1)...12 {
            levels.append(lockedStub(number: n))
        }
        return levels
    }()

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
            SparkSpawn(id: 1, position: Vec2(x: 220, y: 500)),
            SparkSpawn(id: 2, position: Vec2(x: 780, y: 500)),
            SparkSpawn(id: 3, position: Vec2(x: 500, y: 780)),
            SparkSpawn(id: 4, position: Vec2(x: 340, y: 340)),
            SparkSpawn(id: 5, position: Vec2(x: 660, y: 660)),
        ],
        echoInterval: 8,
        maxEchoes: 4,
        parTime: 22,
        parMoves: 38
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
                SparkSpawn(id: 1, position: Vec2(x: 820, y: 180)),
                SparkSpawn(id: 2, position: Vec2(x: 180, y: 820)),
                SparkSpawn(id: 3, position: Vec2(x: 820, y: 820)),
                SparkSpawn(id: 4, position: Vec2(x: 500, y: 280)),
                SparkSpawn(id: 5, position: Vec2(x: 500, y: 720)),
            ],
            echoInterval: 7.5,
            maxEchoes: 4,
            parTime: 24,
            parMoves: 42
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
                SparkSpawn(id: 1, position: Vec2(x: 200, y: 500)),
                SparkSpawn(id: 2, position: Vec2(x: 800, y: 500)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 800)),
                SparkSpawn(id: 4, position: Vec2(x: 280, y: 280)),
                SparkSpawn(id: 5, position: Vec2(x: 720, y: 720)),
            ],
            echoInterval: 7,
            maxEchoes: 4,
            parTime: 26,
            parMoves: 44
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
                SparkSpawn(id: 1, position: Vec2(x: 840, y: 500)),
                SparkSpawn(id: 2, position: Vec2(x: 500, y: 160)),
                SparkSpawn(id: 3, position: Vec2(x: 500, y: 840)),
                SparkSpawn(id: 4, position: Vec2(x: 300, y: 300)),
                SparkSpawn(id: 5, position: Vec2(x: 700, y: 700)),
            ],
            echoInterval: 6.5,
            maxEchoes: 4,
            parTime: 28,
            parMoves: 48,
            playerSpeed: 240
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
        return level
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
        playerSpeed: Double = 230
    ) -> LevelDefinition {
        LevelDefinition(
            id: "awakening-\(number)",
            number: number,
            name: name,
            subtitle: subtitle,
            worldSize: LevelDefinition.worldSize,
            playerStart: playerStart,
            exit: exit,
            walls: walls,
            sparks: sparks,
            echoInterval: echoInterval,
            maxEchoes: maxEchoes,
            warningLead: 1.6,
            parTime: parTime,
            parMoves: parMoves,
            playerSpeed: playerSpeed,
            locked: false
        )
    }

    private static func lockedStub(number: Int) -> LevelDefinition {
        var level = prototype
        level.id = "awakening-\(number)"
        level.number = number
        level.name = "Locked"
        level.subtitle = ""
        level.locked = true
        return level
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
            AABB(x: 300, y: 80, width: 48, height: 340),
            AABB(x: 652, y: 80, width: 48, height: 340),
            AABB(x: 300, y: 580, width: 48, height: 340),
            AABB(x: 652, y: 580, width: 48, height: 340),
            AABB(x: 380, y: 456, width: 240, height: 88),
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
