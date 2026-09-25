import Foundation

/// The story the maps sit in. The orb is the Signal, the last light of the
/// Lighthouse the Keepers built at the rim of the galaxy to hold time
/// steady. Time broke: anything that moves is now replayed a few seconds
/// later. The Signal carries an unbroken present down the Fold Road, a chain
/// of folds that open once enough loose present (the sparks) is gathered and
/// throw it to the next place. Each act is one region of space along the
/// Road, which is why the sky, the walls and the hazards change between acts.
enum RegionLore {
    static let premise = "At the rim of the galaxy the Keepers built the Lighthouse to hold time steady. Time broke anyway: everything that moves is now replayed a few seconds later. The Keepers lit one last Signal — you — to carry an unbroken present down the Fold Road to wherever the break began."

    static let foldRoad = "Every map is one stop on the Fold Road. Sparks are loose seconds of the present; once enough are gathered, the exit opens into a fold that throws the Signal to the next place. That is why the sky changes: each region lies in a different part of space."

    static let loop = "The Road ends where it began. At the end of time the break lies inside the Lighthouse itself, and the last echo is the Signal the moment it was lit. The loop closes, then opens again — each lap more fractured than the last."

    static let deepTime = "Below the Road lies Deep Time: moments no Keeper ever charted, drawn fresh on every dive. They borrow the look of every region, never repeat, and never end."

    static let dailyRift = "Each day a fresh tear reopens one stop of the Road with its sparks scattered anew."

    static let wrist = "The Keepers tuned their light with a chronometer: twelve clockwork rooms in three movements, Tick, Crown and Tourbillon, that now fit on a wrist. Every movement cleared there tunes the Signal on the phone."
}

/// A distant landmark that fixes where in space a region lies.
enum SkyLandmark: Equatable, Sendable {
    /// A banded giant, with or without rings.
    case giant(base: RGB, accent: RGB, rings: Bool)
    /// A star disc with its corona; `size` is a fraction of the short side.
    case sun(core: RGB, corona: RGB, size: Double)
    /// A frozen moon split by glowing cracks.
    case crackedMoon(base: RGB, glow: RGB)
    /// A world broken in two, trailing a ring of its own rubble.
    case brokenWorld(base: RGB, glow: RGB)
    /// A spinning dead star sweeping two beams like a lighthouse.
    case pulsar(color: RGB)
    /// A bright tear across the sky inside coloured clouds.
    case tear(color: RGB)
    /// A black hole with its accretion disc.
    case blackHole(disc: RGB)
    /// One giant and its mirrored copy.
    case twinGiants(base: RGB, accent: RGB)
    /// A sugar-banded world with a little moon.
    case candyWorld(base: RGB, accent: RGB)
    /// The first light of a star rising over the edge of the view.
    case dawn(core: RGB, corona: RGB)
}

extension Act {
    /// Where on the Fold Road the region lies.
    var region: String {
        switch self {
        case .trace: "THE LIGHTHOUSE"
        case .drift: "DRIFT GARDENS"
        case .fracture: "TESSERA SHELF"
        case .debris: "HOLLOW BELT"
        case .paradox: "PROVING GROUNDS"
        case .singularity: "ASHCROWN CORONA"
        case .rift: "THE RIFTLANDS"
        case .gravity: "THE UNDERTOW"
        case .mirage: "GLASS NEBULA"
        case .confection: "CANDY TIMELINE"
        case .eternity: "LAST DAWN"
        }
    }

