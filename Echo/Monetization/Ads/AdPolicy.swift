import Foundation

enum AdPlacement: String, Codable, Sendable { case campaignResultToNext, death, retry, rewind, menu }

struct AdContext: Equatable, Sendable {
    var runID: UUID
    var resultID: UUID
    var placement = AdPlacement.campaignResultToNext
    var campaignNumber: Int
    var isEducational = false
    var hasMajorDiscovery = false
    var isChapterEnd = false
    var usedWatchRemote = false
    var isDaily = false
    var isEndless = false
    var hasModal = false
    var isForeground = true
    var nextIntentIsCurrent = true
    var uniqueCampaignClears = 0
    var isTestingRun = false
    var isOnline = true

    var isEligibleWin: Bool {
        placement == .campaignResultToNext && campaignNumber > 5 && !isEducational && !hasMajorDiscovery
            && !isChapterEnd && !usedWatchRemote && !isDaily && !isEndless && !isTestingRun
    }
}

struct AdCreative: Equatable, Sendable {
    var id = UUID()
    var loadedAt: Date
    var privacyGeneration: UInt64
    var entitlementGeneration: UInt64
    var policyVersion: UInt64
}

enum AdDecision: Equatable {
    case allow
    case deny(Reason)
    enum Reason: String { case releaseNotEnabled, entitlementProtected, privacy, placement, protectedLevel,
        protectedContent, protectedMode, presentationState, onboarding, cadence, dailyCap, notReady, clock, offline }
}

enum AdPolicy {
    static func evaluate(context: AdContext, entitlement: EntitlementState, privacyAllowed: Bool,
        release: ReleasePolicy, budget: AdBudget, creative: AdCreative?, now: Date,
        privacyGeneration: UInt64, entitlementGeneration: UInt64, preparing: Bool = false) -> AdDecision {
        guard release.permitsAds(at: now) else { return .deny(.releaseNotEnabled) }
        guard entitlement.isConclusiveFree else { return .deny(.entitlementProtected) }
        guard context.isOnline else { return .deny(.offline) }
        guard privacyAllowed else { return .deny(.privacy) }
        guard context.placement == .campaignResultToNext else { return .deny(.placement) }
        guard context.campaignNumber > 5 else { return .deny(.protectedLevel) }
        guard !context.isEducational, !context.hasMajorDiscovery, !context.isChapterEnd else { return .deny(.protectedContent) }
        guard !context.usedWatchRemote, !context.isDaily, !context.isEndless, !context.isTestingRun else { return .deny(.protectedMode) }
        guard !context.hasModal, context.isForeground, context.nextIntentIsCurrent else { return .deny(.presentationState) }
        guard context.uniqueCampaignClears >= 5 else { return .deny(.onboarding) }
        guard now >= budget.wallHighWater else { return .deny(.clock) }
        let limits = release.limits.bounded
        guard budget.eligibleWins >= limits.minimumEligibleWins, budget.activeSeconds >= limits.minimumActiveSeconds else { return .deny(.cadence) }
        guard budget.started.filter({ now.timeIntervalSince($0) < 86400 }).count < limits.maxPer24Hours,
              budget.reservation == nil else { return .deny(.dailyCap) }
        if preparing { return .allow }
        guard let creative, now >= creative.loadedAt, now.timeIntervalSince(creative.loadedAt) < limits.cacheMaxAge,
              creative.privacyGeneration == privacyGeneration, creative.entitlementGeneration == entitlementGeneration,
              creative.policyVersion == release.version else { return .deny(.notReady) }
        return .allow
    }
}
