import SpriteKit
import SwiftUI
import UIKit

extension Backdrop.Budget {
    /// The Atlas shows a region's sky with nothing on top of it but the
    /// route, so the landmark can be a little brighter than in play.
    static let atlas = Backdrop.Budget(stars: 36, meteorGap: 3...7, textureScale: 2, lightSweep: true, planetScale: 1, planetAlpha: 0.6)
}

/// The same sky the region's maps are played under: its landmark, galaxy,
/// stars and meteors, behind the route through the region.
final class AtlasSkyScene: SKScene {
    private var backdrop: Backdrop?

    init(act: Act, size: CGSize, progress: Double, motion: Bool) {
        super.init(size: size)
        scaleMode = .resizeFill
        let theme = act.theme
        backgroundColor = theme.sky.uiColor
        guard size.width > 20, size.height > 20 else { return }
        let sky = Backdrop(
            size: size,
            palette: Backdrop.Palette(sky: theme.sky.uiColor, glow: theme.nebula.uiColor, accent: theme.wallStroke.uiColor),
            seed: UInt64(act.rawValue) &* 0x9E37_79B9_7F4A_7C15,
            landmark: act.landmark,
            progress: progress,
            budget: .atlas,
            motion: motion
        )
        addChild(sky.root)
        backdrop = sky
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) { nil }

    override func update(_ currentTime: TimeInterval) {
        backdrop?.tick(now: currentTime)
    }
}

/// Builds the sky once per region and size; SwiftUI asks for it on every pass.
@MainActor
final class AtlasSkyCache {
    private var key = ""
    private var scene: AtlasSkyScene?

    func scene(act: Act, size: CGSize, progress: Double, motion: Bool) -> AtlasSkyScene {
        let key = "\(act.rawValue)-\(Int(size.width))x\(Int(size.height))-\(motion)"
        if let scene, key == self.key { return scene }
        let built = AtlasSkyScene(act: act, size: size, progress: progress, motion: motion)
        self.key = key
        scene = built
        return built
    }
}

struct AtlasRouteSky: View {
    let act: Act
    /// How much of the region is cleared; the landmark draws nearer.
    let progress: Double
    let motion: Bool
    @State private var cache = AtlasSkyCache()

    var body: some View {
        GeometryReader { geometry in
            SpriteView(
                scene: cache.scene(act: act, size: geometry.size, progress: progress, motion: motion),
                preferredFramesPerSecond: 30,
                options: [.ignoresSiblingOrder]
            )
        }
        .overlay {
            // Keep the route legible over the brightest parts of the sky.
            RadialGradient(
                colors: [.clear, EchoTheme.navyDeep.opacity(0.55)],
                center: .center,
                startRadius: 80,
                endRadius: 260
            )
        }
        .overlay(alignment: .top) {
            LinearGradient(colors: [EchoTheme.navyDeep.opacity(0.75), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 64)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