    /// The story card shown the first time the Signal arrives in the region.
    var intro: String {
        switch self {
        case .trace:
            RegionLore.premise
        case .drift:
            "The first fold throws the Signal into the Drift Gardens: greenhouse domes torn loose from a garden world, drifting under a small red sun. Their airlocks still cycle on broken timers, and they open whether you are ready or not."
        case .fracture:
            "The Road drops onto Tessera, a frozen moon split by the first time scars. Cracks run through its ice shelf, and loose rock has started to drift free."
        case .debris:
            "Beyond Tessera lies the Hollow Belt, all that is left of Cinder, a world the break tore apart. Its crust became basalt, its mantle magma, its heart meteoric iron — and every piece is still moving."
        case .paradox:
            "The Road runs through the Proving Grounds, where the Keepers tested how to lock time. The tests never stopped: sentinel beams still charge and fire on the beat of a dead pulsar, and the locks still keep their own clocks."
        case .singularity:
            "The Proving Grounds circle Ashcrown, a giant star now collapsing into a singularity. Its corona fires on its own, and the heaviest pieces it has shed hold whole swarms of shards in orbit."
        case .rift:
            "Ashcrown's collapse tore the Road into the Riftlands, where space has exits of its own. Warp tears fold you across the arena, and rock from far away — hollow geodes, dusty comets — falls through them."
        case .gravity:
            "Past the Riftlands the Road falls into the Undertow, where Ashcrown's remains collapsed into black holes. The dark pulls long before it kills, and every straight route bends."
        case .mirage:
            "Light bent around the Undertow pours into the Glass Nebula, where space shows mirrored copies of itself. Here a tear does not only move you — it can reflect you."
        case .confection:
            "Falling out of the Glass Nebula, the Signal lands in the Candy Timeline, a pocket reality the broken timeline dreams for itself. Everything is sweeter and faster here, and none of it is safe."
        case .eternity:
            "The last fold opens onto the rim of the galaxy: the Lighthouse, at the end of time. The break began here. Every law you survived returns at once — and so does every route you ever drew."
        }
    }

    var theme: ArenaTheme {
        switch self {
        case .trace: .void
        case .drift: .moss
        case .fracture: .ice
        case .debris: .dust
        case .paradox: .ion
        case .singularity: .ember
        case .rift: .tear
        case .gravity: .abyss
        case .mirage: .ice
        case .confection: .candy
        case .eternity: .dawn
        }
    }

    var atmosphere: ArenaAtmosphere {
        switch self {
        case .trace, .paradox, .eternity: .clear
        case .drift, .fracture, .debris, .gravity: .drift
        case .singularity, .rift, .mirage, .confection: .nebula
        }
    }

    var landmark: SkyLandmark {
        switch self {
        case .trace: .giant(base: RGB(0.55, 0.74, 0.95), accent: RGB(0.85, 0.93, 1.0), rings: true)
        case .drift: .sun(core: RGB(1.0, 0.62, 0.42), corona: RGB(1.0, 0.36, 0.22), size: 0.2)
        case .fracture: .crackedMoon(base: RGB(0.62, 0.72, 0.84), glow: RGB(0.55, 0.9, 1.0))
        case .debris: .brokenWorld(base: RGB(0.62, 0.42, 0.28), glow: RGB(1.0, 0.52, 0.2))
        case .paradox: .pulsar(color: RGB(0.82, 0.6, 1.0))
        case .singularity: .sun(core: RGB(1.0, 0.5, 0.28), corona: RGB(1.0, 0.28, 0.16), size: 0.55)
        case .rift: .tear(color: RGB(1.0, 0.38, 0.72))
        case .gravity: .blackHole(disc: RGB(1.0, 0.62, 0.3))
        case .mirage: .twinGiants(base: RGB(0.62, 0.86, 0.95), accent: RGB(0.9, 0.8, 1.0))
        case .confection: .candyWorld(base: RGB(1.0, 0.6, 0.82), accent: RGB(0.6, 1.0, 0.86))
        case .eternity: .dawn(core: RGB(1.0, 0.9, 0.62), corona: RGB(1.0, 0.7, 0.36))
        }
    }
}

extension LevelDefinition {
    /// The region a map sits in: its act for the campaign and the Daily Rift,
    /// and for Deep Time the region whose look that depth borrows.
    var region: Act {
        number >= 1000
            ? Act(rawValue: (number - 1001) % Act.allCases.count + 1) ?? .trace
            : Act.containing(level: number)
    }

    /// How far into its region a campaign map lies, from 0 to 1, so the
    /// landmark draws nearer as the Signal crosses the region.
    var regionProgress: Double {
        guard number < 1000 else { return 0.5 }
        return Double((max(1, number) - 1) % 7) / 6
    }

    /// Gives the map its region's colours and air.
    func inRegion() -> LevelDefinition {
        var copy = self
        copy.theme = region.theme
        copy.atmosphere = region.atmosphere
        return copy
    }
}
