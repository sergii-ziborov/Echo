import Foundation

enum LegacyAssessment: Equatable { case eligible, notEligible, unresolved }

struct CutoverPolicy: Codable, Equatable, Sendable {
    var id: String
    var approved: Bool
    var legacyEligibilityEnd: Date
    /// Until this boundary has passed, conflicting/rollout acquisitions remain protected.
    var rolloutUncertaintyEnd: Date
    var paidBuilds: [String]?
    /// Explicitly protected free builds released during the approved goodwill window.
    /// Separate from the historical paid-build evidence; old policies decode this as nil.
    var goodwillBuilds: [String]?
}

enum LegacyEligibility {
    static func assess(_ acquisition: OriginalAcquisition, policy: ReleasePolicy) -> LegacyAssessment {
        guard acquisition.bundleID == MonetizationConfiguration.bundleID else { return .unresolved }
        switch acquisition.environment {
        case .sandbox, .xcode: return .notEligible // Explicit test policy: never manufacture legacy.
        case .unknown: return .unresolved
        case .production: break
        }
        guard let cutover = policy.cutover, cutover.approved, !cutover.id.isEmpty,
              let paidBuilds = cutover.paidBuilds, !paidBuilds.isEmpty,
              cutover.rolloutUncertaintyEnd >= cutover.legacyEligibilityEnd,
              acquisition.originalPurchaseDate.timeIntervalSince1970 > 0,
              !acquisition.originalBuild.isEmpty else { return .unresolved }
        if acquisition.originalPurchaseDate <= cutover.legacyEligibilityEnd {
            let protectedBuild = paidBuilds.contains(acquisition.originalBuild)
                || (cutover.goodwillBuilds ?? []).contains(acquisition.originalBuild)
            return protectedBuild ? .eligible : .unresolved
        }
        if acquisition.originalPurchaseDate <= cutover.rolloutUncertaintyEnd { return .unresolved }
        // Never use a version-only, install-date or local-progress heuristic.
        return .notEligible
    }
}
