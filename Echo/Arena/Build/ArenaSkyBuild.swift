import SpriteKit
import UIKit

extension GameScene {
    /// The sky says where on the Fold Road the map lies: its region's
    /// landmark, drawing nearer across the region, under the region's
    /// colours. It holds still when the system asks for reduced motion.
    func buildBackdrop() {
        let level = session.level
        let theme = level.theme
        let sky = Backdrop(
            size: size,
            palette: Backdrop.Palette(sky: theme.sky.uiColor, glow: theme.nebula.uiColor, accent: theme.wallStroke.uiColor),
            seed: UInt64(RemoteLevel.token(of: Data(level.id.utf8))),
            landmark: level.region.landmark,
            progress: level.regionProgress,
            motion: !UIAccessibility.isReduceMotionEnabled
        )
        sky.root.zPosition = -20
        addChild(sky.root)
        backdrop = sky
    }
}
