import Foundation

extension WristCatalog {
    /// The third movement: certification. The chronometer is tested the way
    /// observatories once tested watches, with every hazard in combination.
    static let certification: [LevelDefinition] = [
        room(
            25, "Rattrapante", "Two hands split the dial.",
            start: Vec2(x: 350, y: 55), exit: Vec2(x: 600, y: 620),
            sparks: [Vec2(x: 100, y: 110), Vec2(x: 600, y: 110), Vec2(x: 100, y: 600), Vec2(x: 350, y: 180)],
            lasers: [
                .sweeping(id: 0, center: Vec2(x: 350, y: 360), length: 520, from: 0, to: .pi / 2, sweepDuration: 3, period: 6, chargeFor: 1.4, activeFor: 1.5, phase: 0),
                .sweeping(id: 1, center: Vec2(x: 350, y: 360), length: 520, from: .pi / 2, to: .pi, sweepDuration: 3, period: 6, chargeFor: 1.4, activeFor: 1.5, phase: 3),
            ],
            echoInterval: 8, maxEchoes: 3, par: 30,
            theme: .tear
        ),
        room(
            26, "Tachymeter", "Measure speed by distance.",
            start: Vec2(x: 350, y: 70), exit: Vec2(x: 350, y: 640),
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 100, y: 600), timer: 7),
                SparkSpawn(id: 1, position: Vec2(x: 600, y: 600), timer: 9),
                SparkSpawn(id: 2, position: Vec2(x: 600, y: 100), timer: 11),
                SparkSpawn(id: 3, position: Vec2(x: 350, y: 350)),
            ],
            bonuses: [BonusSpawn(id: 0, kind: .surge, position: Vec2(x: 350, y: 200))],
            movers: [
                .bounce(id: 0, at: Vec2(x: 200, y: 400), velocity: Vec2(x: 110, y: 80), radius: 26, material: .ice),
                .bounce(id: 1, at: Vec2(x: 500, y: 300), velocity: Vec2(x: -100, y: 90), radius: 26, material: .crystal),
                .bounce(id: 2, at: Vec2(x: 350, y: 520), velocity: Vec2(x: 90, y: -100), radius: 24, material: .comet),
            ],
            echoInterval: 7.5, maxEchoes: 3, par: 24,
            theme: .tear
        ),
        room(
            27, "Minute Repeater", "Three gates chime in turn.",
            start: Vec2(x: 350, y: 70), exit: Vec2(x: 350, y: 640),
            walls: [
                AABB(x: 0, y: 180, width: 300, height: 30),
                AABB(x: 420, y: 180, width: 280, height: 30),
                AABB(x: 0, y: 350, width: 120, height: 30),
                AABB(x: 240, y: 350, width: 460, height: 30),
                AABB(x: 0, y: 520, width: 460, height: 30),
                AABB(x: 580, y: 520, width: 120, height: 30),
            ],
            sparks: [Vec2(x: 100, y: 100), Vec2(x: 580, y: 280), Vec2(x: 600, y: 450), Vec2(x: 120, y: 620)],
            gates: [
                TimeGateSpawn(id: 0, area: AABB(x: 300, y: 180, width: 120, height: 30), period: 4.5, openFor: 2, phase: 0),
                TimeGateSpawn(id: 1, area: AABB(x: 120, y: 350, width: 120, height: 30), period: 4.5, openFor: 2, phase: 1.5),
                TimeGateSpawn(id: 2, area: AABB(x: 460, y: 520, width: 120, height: 30), period: 4.5, openFor: 2, phase: 3),
            ],
            echoInterval: 8, maxEchoes: 3, par: 34,
            theme: .tear
        ),
        room(
            28, "Perpetual Calendar", "Four wheels, four lengths of month.",
            start: Vec2(x: 350, y: 60), exit: Vec2(x: 350, y: 650),
            sparks: [Vec2(x: 190, y: 190), Vec2(x: 510, y: 190), Vec2(x: 190, y: 510), Vec2(x: 510, y: 510), Vec2(x: 350, y: 350)],
            movers: [
                .orbit(id: 0, center: Vec2(x: 190, y: 190), radius: 90, period: 6, phase: 0, size: 24, material: .basalt),
                .orbit(id: 1, center: Vec2(x: 510, y: 190), radius: 90, period: 7, phase: 1, size: 24, material: .ice),
                .orbit(id: 2, center: Vec2(x: 190, y: 510), radius: 90, period: 8, phase: 2, size: 24, material: .crystal),
                .orbit(id: 3, center: Vec2(x: 510, y: 510), radius: 90, period: 9, phase: 3, size: 24, material: .geode),
            ],
            echoInterval: 9, maxEchoes: 3, par: 34,
            theme: .tear
        ),
        room(
            29, "Equation of Time", "Two beams disagree about noon.",
            start: Vec2(x: 80, y: 80), exit: Vec2(x: 620, y: 620),
            sparks: [Vec2(x: 175, y: 175), Vec2(x: 525, y: 175), Vec2(x: 175, y: 525), Vec2(x: 525, y: 525)],
            movers: [.bounce(id: 0, at: Vec2(x: 200, y: 300), velocity: Vec2(x: 60, y: 70), radius: 26, material: .iron)],
            lasers: [
                .horizontal(id: 0, y: 350, fromX: 40, toX: 660, period: 6, chargeFor: 1.4, activeFor: 1.3, phase: 0),
                .vertical(id: 1, x: 350, fromY: 40, toY: 660, period: 6, chargeFor: 1.4, activeFor: 1.3, phase: 3),
            ],
            echoInterval: 8, maxEchoes: 3, par: 28,
            theme: .abyss
        ),
        room(
            30, "Sidereal Time", "The stars turn a little faster.",
            start: Vec2(x: 350, y: 50), exit: Vec2(x: 350, y: 650),
            sparks: (0..<3).map { index in
                let phase = Double(index) * .pi * 2 / 3
                let center = Vec2(x: 350, y: 360)
                return SparkSpawn(
                    id: index,
                    position: Vec2(x: center.x + cos(phase) * 200, y: center.y + sin(phase) * 200),
                    orbit: SparkOrbit(center: center, radius: 200, period: 14, phase: phase)
                )
            },
            movers: [
                .stationary(id: 0, at: Vec2(x: 350, y: 360), radius: 70),
                .orbit(id: 1, center: Vec2(x: 350, y: 360), radius: 120, period: 7, phase: 0, size: 24, material: .ice),
                .orbit(id: 2, center: Vec2(x: 350, y: 360), radius: 120, period: 7, phase: .pi, size: 24, material: .crystal),
            ],
            echoInterval: 9, maxEchoes: 3, par: 32,
            theme: .abyss
        ),
        room(
            31, "Remontoire", "Wait for the force to be restored.",
            start: Vec2(x: 110, y: 80), exit: Vec2(x: 590, y: 640),
            walls: [
                AABB(x: 220, y: 0, width: 30, height: 300),
                AABB(x: 220, y: 420, width: 30, height: 280),
                AABB(x: 450, y: 0, width: 30, height: 280),
                AABB(x: 450, y: 400, width: 30, height: 300),
            ],
            sparks: [Vec2(x: 110, y: 600), Vec2(x: 350, y: 120), Vec2(x: 350, y: 600), Vec2(x: 590, y: 120)],
            movers: [.patrol(id: 0, from: Vec2(x: 350, y: 200), to: Vec2(x: 350, y: 520), radius: 28, material: .alloy)],
            gates: [
                TimeGateSpawn(id: 0, area: AABB(x: 220, y: 300, width: 30, height: 120), period: 5, openFor: 2.2, phase: 0),
                TimeGateSpawn(id: 1, area: AABB(x: 450, y: 280, width: 30, height: 120), period: 5, openFor: 2.2, phase: 2.5),
            ],
            echoInterval: 8.5, maxEchoes: 3, par: 32,
            theme: .abyss
        ),
        room(
            32, "Fusee", "The chain unwinds through two beams.",
            start: Vec2(x: 100, y: 80), exit: Vec2(x: 600, y: 620),
            walls: [AABB(x: 0, y: 200, width: 540, height: 30), AABB(x: 160, y: 420, width: 540, height: 30)],
            sparks: [Vec2(x: 600, y: 110), Vec2(x: 100, y: 330), Vec2(x: 600, y: 330), Vec2(x: 350, y: 600)],
            movers: [
                .bounce(id: 0, at: Vec2(x: 350, y: 320), velocity: Vec2(x: 90, y: 30), radius: 26, material: .comet),
                .bounce(id: 1, at: Vec2(x: 350, y: 560), velocity: Vec2(x: -80, y: 40), radius: 26, material: .magma),
            ],
            lasers: [
                .horizontal(id: 0, y: 215, fromX: 548, toX: 680, period: 5.5, chargeFor: 1.3, activeFor: 1.2, phase: 0),
                .horizontal(id: 1, y: 435, fromX: 20, toX: 152, period: 5.5, chargeFor: 1.3, activeFor: 1.2, phase: 2.7),
            ],
            echoInterval: 8, maxEchoes: 3, par: 34,
            theme: .abyss
        ),
        room(
            33, "Detent Escapement", "One gate, one beam, one moment.",
            start: Vec2(x: 350, y: 60), exit: Vec2(x: 350, y: 640),
            walls: [AABB(x: 0, y: 330, width: 290, height: 40), AABB(x: 410, y: 330, width: 290, height: 40)],
            sparks: [Vec2(x: 120, y: 130), Vec2(x: 580, y: 130), Vec2(x: 120, y: 560), Vec2(x: 580, y: 560)],
            movers: [.patrol(id: 0, from: Vec2(x: 150, y: 230), to: Vec2(x: 550, y: 230), radius: 26, material: .alloy)],
            gates: [TimeGateSpawn(id: 0, area: AABB(x: 290, y: 330, width: 120, height: 40), period: 6, openFor: 2, phase: 0)],
            lasers: [.horizontal(id: 0, y: 440, fromX: 40, toX: 660, period: 6, chargeFor: 1.4, activeFor: 1.2, phase: 3.8)],
            echoInterval: 8, maxEchoes: 3, par: 30,
            theme: .dawn
        ),
        room(
            34, "Constant Force", "Four fragments that never slow down.",
            start: Vec2(x: 350, y: 60), exit: Vec2(x: 350, y: 650),
            sparks: [Vec2(x: 100, y: 100), Vec2(x: 600, y: 100), Vec2(x: 100, y: 600), Vec2(x: 600, y: 600), Vec2(x: 350, y: 180), Vec2(x: 350, y: 540)],
            bonuses: [BonusSpawn(id: 0, kind: .shield, position: Vec2(x: 350, y: 350))],
            movers: [
                .bounce(id: 0, at: Vec2(x: 150, y: 250), velocity: Vec2(x: 85, y: 60), radius: 26, material: .crystal),
                .bounce(id: 1, at: Vec2(x: 550, y: 250), velocity: Vec2(x: -80, y: 70), radius: 26, material: .ice),
                .bounce(id: 2, at: Vec2(x: 150, y: 480), velocity: Vec2(x: 75, y: -65), radius: 26, material: .geode),
                .bounce(id: 3, at: Vec2(x: 550, y: 480), velocity: Vec2(x: -90, y: -55), radius: 26, material: .iron),
            ],
            echoInterval: 8.5, maxEchoes: 3, par: 32,
            theme: .dawn
        ),
        room(
            35, "Grand Complication", "Every mechanism at once.",
            start: Vec2(x: 80, y: 70), exit: Vec2(x: 600, y: 620),
            walls: [AABB(x: 0, y: 460, width: 280, height: 30), AABB(x: 420, y: 460, width: 280, height: 30)],
            sparks: [
                SparkSpawn(id: 0, position: Vec2(x: 120, y: 120)),
                SparkSpawn(id: 1, position: Vec2(x: 580, y: 120)),
                SparkSpawn(id: 2, position: Vec2(x: 350, y: 600), timer: 16),
                SparkSpawn(id: 3, position: Vec2(x: 100, y: 600)),
            ],
            movers: [.orbit(id: 0, center: Vec2(x: 350, y: 600), radius: 50, period: 6, phase: 0, size: 24, material: .crystal)],
            gates: [TimeGateSpawn(id: 0, area: AABB(x: 280, y: 460, width: 140, height: 30), period: 5.5, openFor: 2.2, phase: 1)],
            lasers: [.sweeping(id: 0, center: Vec2(x: 350, y: 260), length: 400, from: 0, to: .pi / 2, sweepDuration: 3, period: 6, chargeFor: 1.4, activeFor: 1.4)],
            echoInterval: 8, maxEchoes: 3, par: 34,
            theme: .dawn
        ),
        room(
            36, "Observatory Trial", "The last test: read everything.",
            start: Vec2(x: 80, y: 350), exit: Vec2(x: 350, y: 650),
            sparks: [Vec2(x: 100, y: 100), Vec2(x: 100, y: 600), Vec2(x: 600, y: 100), Vec2(x: 350, y: 570)],
            movers: [
                .stationary(id: 0, at: Vec2(x: 350, y: 350), radius: 60),
                .orbit(id: 1, center: Vec2(x: 350, y: 350), radius: 160, period: 8, phase: 0, size: 26, material: .crystal),
                .orbit(id: 2, center: Vec2(x: 350, y: 350), radius: 160, period: 8, phase: .pi * 2 / 3, size: 26, material: .ice),
                .orbit(id: 3, center: Vec2(x: 350, y: 350), radius: 160, period: 8, phase: .pi * 4 / 3, size: 26, material: .basalt),
            ],
            lasers: [
                .horizontal(id: 0, y: 620, fromX: 40, toX: 660, period: 6.5, chargeFor: 1.4, activeFor: 1.3, phase: 2),
                .vertical(id: 1, x: 620, fromY: 40, toY: 560, period: 6.5, chargeFor: 1.4, activeFor: 1.3, phase: 5),
            ],
            echoInterval: 8, maxEchoes: 4, par: 36,
            theme: .dawn
        ),
    ]
}
