import Foundation

/// Twelve maps built for the wrist: a smaller, nearly square world, fewer
/// objectives and shorter runs, named after the parts of a watch movement.
/// Shared with the phone so it can count clears and grant relics.
enum WristCatalog {
    static let worldSize: Double = 700
    /// The three movements of the Keeper Chronometer.
    static var actTitles: [String] { (1...3).map { Copy.text("wrist.act\($0)") } }
    static let mapsPerAct = 4

    static let maps: [LevelDefinition] = [
        map(
            1, "Tick", "Three sparks. Your past follows.",
            start: Vec2(x: 350, y: 90), exit: Vec2(x: 350, y: 610),
            sparks: [Vec2(x: 170, y: 350), Vec2(x: 530, y: 350), Vec2(x: 350, y: 470)],
            echoInterval: 8, maxEchoes: 1, par: 16
        ),
        map(
            2, "Tock", "Two pillars, two echoes.",
            start: Vec2(x: 350, y: 90), exit: Vec2(x: 350, y: 620),
            walls: [AABB(x: 170, y: 260, width: 70, height: 180), AABB(x: 460, y: 260, width: 70, height: 180)],
            sparks: [Vec2(x: 110, y: 350), Vec2(x: 590, y: 350), Vec2(x: 350, y: 350), Vec2(x: 350, y: 520)],
            echoInterval: 7.5, maxEchoes: 2, par: 20
        ),
        map(
            3, "Second Hand", "A slow rock sweeps the dial.",
            start: Vec2(x: 350, y: 80), exit: Vec2(x: 350, y: 630),
            sparks: [Vec2(x: 350, y: 350), Vec2(x: 110, y: 350), Vec2(x: 590, y: 350), Vec2(x: 350, y: 580)],
            movers: [.orbit(id: 0, center: Vec2(x: 350, y: 350), radius: 170, period: 9, size: 30, material: .basalt)],
            echoInterval: 8, maxEchoes: 2, par: 22
        ),
        map(
            4, "Bezel", "Sparks ride the rim. Rocks ricochet.",
            start: Vec2(x: 200, y: 130), exit: Vec2(x: 500, y: 590),
            sparks: [Vec2(x: 80, y: 350), Vec2(x: 620, y: 350), Vec2(x: 350, y: 630), Vec2(x: 350, y: 75)],
            bonuses: [BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 350, y: 350))],
            movers: [
                .bounce(id: 0, at: Vec2(x: 200, y: 460), velocity: Vec2(x: 70, y: 55), radius: 30, material: .basalt),
                .bounce(id: 1, at: Vec2(x: 500, y: 250), velocity: Vec2(x: -60, y: 65), radius: 30, material: .ice),
            ],
            echoInterval: 8, maxEchoes: 3, par: 26
        ),
        map(
            5, "Crown", "A beam fires across the middle.",
            start: Vec2(x: 350, y: 80), exit: Vec2(x: 350, y: 620),
            sparks: [Vec2(x: 150, y: 200), Vec2(x: 550, y: 200), Vec2(x: 150, y: 500), Vec2(x: 550, y: 500)],
            lasers: [.horizontal(id: 0, y: 350, fromX: 60, toX: 640, period: 5.5, chargeFor: 1.3, activeFor: 1.2, phase: 1.5)],
            echoInterval: 8, maxEchoes: 2, par: 22,
            theme: .ion
        ),
        map(
            6, "Escapement", "Slip through the gap between ticks.",
            start: Vec2(x: 350, y: 90), exit: Vec2(x: 350, y: 620),
            walls: [AABB(x: 40, y: 330, width: 250, height: 40), AABB(x: 410, y: 330, width: 250, height: 40)],
            sparks: [Vec2(x: 120, y: 180), Vec2(x: 580, y: 180), Vec2(x: 120, y: 540), Vec2(x: 580, y: 540)],
            movers: [.patrol(id: 0, from: Vec2(x: 170, y: 460), to: Vec2(x: 530, y: 460), radius: 30, material: .alloy)],
            gates: [TimeGateSpawn(id: 0, area: AABB(x: 290, y: 330, width: 120, height: 40), period: 4.6, openFor: 2.3, phase: 1)],
            echoInterval: 8.5, maxEchoes: 2, par: 26,
            theme: .ion
        ),
        map(
            7, "Balance Wheel", "Two weights swing around the core.",
            start: Vec2(x: 350, y: 70), exit: Vec2(x: 580, y: 620),
            sparks: [Vec2(x: 350, y: 380), Vec2(x: 350, y: 610), Vec2(x: 110, y: 200), Vec2(x: 590, y: 200)],
            bonuses: [BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 110, y: 600))],
            movers: [
                .orbit(id: 0, center: Vec2(x: 350, y: 380), radius: 150, period: 7, phase: 0, size: 30, material: .crystal),
                .orbit(id: 1, center: Vec2(x: 350, y: 380), radius: 150, period: 7, phase: .pi, size: 30, material: .ice),
            ],
            echoInterval: 8, maxEchoes: 3, par: 26,
            theme: .ion
        ),
        map(
            8, "Mainspring", "Gold crystals pay out only while they last.",
            start: Vec2(x: 90, y: 90), exit: Vec2(x: 350, y: 630),
            walls: [
                AABB(x: 180, y: 220, width: 380, height: 36),
                AABB(x: 524, y: 220, width: 36, height: 280),
                AABB(x: 180, y: 464, width: 380, height: 36),
            ],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 380, y: 360), timer: 14),
                SparkSpawn(id: 1, position: Vec2(x: 350, y: 110), timer: 10),
                SparkSpawn(id: 2, position: Vec2(x: 110, y: 600)),
                SparkSpawn(id: 3, position: Vec2(x: 610, y: 620)),
            ],
            bonuses: [BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 625, y: 360))],
            echoInterval: 8, maxEchoes: 3, par: 28,
            theme: .ion
        ),
        map(
            9, "Jewel Bearing", "Ice cracks on every wall hit.",
            start: Vec2(x: 350, y: 70), exit: Vec2(x: 350, y: 640),
            sparks: [Vec2(x: 100, y: 110), Vec2(x: 600, y: 110), Vec2(x: 100, y: 600), Vec2(x: 600, y: 600), Vec2(x: 350, y: 380)],
            bonuses: [BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 350, y: 170))],
            movers: [
                .bounce(id: 0, at: Vec2(x: 200, y: 460), velocity: Vec2(x: 90, y: 70), radius: 32, material: .ice),
                .bounce(id: 1, at: Vec2(x: 500, y: 270), velocity: Vec2(x: -80, y: 90), radius: 30, material: .ice),
                .bounce(id: 2, at: Vec2(x: 350, y: 540), velocity: Vec2(x: 70, y: -60), radius: 30, material: .crystal),
            ],
            echoInterval: 8.5, maxEchoes: 2, par: 26,
            theme: .ember
        ),
        map(
            10, "Complication", "A sweeping beam and a restless rock.",
            start: Vec2(x: 350, y: 80), exit: Vec2(x: 630, y: 630),
            sparks: [Vec2(x: 110, y: 140), Vec2(x: 590, y: 140), Vec2(x: 110, y: 600), Vec2(x: 560, y: 560)],
            movers: [.bounce(id: 0, at: Vec2(x: 170, y: 560), velocity: Vec2(x: 80, y: -60), radius: 32, material: .basalt)],
            lasers: [.sweeping(id: 0, center: Vec2(x: 350, y: 380), length: 500, from: 0, to: .pi / 2, sweepDuration: 3.2, period: 6, chargeFor: 1.3, activeFor: 1.6)],
            echoInterval: 8, maxEchoes: 3, par: 28,
            theme: .ember
        ),
        map(
            11, "Moonphase", "One gate breathes between two halves.",
            start: Vec2(x: 150, y: 80), exit: Vec2(x: 560, y: 620),
            walls: [AABB(x: 330, y: 60, width: 40, height: 200), AABB(x: 330, y: 440, width: 40, height: 200)],
            sparks: [Vec2(x: 110, y: 230), Vec2(x: 110, y: 540), Vec2(x: 590, y: 230), Vec2(x: 590, y: 520)],
            movers: [
                .orbit(id: 0, center: Vec2(x: 175, y: 380), radius: 105, period: 8, phase: 0, size: 30, material: .alloy),
                .orbit(id: 1, center: Vec2(x: 525, y: 380), radius: 105, period: 8, phase: .pi, size: 30, material: .alloy),
            ],
            gates: [TimeGateSpawn(id: 0, area: AABB(x: 330, y: 260, width: 40, height: 180), period: 5, openFor: 2.4, phase: 0.5)],
            echoInterval: 9, maxEchoes: 3, par: 30,
            theme: .ember
        ),
        map(
            12, "Tourbillon", "Everything turns at once.",
            start: Vec2(x: 90, y: 110), exit: Vec2(x: 610, y: 110),
            sparks: [Vec2(x: 90, y: 380), Vec2(x: 610, y: 380), Vec2(x: 350, y: 110), Vec2(x: 350, y: 650)],
            movers: [
                .stationary(id: 0, at: Vec2(x: 350, y: 380), radius: 70),
                .orbit(id: 1, center: Vec2(x: 350, y: 380), radius: 170, period: 9, phase: 0, size: 30, material: .crystal),
                .orbit(id: 2, center: Vec2(x: 350, y: 380), radius: 170, period: 9, phase: .pi * 2 / 3, size: 30, material: .ice),
                .orbit(id: 3, center: Vec2(x: 350, y: 380), radius: 170, period: 9, phase: .pi * 4 / 3, size: 30, material: .basalt),
            ],
            lasers: [.horizontal(id: 0, y: 610, fromX: 60, toX: 640, period: 6.5, chargeFor: 1.4, activeFor: 1.3, phase: 3)],
            echoInterval: 9, maxEchoes: 4, par: 34,
            theme: .ember
        ),
    ]

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

    private static func map(
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
        map(
            number, name, subtitle,
            start: start, exit: exit, walls: walls,
            sparks: sparks.enumerated().map { SparkSpawn(id: $0.offset, position: $0.element) },
            bonuses: bonuses, movers: movers, gates: gates, lasers: lasers,
            echoInterval: echoInterval, maxEchoes: maxEchoes, par: par, theme: theme
        )
    }

    private static func map(
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
