import XCTest
@testable import Echo

@MainActor
final class HUDCoverageTests: XCTestCase {
    func testHUDWithEveryStatusBadge() {
        let session = GameSession(level: LevelCatalog.prototype, daily: false)
        session.configure(tuning: PlayerTuning())
        session.effects.shieldCharges = 2
        session.effects.freezeRemaining = 2
        session.effects.surgeRemaining = 2
        session.effects.magnetRemaining = 2
        session.effects.phaseRemaining = 2
        session.effects.anchorRemaining = 2
        session.effects.prismRemaining = 2
        session.resonanceChain = 4
        session.resonanceRemaining = 2
        session.reality = .candy
        session.realityRemaining = 4
        session.warning = true
        session.exitOpen = true
        session.hasStarted = true
        session.nextEchoIn = 1.2
        session.banner = "Resonance ×4"
        session.abilityCooldowns[.shield] = 1.6
        session.abilityCooldowns[.freeze] = 0.8
        let model = CoverageFixtures.model()
        CoverageHost.render(HUDBar(session: session, onPause: {}))
        CoverageHost.render(InventoryBar(session: session, onUse: { _ in }).environment(model))

        let quiet = GameSession(level: LevelCatalog.prototype, daily: true)
        CoverageHost.render(HUDBar(session: quiet, onPause: {}))
        CoverageHost.render(InventoryBar(session: quiet, onUse: { _ in }).environment(CoverageFixtures.model(rich: false)))
    }
}
