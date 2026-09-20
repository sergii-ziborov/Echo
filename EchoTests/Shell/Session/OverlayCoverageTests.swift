import XCTest
@testable import Echo

@MainActor
final class OverlayCoverageTests: XCTestCase {
    func testEveryDeathCause() {
        let causes: [DeathCause] = [
            .echo(index: 0, delay: 8),
            .echo(index: 3, delay: 24),
            .asteroid, .rift, .collision, .ghost, .laser, .blackHole,
        ]
        for cause in causes {
            CoverageHost.render(
                DeathView(cause: cause, rewindCharges: 2, rewindSeconds: 3, onRewind: {}, onRestart: {}, onMenu: {})
            )
            CoverageHost.render(
                DeathView(cause: cause, rewindCharges: 0, rewindSeconds: 5, onRewind: {}, onRestart: {}, onMenu: {})
            )
            _ = cause.headline
            _ = cause.echoIndex
        }
    }

    func testResultsVariantsAndSeals() {
        let seals: [SealKind] = [
            .beforeEcho(3), .noDash, .maxEchoes(4), .noShop,
            .causeScar, .avoidScar, .parTime, .useRift,
        ]
        let result = SessionResult(
            time: 22, moves: 14, stars: 3, sparks: 6, echoesFaced: 2,
            bonuses: 1, timeCrystals: 2, resonance: 4, dashed: true,
            usedItem: true, scars: 1, riftsUsed: 1, closest: 0.12,
            control: true, paradox: true
        )
        for (control, paradox) in zip(seals, seals.reversed()) {
            CoverageHost.render(
                ResultsView(
                    levelName: "Trace",
                    result: result,
                    controlSeal: control,
                    paradoxSeal: paradox,
                    bestTime: 19,
                    bestMoves: 11,
                    cycleComplete: false,
                    nextDifficulty: DifficultyProfile(cycle: 1),
                    awardedPoints: 180,
                    onWatch: {},
                    onRetry: {},
                    onNext: {},
                    onNextCycle: {},
                    onMenu: {}
                )
            )
        }
        CoverageHost.render(
            ResultsView(
                levelName: "Eternity",
                result: SessionResult(time: 40, moves: 30, stars: 1, sparks: 6, echoesFaced: 5),
                controlSeal: .parTime,
                paradoxSeal: .noDash,
                bestTime: nil,
                bestMoves: nil,
                cycleComplete: true,
                nextDifficulty: DifficultyProfile(cycle: 4),
                awardedPoints: 0,
                onWatch: {},
                onRetry: {},
                onNext: {},
                onMenu: {}
            )
        )
        for seal in seals {
            _ = seal.label
            _ = seal.met(by: result, parTime: 30)
        }
        for cycle in 0...4 {
            _ = DifficultyProfile(cycle: cycle).detail
            _ = DifficultyProfile(cycle: cycle).hazardMultiplier
        }
    }
}
