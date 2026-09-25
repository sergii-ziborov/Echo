import Foundation

extension LevelCatalog {
    static func expandedLevel(_ number: Int) -> LevelDefinition {
        let names = [
            "Corona", "Twinfire", "Redshift", "Lensing", "Pulse Crown", "Zero Hour",
            "First Tear", "Foldline", "Split Realm", "Backstep", "False Door", "Broken Axis", "Rift Heart",
            "Dark Tide", "Orbit Fall", "Gravity Choir", "Bent Route", "Well Spring", "Tidal Lock", "Dark Star",
            "Doppelglass", "Inversion", "False North", "Phase Garden", "Echo Mask", "Glass Labyrinth", "Dream Collapse",
            "Sugar Static", "Gumdrop Orbit", "Frosting Rail", "Candy Comet", "Crystal Syrup", "Sweet Paradox", "Candy Timeline",
            "Last Dawn", "All Pasts", "Infinite Scar", "Final Mirror", "Event Crown", "Forever Loop", "Eternal Echo",
        ]
        let subtitles = [
            "Read the light before it fires.",
            "Two safe lanes never stay safe together.",
            "The arena accelerates behind you.",
            "An immovable core commands three orbiting shards.",
            "Break the firing rhythm at its center.",
            "Survive every law of the horizon.",
            "The first door opens somewhere else.",
            "Cross once; return on a different axis.",
            "One arena, two incompatible routes.",
            "The tear sends your timeline backward.",
            "The fold moves. The asteroid core does not.",
            "Steering changes when the world folds.",
            "Use the breach before it uses you.",
            "The dark pulls long before it kills.",
            "Orbit wide, then cut across the tide.",
            "Three moving bodies share one gravity song.",
            "Your straightest route will bend.",
            "Collect at the edge of the pull.",
            "The well and the laser keep one clock.",
            "Nothing escapes without a planned loop.",
            "The reflection is mechanically real.",
            "Left becomes wrong for four seconds.",
            "Trust the crystal, not the compass.",
            "Phase through the route the map denies.",
            "Three reflections circle a single fixed danger.",
            "Walls are honest; the breach is not.",
            "Wake before the mirrored world closes.",
            "A sweeter reality runs faster.",
            "Orbit the gumdrops, avoid your old line.",
            "Candy rails still carry lethal light.",
            "The pretty path has moving teeth.",
            "One candy moon, three restless satellites.",
            "Build resonance while the rules are soft.",
            "Enter hungry. Leave before it hardens.",
            "Everything learned returns at once.",
            "Every route you made is waiting.",
            "Scars, wells and tears share the arena.",
            "Cross the fold without trusting your hand.",
            "Take the center between four pulses.",
            "The loop ends only when you outrun it.",
            "Seventy-seven epochs answer with one final echo.",
        ]
        let slot = (number - 1) % 7
        let act = Act.containing(level: number)
        let start: Vec2 = slot.isMultiple(of: 2) ? Vec2(x: 120, y: 120) : Vec2(x: 880, y: 120)
        let exit: Vec2 = slot == 6
            ? Vec2(x: 650, y: 840)
            : (slot.isMultiple(of: 2) ? Vec2(x: 850, y: 840) : Vec2(x: 150, y: 840))

        let usesGravity = act == .gravity || act == .eternity
        let hasAsteroidCore = slot == 4 && !usesGravity
        let defaultWalls: [AABB] = switch slot {
        case 0: [
            AABB(x: 245, y: 260, width: 250, height: 48),
            AABB(x: 505, y: 692, width: 250, height: 48),
            AABB(x: 245, y: 470, width: 95, height: 48),
            AABB(x: 660, y: 482, width: 95, height: 48),
        ]
        case 1: [
            AABB(x: 245, y: 170, width: 48, height: 270),
            AABB(x: 707, y: 560, width: 48, height: 270),
            AABB(x: 390, y: 300, width: 220, height: 46),
            AABB(x: 390, y: 654, width: 220, height: 46),
        ]
        case 2: [
            AABB(x: 145, y: 390, width: 245, height: 50),
            AABB(x: 610, y: 560, width: 245, height: 50),
            AABB(x: 330, y: 145, width: 50, height: 190),
            AABB(x: 620, y: 665, width: 50, height: 190),
        ]
        case 3: [
            AABB(x: 190, y: 215, width: 210, height: 46),
            AABB(x: 190, y: 215, width: 46, height: 205),
            AABB(x: 600, y: 739, width: 210, height: 46),
            AABB(x: 764, y: 580, width: 46, height: 205),
        ]
        case 4: [
            AABB(x: 180, y: 315, width: 240, height: 46),
            AABB(x: 580, y: 315, width: 240, height: 46),
            AABB(x: 310, y: 640, width: 165, height: 46),
            AABB(x: 525, y: 640, width: 165, height: 46),
        ]
        case 5: [
            AABB(x: 210, y: 170, width: 46, height: 270),
            AABB(x: 744, y: 170, width: 46, height: 270),
            AABB(x: 210, y: 560, width: 46, height: 270),
            AABB(x: 744, y: 560, width: 46, height: 270),
        ]
        default: fourPillars() + [
            AABB(x: 105, y: 475, width: 175, height: 50),
            AABB(x: 720, y: 475, width: 175, height: 50),
        ]
        }
        let walls = hasAsteroidCore ? [
            AABB(x: 180, y: 190, width: 170, height: 48),
            AABB(x: 650, y: 190, width: 170, height: 48),
            AABB(x: 180, y: 762, width: 170, height: 48),
            AABB(x: 650, y: 762, width: 170, height: 48),
        ] : defaultWalls

        let sparkPositions = [
            usesGravity ? Vec2(x: 500, y: 380) : (hasAsteroidCore ? Vec2(x: 500, y: 210) : Vec2(x: 500, y: 500)),
            Vec2(x: 150, y: 500), Vec2(x: 850, y: 500),
            Vec2(x: 500, y: 150), Vec2(x: 500, y: 850), Vec2(x: 270, y: 720),
            Vec2(x: 730, y: 280), Vec2(x: 730, y: 720),
        ]
        let sparks = sparkPositions.enumerated().map { index, position in
            SparkSpawn(
                id: index,
                position: position,
                timer: index == 1 || index == 6 ? TimeInterval(19 + slot) : nil,
                orbit: index == 7 && act.rawValue >= Act.gravity.rawValue
                    ? SparkOrbit(center: position, radius: 54, period: 7.5 + Double(slot) * 0.25)
                    : nil
            )
        }

        let moverCount = min(4, 2 + max(0, act.rawValue - 6) / 2)
        let moverSeeds: [(Vec2, Vec2)] = [
            (Vec2(x: 225, y: 555), Vec2(x: 92, y: 72)),
            (Vec2(x: 775, y: 445), Vec2(x: -84, y: 88)),
            (Vec2(x: 500, y: 235), Vec2(x: 118, y: -54)),
            (Vec2(x: 500, y: 765), Vec2(x: -110, y: -62)),
        ]
        let movers: [MoverSpawn]
        if hasAsteroidCore {
            let center = Vec2(x: 500, y: 500)
            let orbitPeriod = 10.5 - Double(act.rawValue - Act.singularity.rawValue) * 0.45
            movers = [
                .stationary(id: 0, at: center, radius: 130),
                .orbit(id: 1, center: center, radius: 210, period: orbitPeriod, phase: 0, size: ArenaMetrics.satelliteRadius),
                .orbit(id: 2, center: center, radius: 210, period: orbitPeriod, phase: .pi * 2 / 3, size: ArenaMetrics.satelliteRadius),
                .orbit(id: 3, center: center, radius: 210, period: orbitPeriod, phase: .pi * 4 / 3, size: ArenaMetrics.satelliteRadius),
            ]
        } else if slot == 2 {
            let center = Vec2(x: 500, y: 500)
            movers = [
                .orbit(id: 0, center: center, radius: 92, period: 7.8, size: 22),
                .orbit(id: 1, center: center, radius: 92, period: 7.8, phase: .pi, size: 22),
            ] + moverSeeds.dropFirst(2).prefix(max(0, moverCount - 2)).enumerated().map { index, seed in
                .bounce(id: index + 2, at: seed.0, velocity: seed.1, radius: 38 + Double((index + 2 + slot) % 3) * 4)
            }
        } else if slot == 3 {
            movers = [
                .patrol(id: 0, from: Vec2(x: 300, y: 340), to: Vec2(x: 700, y: 340), radius: 27),
                .patrol(id: 1, from: Vec2(x: 650, y: 360), to: Vec2(x: 650, y: 650), radius: 25),
            ] + moverSeeds.dropFirst(2).prefix(max(0, moverCount - 2)).enumerated().map { index, seed in
                .bounce(id: index + 2, at: seed.0, velocity: seed.1, radius: 38 + Double((index + 2 + slot) % 3) * 4)
            }
        } else {
            movers = moverSeeds.prefix(moverCount).enumerated().map { index, seed in
                .bounce(id: index, at: seed.0, velocity: seed.1, radius: 38 + Double((index + slot) % 3) * 4)
            }
        }

        let riftKind: RiftKind? = switch act {
        case .rift, .mirage: .warp
        case .confection: .candy
        case .eternity: slot.isMultiple(of: 2) ? .warp : .candy
        case .singularity: slot >= 4 ? .collision : nil
        default: nil
        }
        let riftPositions = [
            Vec2(x: 500, y: 600), Vec2(x: 360, y: 500), Vec2(x: 300, y: 700),
            Vec2(x: 360, y: 500), Vec2(x: 120, y: 620), Vec2(x: 840, y: 610),
            Vec2(x: 340, y: 500),
        ]
        let rifts = riftKind.map {
            [RiftSpawn(id: 0, kind: $0, position: riftPositions[slot], radius: 48, period: 7.2, openFor: 3.0, phase: Double(slot) * 0.7)]
        } ?? []

        let gravityWells: [GravityWellSpawn] = usesGravity
            ? [GravityWellSpawn(id: 0, position: Vec2(x: 500, y: 500), coreRadius: 34, influenceRadius: 190, strength: 250)]
            : []

        var lasers: [LaserSpawn] = [
            slot.isMultiple(of: 2)
                ? .horizontal(id: 0, y: 390, period: 7.4, chargeFor: 1.6, activeFor: 1.25, phase: 1.1)
                : .vertical(id: 0, x: 500, period: 7.4, chargeFor: 1.6, activeFor: 1.25, phase: 1.1),
        ]
        if act.rawValue >= Act.rift.rawValue {
            lasers.append(
                slot.isMultiple(of: 3)
                    ? .vertical(id: 1, x: 680, period: 8.6, chargeFor: 1.7, activeFor: 1.3, phase: 4.0)
                    : .horizontal(id: 1, y: 690, period: 8.6, chargeFor: 1.7, activeFor: 1.3, phase: 4.0)
            )
        }
        if number == 77 {
            lasers.append(.sweeping(id: 2, center: Vec2(x: 500, y: 500), length: 860, from: 0, to: .pi, sweepDuration: 5.2, beamWidth: 15, period: 9.2, chargeFor: 1.8, activeFor: 1.2))
        }

        let featuredBonus: BonusKind = switch act {
        case .singularity: slot.isMultiple(of: 2) ? .prism : .anchor
        case .rift: slot.isMultiple(of: 2) ? .blink : .phase
        case .gravity: slot.isMultiple(of: 2) ? .repulse : .anchor
        case .mirage: slot.isMultiple(of: 2) ? .prism : .blink
        case .confection: slot.isMultiple(of: 2) ? .surge : .magnet
        case .eternity: [.anchor, .repulse, .prism, .blink][slot % 4]
        default: slot.isMultiple(of: 2) ? .freeze : .phase
        }
        let supportBonus: BonusKind = switch act {
        case .singularity: .chrono
        case .rift: .pulse
        case .gravity: .surge
        case .mirage: .phase
        case .confection: .pulse
        case .eternity: [.chrono, .freeze, .shield][slot % 3]
        default: .shield
        }

        return make(
            number: number,
            name: names[number - 37],
            subtitle: subtitles[number - 37],
            playerStart: start,
            exit: exit,
            walls: walls,
            sparks: sparks,
            echoInterval: max(5.0, 6.7 - Double(act.rawValue - 6) * 0.18),
            maxEchoes: act == .eternity ? 7 : 6,
            parTime: 46 + Double(slot) * 1.8,
            parMoves: 82 + slot * 3,
            playerSpeed: act == .confection ? 345 : 330,
            bonuses: [
                BonusSpawn(id: 0, kind: featuredBonus, position: Vec2(x: 500, y: 92)),
                BonusSpawn(id: 1, kind: supportBonus, position: Vec2(x: 500, y: 908)),
            ],
            fields: slot == 2 || act == .mirage
                ? [SlowField(id: 0, area: AABB(x: 405, y: 405, width: 190, height: 190))]
                : [],
            movers: movers,
            rifts: rifts,
            gates: slot == 1 || slot == 5
                ? [TimeGateSpawn(id: 0, area: AABB(x: 330, y: 476, width: 340, height: 48), period: 6.2, openFor: 2.5, phase: 1.2)]
                : [],
            lasers: lasers,
            gravityWells: gravityWells,
            theme: .forLevel(number),
            atmosphere: [0, 3, 5].contains(slot) ? .clear : (slot == 2 || slot == 6 ? .nebula : .drift)
        )
    }

    static func daily(on day: Date = Date(), calendar: Calendar = .current) -> LevelDefinition {
        let start = calendar.startOfDay(for: day)
        let year = calendar.component(.year, from: start)
        let month = calendar.component(.month, from: start)
        let dayNum = calendar.component(.day, from: start)
        let seed = UInt64(year) * 10_000 + UInt64(month) * 100 + UInt64(dayNum)
        var rng = SplitMix64(seed: seed)

        let templates = [1, 3, 8, 13, 16, 21, 25, 30, 31, 33, 36]
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
        // The Daily Rift reopens a known stop of the Road, so it keeps that region's look.
        return level.sanitized()
    }
}
