import SpriteKit
import UIKit

extension GameScene {
    /// Each map gets its own distant sky, tinted by its theme; it holds
    /// still when the system asks for reduced motion.
    func buildBackdrop() {
        let theme = session.level.theme
        let sky = Backdrop(
            size: size,
            palette: Backdrop.Palette(sky: theme.sky.uiColor, glow: theme.nebula.uiColor, accent: theme.wallStroke.uiColor),
            seed: UInt64(RemoteLevel.token(of: Data(session.level.id.utf8))),
            motion: !UIAccessibility.isReduceMotionEnabled
        )
        sky.root.zPosition = -20
        addChild(sky.root)
        backdrop = sky
    }
}
