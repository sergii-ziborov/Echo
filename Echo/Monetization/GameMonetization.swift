import SwiftUI

extension GameView {
    var adContext: AdContext {
        let progress = activeModel.progress
        return AdContext(runID: session.runID, resultID: session.runID, campaignNumber: session.level.number,
            // All current/unknown discoveries are protected. Reading one does not clear this flag.
            isEducational: session.level.region == .confection,
            hasMajorDiscovery: session.hasProtectedDiscovery,
            isChapterEnd: session.level.number % 7 == 0 || session.level.number == LevelCatalog.playable.count,
            usedWatchRemote: session.usedWatchRemote, isDaily: request.daily, isEndless: request.endless != nil,
            hasModal: overlay != .none, isForeground: scenePhase == .active,
            nextIntentIsCurrent: !session.nextRequested,
            uniqueCampaignClears: LevelCatalog.playable.filter { progress.progress(for: $0.id, cycle: 0).stars > 0 }.count,
            isTestingRun: ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-shot-") })
    }
    func prepareResultAdvertising() {
        let context = adContext
        activeModel.monetization.prepare(context: context) {
            if case .won = session.phase { return !session.nextRequested && !session.usedWatchRemote && overlay == .none
                && activeModel.screen == .playing(request) }
            return false
        }
    }
    func disappearedFromGame() {
        // UIKit fullscreen ad/consent presentation is not a navigation away from this result.
        if activeModel.screen == .playing(request), activeModel.monetization.modal.owner != nil { return }
        PhoneWatchLink.shared.detach(session: session)
        activeModel.monetization.leaveResult()
    }
    func monetizedNext() {
        let context = adContext
        guard !session.nextRequested else { return }
        session.nextRequested = true
        session.inputTarget = nil
        PhoneWatchLink.shared.stopInput()
        // No simulation of the next map exists while a presentation is in progress.
        activeModel.monetization.next(context: context, isCurrent: {
            // Watch suppresses the ad through the freshly captured context, not navigation.
            if case .won = session.phase { return overlay == .none && activeModel.screen == .playing(request) }
            return false
        }, continuation: { continueToNextLevel() })
    }
}
