import Foundation

/// The Game Center achievements. The raw values are the IDs App Store
/// Connect knows them by and never change. Progress is read from saved
/// records, so reporting it again is always safe.
enum Achievement: String, CaseIterable, Sendable {
    case firstLight = "echo.ach.first_light"
    case lighthouse = "echo.ach.lighthouse"
    case ashcrown = "echo.ach.ashcrown"
    case lastDawn = "echo.ach.last_dawn"
    case secondPass = "echo.ach.second_pass"
    case sealKeeper = "echo.ach.seals_100"
    case everySeal = "echo.ach.seals_all"
    case deepDiver = "echo.ach.deep_10"
    case belowTheRoad = "echo.ach.deep_25"
    case dailyRift = "echo.ach.daily_rift"
    case calibrated = "echo.ach.calibration"
    case regulated = "echo.ach.regulation"
    case certified = "echo.ach.certification"
    case aheadOfTime = "echo.ach.under_par"
    case signalMatrix = "echo.ach.research"

    /// Game Center points; the whole set stays under Apple's 1000.
    var points: Int {
        switch self {
        case .firstLight: 10
        case .lighthouse, .dailyRift: 25
        case .ashcrown, .sealKeeper, .deepDiver, .calibrated: 50
        case .signalMatrix: 60
        case .regulated, .aheadOfTime: 75
        case .lastDawn, .secondPass, .everySeal, .belowTheRoad, .certified: 100
        }
    }

    /// Rooms with a best time at or under par that `aheadOfTime` asks for.
    static let roomsUnderPar = 12

    /// Progress from 0 to 100 against the saved records.
    @MainActor
    func percent(_ progress: ProgressStore) -> Double {
        switch self {
        case .firstLight:
            return progress.lifetimeStars > 0 ? 100 : 0
        case .lighthouse:
            return Self.share(of: .trace, progress)
        case .ashcrown:
            return Self.share(of: .singularity, progress)
        case .lastDawn:
            let cleared = LevelCatalog.playable.filter { progress.progress(for: $0.id).stars > 0 }.count
            return progress.hasFinishedCampaign ? 100 : Self.ratio(cleared, LevelCatalog.playable.count)
        case .secondPass:
            return Self.ratio(progress.completedDifficultyCycles, 2)
        case .sealKeeper:
            return Self.ratio(progress.lifetimeStars, 100)
        case .everySeal:
            return Self.ratio(progress.totalStars, LevelCatalog.playable.count * 3)
        case .deepDiver:
            return Self.ratio(progress.endless.bestDepth, 10)
        case .belowTheRoad:
            return Self.ratio(progress.endless.bestDepth, 25)
        case .dailyRift:
            return progress.lastDailyKey == nil ? 0 : 100
        case .calibrated:
            return Self.rooms(1...12, progress.wrist)
        case .regulated:
            return Self.rooms(13...24, progress.wrist)
        case .certified:
            return Self.rooms(1...WristCatalog.maps.count, progress.wrist)
        case .aheadOfTime:
            let fast = WristCatalog.maps.filter { room in
                progress.wrist.bestTimes[room.id].map { $0 <= room.parTime } ?? false
            }.count
            return Self.ratio(fast, Self.roomsUnderPar)
        case .signalMatrix:
            let researched = UpgradeKind.allCases.filter { progress.upgradeLevel($0) > 0 }.count
            return Self.ratio(researched, UpgradeKind.allCases.count)
        }
    }

    private static func ratio(_ count: Int, _ goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return (Double(min(count, goal)) / Double(goal) * 100).rounded()
    }

    @MainActor
    private static func share(of act: Act, _ progress: ProgressStore) -> Double {
        if progress.hasCleared(act) { return 100 }
        let cleared = act.range.filter { number in
            LevelCatalog.level(number: number).map { progress.progress(for: $0.id, cycle: 0).stars > 0 } ?? false
        }.count
        return ratio(cleared, act.range.count)
    }

    private static func rooms(_ numbers: ClosedRange<Int>, _ wrist: WristProgress) -> Double {
        ratio(numbers.filter { wrist.cleared.contains("wrist-\($0)") }.count, numbers.count)
    }
}
