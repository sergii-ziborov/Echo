import Foundation

extension WristCatalog {
    /// The second movement: regulation. Each room tunes one part of the
    /// chronometer, and the hazards learned in calibration start to combine.
    static let regulation: [LevelDefinition] = [
        room(
            13, "Hairspring", "The coil turns back on itself.",
            start: Vec2(x: 90, y: 80), exit: Vec2(x: 110, y: 620),
            walls: [
                AABB(x: 0, y: 190, width: 520, height: 34),
                AABB(x: 180, y: 350, width: 520, height: 34),
                AABB(x: 0, y: 510, width: 520, height: 34),
            ],
            sparks: [Vec2(x: 620, y: 110), Vec2(x: 100, y: 287), Vec2(x: 600, y: 447)],
            echoInterval: 7, maxEchoes: 2, par: 30,
            theme: .ice
        ),
        room(
            14, "Pallet Fork", "Two gates lock and release in turn.",
            start: Vec2(x: 350, y: 90), exit: Vec2(x: 350, y: 620),
            walls: [
                AABB(x: 0, y: 330, width: 160, height: 40),
                AABB(x: 280, y: 330, width: 140, height: 40),
                AABB(x: 540, y: 330, width: 160, height: 40),
            ],
            sparks: [Vec2(x: 120, y: 180), Vec2(x: 580, y: 180), Vec2(x: 120, y: 540), Vec2(x: 580, y: 540), Vec2(x: 350, y: 470)],
            movers: [.bounce(id: 0, at: Vec2(x: 200, y: 250), velocity: Vec2(x: 90, y: 40), radius: 28, material: .ice)],
            gates: [
                TimeGateSpawn(id: 0, area: AABB(x: 160, y: 330, width: 120, height: 40), period: 5, openFor: 2.2, phase: 0),
                TimeGateSpawn(id: 1, area: AABB(x: 420, y: 330, width: 120, height: 40), period: 5, openFor: 2.2, phase: 2.5),
            ],
            echoInterval: 8, maxEchoes: 2, par: 26,
            theme: .ice
        ),
        room(
            15, "Barrel", "Two rings wind around the core.",
            start: Vec2(x: 350, y: 55), exit: Vec2(x: 350, y: 650),
            sparks: [Vec2(x: 90, y: 110), Vec2(x: 610, y: 110), Vec2(x: 90, y: 600), Vec2(x: 610, y: 600)],
            movers: [
                .stationary(id: 0, at: Vec2(x: 350, y: 350), radius: 50),
                .orbit(id: 1, center: Vec2(x: 350, y: 350), radius: 120, period: 7, phase: 0, size: 26, material: .ice),
                .orbit(id: 2, center: Vec2(x: 350, y: 350), radius: 120, period: 7, phase: .pi, size: 26, material: .crystal),
                .orbit(id: 3, center: Vec2(x: 350, y: 350), radius: 210, period: 10, phase: .pi / 2, size: 28, material: .basalt),
                .orbit(id: 4, center: Vec2(x: 350, y: 350), radius: 210, period: 10, phase: .pi * 3 / 2, size: 28, material: .ice),
            ],
            echoInterval: 8, maxEchoes: 3, par: 30,
            theme: .ice
        ),
        room(
            16, "Ratchet", "Four crystals, one way round.",
            start: Vec2(x: 80, y: 80), exit: Vec2(x: 620, y: 620),
            walls: [AABB(x: 250, y: 250, width: 200, height: 200)],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 115, y: 350), timer: 9),
                SparkSpawn(id: 1, position: Vec2(x: 350, y: 585), timer: 12),
                SparkSpawn(id: 2, position: Vec2(x: 585, y: 350), timer: 15),
                SparkSpawn(id: 3, position: Vec2(x: 350, y: 115), timer: 18),
            ],
            movers: [.orbit(id: 0, center: Vec2(x: 350, y: 350), radius: 180, period: 12, phase: 0, size: 26, material: .ice)],
            echoInterval: 8, maxEchoes: 3, par: 26,
            theme: .ice
        ),
        room(
            17, "Gear Train", "Collect the hubs between the teeth.",
            start: Vec2(x: 620, y: 70), exit: Vec2(x: 620, y: 630),
            sparks: [Vec2(x: 190, y: 190), Vec2(x: 510, y: 350), Vec2(x: 190, y: 510), Vec2(x: 330, y: 350)],
            movers: [
                .orbit(id: 0, center: Vec2(x: 190, y: 190), radius: 100, period: 6, phase: 0, size: 26, material: .basalt),
                .orbit(id: 1, center: Vec2(x: 510, y: 350), radius: 110, period: 7, phase: 1, size: 26, material: .geode),
                .orbit(id: 2, center: Vec2(x: 190, y: 510), radius: 100, period: 6.5, phase: 2, size: 26, material: .iron),
            ],
            echoInterval: 8.5, maxEchoes: 2, par: 28,
            theme: .moss
        ),
        room(
            18, "Center Wheel", "The hand sweeps the dial; cross while it is dark.",
            start: Vec2(x: 70, y: 70), exit: Vec2(x: 630, y: 630),
            sparks: [Vec2(x: 491, y: 491), Vec2(x: 209, y: 491), Vec2(x: 209, y: 209), Vec2(x: 491, y: 209)],
            lasers: [.sweeping(id: 0, center: Vec2(x: 350, y: 350), length: 560, from: 0, to: .pi, sweepDuration: 5, period: 6, chargeFor: 1.4, activeFor: 2)],
            echoInterval: 8, maxEchoes: 2, par: 26,
            theme: .moss
        ),
        room(
            19, "Fourth Wheel", "Two beams keep alternate seconds.",
            start: Vec2(x: 350, y: 70), exit: Vec2(x: 350, y: 640),
            sparks: [Vec2(x: 120, y: 200), Vec2(x: 580, y: 200), Vec2(x: 120, y: 560), Vec2(x: 580, y: 560), Vec2(x: 350, y: 500)],
            movers: [.patrol(id: 0, from: Vec2(x: 350, y: 260), to: Vec2(x: 350, y: 440), radius: 26, material: .alloy)],
            lasers: [
                .vertical(id: 0, x: 240, fromY: 50, toY: 650, period: 6, chargeFor: 1.3, activeFor: 1.2, phase: 0),
                .vertical(id: 1, x: 460, fromY: 50, toY: 650, period: 6, chargeFor: 1.3, activeFor: 1.2, phase: 3),
            ],
            echoInterval: 8, maxEchoes: 3, par: 30,
            theme: .moss
        ),
        room(
            20, "Cannon Pinion", "A piston rock runs the tube.",
            start: Vec2(x: 350, y: 60), exit: Vec2(x: 350, y: 640),
            walls: [AABB(x: 250, y: 140, width: 30, height: 420), AABB(x: 420, y: 140, width: 30, height: 420)],
            sparks: [Vec2(x: 130, y: 350), Vec2(x: 570, y: 350), Vec2(x: 350, y: 350), Vec2(x: 130, y: 600)],
            bonuses: [BonusSpawn(id: 0, kind: .freeze, position: Vec2(x: 570, y: 600))],
            movers: [.patrol(id: 0, from: Vec2(x: 350, y: 170), to: Vec2(x: 350, y: 530), radius: 30, material: .basalt)],
            echoInterval: 8, maxEchoes: 2, par: 24,
            theme: .moss
        ),
        room(
            21, "Rotor", "Catch the sparks riding the rotor.",
            start: Vec2(x: 350, y: 55), exit: Vec2(x: 350, y: 650),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 530, y: 380), orbit: SparkOrbit(center: Vec2(x: 350, y: 380), radius: 180, period: 12, phase: 0)),
                SparkSpawn(id: 1, position: Vec2(x: 170, y: 380), orbit: SparkOrbit(center: Vec2(x: 350, y: 380), radius: 180, period: 12, phase: .pi)),
                SparkSpawn(id: 2, position: Vec2(x: 110, y: 110)),
                SparkSpawn(id: 3, position: Vec2(x: 590, y: 110)),
            ],
            movers: [
                .bounce(id: 0, at: Vec2(x: 120, y: 600), velocity: Vec2(x: 70, y: -50), radius: 26, material: .comet),
                .bounce(id: 1, at: Vec2(x: 580, y: 600), velocity: Vec2(x: -60, y: -60), radius: 26, material: .magma),
            ],
            lasers: [.sweeping(id: 0, center: Vec2(x: 350, y: 380), length: 300, from: 0, to: .pi, sweepDuration: 3, period: 5.5, chargeFor: 1.3, activeFor: 1.5)],
            echoInterval: 8.5, maxEchoes: 2, par: 28,
            theme: .dust
        ),
        room(
            22, "Power Reserve", "The gauge drains; take it in order.",
            start: Vec2(x: 80, y: 80), exit: Vec2(x: 620, y: 630),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 150, y: 200), timer: 8),
                SparkSpawn(id: 1, position: Vec2(x: 250, y: 330), timer: 10),
                SparkSpawn(id: 2, position: Vec2(x: 350, y: 420), timer: 12),
                SparkSpawn(id: 3, position: Vec2(x: 450, y: 330), timer: 14),
                SparkSpawn(id: 4, position: Vec2(x: 550, y: 200), timer: 16),
            ],
            bonuses: [BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 350, y: 120))],
            movers: [
                .bounce(id: 0, at: Vec2(x: 200, y: 560), velocity: Vec2(x: 80, y: -40), radius: 28, material: .magma),
                .bounce(id: 1, at: Vec2(x: 500, y: 520), velocity: Vec2(x: -70, y: 50), radius: 28, material: .iron),
            ],
            echoInterval: 9, maxEchoes: 3, par: 30,
            theme: .dust
        ),
        room(
            23, "Chronograph", "Start, stop, reset: a beam and a gate.",
            start: Vec2(x: 350, y: 60), exit: Vec2(x: 350, y: 640),
            walls: [AABB(x: 0, y: 440, width: 290, height: 30), AABB(x: 410, y: 440, width: 290, height: 30)],
            sparks: [Vec2(x: 120, y: 120), Vec2(x: 580, y: 120), Vec2(x: 120, y: 350), Vec2(x: 580, y: 350), Vec2(x: 150, y: 590), Vec2(x: 550, y: 590)],
            gates: [TimeGateSpawn(id: 0, area: AABB(x: 290, y: 440, width: 120, height: 30), period: 4, openFor: 1.8, phase: 0)],
            lasers: [.horizontal(id: 0, y: 250, fromX: 40, toX: 660, period: 5.5, chargeFor: 1.3, activeFor: 1.2, phase: 2)],
            echoInterval: 8, maxEchoes: 3, par: 32,
            theme: .dust
        ),
        room(
            24, "Flyback", "Two runs and a reset beam.",
            start: Vec2(x: 100, y: 70), exit: Vec2(x: 600, y: 640),
            sparks: [Vec2(x: 120, y: 350), Vec2(x: 580, y: 350), Vec2(x: 350, y: 150), Vec2(x: 350, y: 550)],
            movers: [
                .patrol(id: 0, from: Vec2(x: 120, y: 250), to: Vec2(x: 580, y: 250), radius: 28, material: .comet),
                .patrol(id: 1, from: Vec2(x: 580, y: 450), to: Vec2(x: 120, y: 450), radius: 28, material: .geode),
            ],
            lasers: [.vertical(id: 0, x: 350, fromY: 50, toY: 650, period: 6.5, chargeFor: 1.4, activeFor: 1.3)],
            echoInterval: 8.5, maxEchoes: 3, par: 32,
            theme: .dust
        ),
    ]
}
