import Foundation

extension LevelCatalog {
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

    static func make(
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
        lasers: [LaserSpawn] = [],
        gravityWells: [GravityWellSpawn] = [],
        decorations: [ArenaDecoration] = [],
        theme: ArenaTheme? = nil,
        atmosphere: ArenaAtmosphere? = nil
    ) -> LevelDefinition {
        let resolvedDecorations = decorations.isEmpty
            ? defaultDecorations(
                number: number,
                playerStart: playerStart,
                exit: exit,
                walls: walls,
                sparks: sparks,
                movers: movers,
                rifts: rifts
            )
            : decorations

        return LevelDefinition(
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
            lasers: lasers,
            gravityWells: gravityWells,
            decorations: resolvedDecorations,
            theme: theme ?? .forLevel(number),
            atmosphere: atmosphere ?? .forLevel(number),
            echoInterval: echoInterval,
            maxEchoes: maxEchoes,
            warningLead: 1.6,
            parTime: parTime,
            parMoves: parMoves,
            playerSpeed: playerSpeed,
            locked: false
        ).sanitized()
    }

    /// Every arena receives a small set of low, non-solid landmarks. The selection
    /// follows its actual objectives and hazards, so repeated wall kits still read as
    /// different places without putting decorative geometry through a solid wall.
    static func defaultDecorations(
        number: Int,
        playerStart: Vec2,
        exit: Vec2,
        walls: [AABB],
        sparks: [SparkSpawn],
        movers: [MoverSpawn],
        rifts: [RiftSpawn]
    ) -> [ArenaDecoration] {
        var nextID = number * 100
        var result: [ArenaDecoration] = []

        func append(
            _ kind: ArenaDecorationKind,
            at position: Vec2,
            tone: ArenaDecorationTone,
            rotation: Double = 0
        ) {
            result.append(ArenaDecoration(id: nextID, kind: kind, position: position, tone: tone, rotation: rotation))
            nextID += 1
        }

        append(
            .anchor(radius: 38 + Double(number % 3) * 4),
            at: playerStart,
            tone: .cyan,
            rotation: Double(number % 6) * .pi / 9
        )
        append(
            .reactor(radius: 48 + Double(number % 2) * 5, spokes: 8 + number % 5),
            at: exit,
            tone: .theme,
            rotation: -Double(number % 5) * .pi / 10
        )

        for spark in sparks.filter({ $0.timer != nil }).prefix(2) {
            append(
                .hazardRing(radius: 34, segments: 8 + (spark.id + number) % 5),
                at: spark.position,
                tone: .gold,
                rotation: Double(spark.id) * .pi / 7
            )
        }

        if let mover = movers.first, mover.path != .stationary {
            append(
                .hazardRing(radius: mover.radius + 18, segments: 10),
                at: mover.position,
                tone: .danger,
                rotation: Double(number) * .pi / 13
            )
        } else if let rift = rifts.first {
            append(
                .hazardRing(radius: rift.radius + 10, segments: 12),
                at: rift.position,
                tone: .violet,
                rotation: Double(number) * .pi / 11
            )
        }

        let laneCandidates = sparks
            .map(\.position)
            .filter { $0.distance(to: playerStart) > 90 }
            .sorted { $0.distance(to: playerStart) < $1.distance(to: playerStart) }
        if let destination = laneCandidates.first(where: {
            clearSegment(from: playerStart, to: $0, walls: walls, clearance: 9)
        }) {
            append(
                .lane(to: destination, chevrons: 5 + number % 4),
                at: playerStart,
                tone: .theme
            )
        }

        return result
    }

    static func clearSegment(
        from start: Vec2,
        to end: Vec2,
        walls: [AABB],
        clearance: Double
    ) -> Bool {
        (0...30).allSatisfy { index in
            let point = start.lerp(end, Double(index) / 30)
            return walls.allSatisfy { !$0.intersectsCircle(center: point, radius: clearance) }
        }
    }

    /// Four inner pillars. They break a clean outer lap and force interior routing to the exit.
    static func fourPillars() -> [AABB] {
        [
            AABB(x: 90, y: 160, width: 150, height: 210),
            AABB(x: 760, y: 160, width: 150, height: 210),
            AABB(x: 90, y: 630, width: 150, height: 210),
            AABB(x: 760, y: 630, width: 150, height: 210),
        ]
    }

    static func corridorWalls() -> [AABB] {
        [
            AABB(x: 280, y: 70, width: 56, height: 330),
            AABB(x: 664, y: 70, width: 56, height: 330),
            AABB(x: 280, y: 600, width: 56, height: 330),
            AABB(x: 664, y: 600, width: 56, height: 330),
            AABB(x: 350, y: 448, width: 72, height: 104),
            AABB(x: 578, y: 448, width: 72, height: 104),
        ]
    }

    static func crossWalls() -> [AABB] {
        [
            AABB(x: 80, y: 456, width: 250, height: 88),
            AABB(x: 670, y: 456, width: 250, height: 88),
            AABB(x: 456, y: 80, width: 88, height: 250),
            AABB(x: 456, y: 670, width: 88, height: 250),
        ]
    }
}
