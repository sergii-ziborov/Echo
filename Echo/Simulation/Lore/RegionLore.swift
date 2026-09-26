import Foundation

/// The story the maps sit in (canon 0.2). After the Break, the Keepers'
/// recovery network began replaying recorded movement; the Signal carries
/// new state records down the Fold Road, and each act is one region of
/// space along it. Every word lives in the string catalog under
/// `region.<key>.*`; this file keeps what is not words: each region's
/// colours, air and sky landmark.
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
    /// Stable key of the region's texts in the catalog.
    var key: String {
        switch self {
        case .trace: "trace"
        case .drift: "drift"
        case .fracture: "fracture"
        case .debris: "debris"
        case .paradox: "paradox"
        case .singularity: "singularity"
        case .rift: "rift"
        case .gravity: "gravity"
        case .mirage: "mirage"
        case .confection: "confection"
        case .eternity: "eternity"
        }
    }

    /// Where on the Fold Road the region lies.
    var region: String { Copy.text("region.\(key).name") }

    /// Two sentences for the arrival card.
    var intro: String { Copy.text("region.\(key).arrival") }

    /// What the region's name means, for the Archive.
    var meaning: String { Copy.text("region.\(key).meaning") }

    /// Where the fiction parts with real science, for the Archive.
    var scienceNote: String { Copy.text("region.\(key).science") }

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
