import SpriteKit
import SwiftUI
import UIKit
@testable import Echo

@MainActor
enum CoverageHost {
    static let size = CGSize(width: 390, height: 844)

    private static var window: UIWindow?
    private static var retainedSession: GameSession?

    static func teardown() {
        if let root = window?.rootViewController?.view {
            retainScenes(from: root)
            detachSpriteKit(from: root)
        }
        window?.rootViewController = nil
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        retainedSession = nil
    }

    @discardableResult
    static func render<V: View>(_ view: V, size: CGSize = size) -> UIView {
        teardown()
        let host = UIHostingController(rootView: view)
        host.safeAreaRegions = []
        let frame = CGRect(origin: .zero, size: size)
        if window == nil {
            window = UIWindow(frame: frame)
        }
        let window = window!
        window.frame = frame
        window.rootViewController = host
        window.isHidden = false
        host.view.frame = frame
        host.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        host.view.setNeedsDisplay()
        host.view.layoutIfNeeded()
        return host.view
    }

    static func renderCanvas<V: View>(_ view: V) {
        let renderer = ImageRenderer(content: view.frame(width: size.width, height: 220))
        renderer.scale = 1
        _ = renderer.uiImage
    }

    @discardableResult
    static func present(_ scene: GameScene) -> SKView {
        teardown()
        retainedSession = scene.session
        let frame = CGRect(origin: .zero, size: size)
        let host = UIViewController()
        let skView = SKView(frame: frame)
        skView.isPaused = false
        host.view.addSubview(skView)
        if window == nil {
            window = UIWindow(frame: frame)
        }
        let window = window!
        window.frame = frame
        window.rootViewController = host
        window.isHidden = false
        skView.presentScene(scene)
        scene.resize(to: size)
        scene.rebuild()
        return skView
    }

    private static func retainScenes(from view: UIView) {
        if let skView = view as? SKView, let scene = skView.scene as? GameScene {
            retainedSession = scene.session
        }
        view.subviews.forEach { retainScenes(from: $0) }
    }

    private static func detachSpriteKit(from view: UIView) {
        if let skView = view as? SKView {
            skView.isPaused = true
            skView.presentScene(nil)
        }
        view.subviews.forEach { detachSpriteKit(from: $0) }
    }
}

@MainActor
enum CoverageFixtures {
    static func model(rich: Bool = true) -> AppModel {
#if DEBUG
        SoundPlayer.testSilent = true
#endif
        let name = "echo.coverage.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        let model = AppModel()
        model.progress = ProgressStore(defaults: defaults)
        model.progress.markTutorialSeen()
        model.progress.soundEnabled = true
        model.progress.hapticsEnabled = true
        model.audio.enabled = false
        model.audio.setHapticsEnabled(false)
        guard rich else { return model }

        model.progress.addShards(80_000)
        let win = SessionResult(
            time: 18,
            moves: 12,
            stars: 3,
            sparks: 6,
            echoesFaced: 2,
            bonuses: 1,
            timeCrystals: 1,
            resonance: 3,
            dashed: true,
            usedItem: true,
            scars: 1,
            riftsUsed: 1,
            closest: 0.2
        )
        for level in LevelCatalog.playable {
            model.progress.recordWin(levelID: level.id, result: win)
        }
        for kind in UpgradeKind.allCases {
            while model.progress.canUpgrade(kind) {
                _ = model.progress.buyUpgrade(kind)
            }
        }
        for kind in BonusKind.allCases where kind.useFromBar {
            _ = model.progress.buy(kind)
            _ = model.progress.toggleEquipped(kind)
        }
        for hint in EncounterHint.allCases {
            _ = model.progress.markHint(hint.rawValue)
        }
        return model
    }

    static func rooted(_ screen: Screen, model: AppModel) -> some View {
        model.screen = screen
        return RootView().environment(model)
    }

    static func playRequest(_ number: Int, daily: Bool = false) -> PlayRequest {
        PlayRequest(
            levelID: LevelCatalog.level(number: number)?.id ?? LevelCatalog.prototype.id,
            daily: daily
        )
    }
}

extension EncounterHint: CaseIterable {
    public static var allCases: [EncounterHint] {
        [
            .echo, .asteroid, .rift, .freeze, .phase, .collision, .gate, .laser,
            .timeCrystal, .resonance, .blackHole, .realityShift, .surge, .pulse,
            .magnet, .chrono, .anchor, .repulse, .prism, .blink,
        ]
    }
}
