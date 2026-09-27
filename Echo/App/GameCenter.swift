import GameKit
import UIKit

/// Game Center: one leaderboard per device and the achievements. Signing in
/// is optional and quiet. The system sheet only appears when the player asks
/// for Game Center, nothing in a run depends on it, and scores and progress
/// are sent only when they change.
@MainActor
@Observable
final class GameCenter: NSObject {
    static let shared = GameCenter()

    /// Leaderboard IDs as App Store Connect knows them.
    static let phoneBoard = "echo.rating.iphone"
    static let watchBoard = "echo.rating.watch"

    /// Off in unit tests and screenshot runs, which must not reach Game Center.
    static var isEnabled: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return NSClassFromString("XCTestCase") == nil && !arguments.contains { $0.hasPrefix("-shot-") }
    }

    private(set) var isSignedIn = false
    @ObservationIgnored private var signInSheet: UIViewController?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var sentScores: [String: Int] = [:]
    @ObservationIgnored private var sentPercents: [String: Double] = [:]
    @ObservationIgnored private var onSignIn: (@MainActor () -> Void)?

    /// Asks Game Center who is playing. `onSignIn` runs each time a player
    /// signs in, so records earned while signed out still arrive.
    func start(onSignIn: @escaping @MainActor () -> Void) {
        guard Self.isEnabled, !started else { return }
        started = true
        self.onSignIn = onSignIn
        GKLocalPlayer.local.authenticateHandler = { sheet, _ in
            // GameKit calls this on the main thread.
            MainActor.assumeIsolated {
                let center = GameCenter.shared
                center.signInSheet = sheet
                let signedIn = GKLocalPlayer.local.isAuthenticated
                let fresh = signedIn && !center.isSignedIn
                center.isSignedIn = signedIn
                if fresh { center.onSignIn?() }
            }
        }
    }

    /// Sends both ratings and any achievement progress that moved.
    func sync(_ progress: ProgressStore) {
        guard isSignedIn else { return }
        submit(Ratings.total(Ratings.phone(progress)), to: Self.phoneBoard)
        submit(Ratings.total(Ratings.watch(progress.wrist)), to: Self.watchBoard)
        var moved: [GKAchievement] = []
        for achievement in Achievement.allCases {
            let percent = achievement.percent(progress)
            guard percent > (sentPercents[achievement.rawValue] ?? 0) else { continue }
            sentPercents[achievement.rawValue] = percent
            let report = GKAchievement(identifier: achievement.rawValue)
            report.percentComplete = percent
            report.showsCompletionBanner = true
            moved.append(report)
        }
        guard !moved.isEmpty else { return }
        GKAchievement.report(moved) { _ in }
    }

    /// Opens the leaderboards, or the sign-in sheet for a player who is not
    /// signed in yet.
    func open() {
        guard let presenter = Self.presenter else { return }
        if isSignedIn {
            let dashboard = GKGameCenterViewController(state: .leaderboards)
            dashboard.gameCenterDelegate = self
            presenter.present(dashboard, animated: true)
        } else if let signInSheet {
            presenter.present(signInSheet, animated: true)
        } else if let settings = URL(string: UIApplication.openSettingsURLString) {
            // Game Center is off for this device; its switch lives in Settings.
            UIApplication.shared.open(settings)
        }
    }

    private func submit(_ score: Int, to board: String) {
        guard score > 0, score != sentScores[board] else { return }
        sentScores[board] = score
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [board]) { _ in }
    }

    private static var presenter: UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}

extension GameCenter: GKGameCenterControllerDelegate {
    nonisolated func gameCenterViewControllerDidFinish(_ controller: GKGameCenterViewController) {
        MainActor.assumeIsolated { controller.dismiss(animated: true) }
    }
}
