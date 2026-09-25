import SpriteKit
import UIKit
import WatchKit

/// Rim markers. Anything worth knowing about past the edge of the face is
/// pinned to the rim on the side it lies, and grows brighter as it closes in:
/// rocks in ember orange, echoes in violet, the nearest spark in cyan, and a
/// chevron toward the exit that lights up once it opens.
extension RemoteScopeScene {
    static let markerCount = 10
    static let rockMarker = UIColor(red: 1, green: 0.55, blue: 0.28, alpha: 1)

    /// The distant sky rides on the camera, so it stays put while the arena
    /// slides past underneath the orb.
    func buildBackdrop() {
        let theme = level.theme
        let sky = Backdrop(
            size: size,
            palette: Backdrop.Palette(sky: WatchArenaScene.color(theme.sky), glow: WatchArenaScene.color(theme.nebula), accent: WatchArenaScene.color(theme.wallStroke)),
            seed: UInt64(RemoteLevel.token(of: Data(level.id.utf8))),
            landmark: level.region.landmark,
            progress: level.regionProgress,
            budget: .watch,
            motion: !WKAccessibilityIsReduceMotionEnabled()
        )
        sky.root.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
        sky.root.zPosition = -20
        lens.addChild(sky.root)
        backdrop = sky
    }

    func buildMarkers() {
        markerPool = (0..<Self.markerCount).map { _ in
            let node = SKShapeNode(circleOfRadius: 1)
            node.lineWidth = 0
            node.isHidden = true
            markers.addChild(node)
            return node
        }
        let chevron = CGMutablePath()
        chevron.move(to: CGPoint(x: 5, y: 0))
        chevron.addLine(to: CGPoint(x: -3, y: 4.5))
        chevron.addLine(to: CGPoint(x: -1, y: 0))
        chevron.addLine(to: CGPoint(x: -3, y: -4.5))
        chevron.closeSubpath()
        exitMarker.path = chevron
        exitMarker.fillColor = UIColor(red: 0.55, green: 0.95, blue: 1, alpha: 1)
        exitMarker.strokeColor = .clear
        exitMarker.isHidden = true
        markers.addChild(exitMarker)
    }

    func updateMarkers(_ frame: RemoteFrame) {
        let half = CGSize(width: size.width / 2, height: size.height / 2)
        // Warn about anything up to one face-width past the rim.
        let reach = CGFloat(Self.window) * scale
        var marks: [(offset: CGPoint, color: UIColor, closeness: CGFloat)] = []

        func offset(of world: Vec2) -> CGPoint {
            let p = point(world)
            return CGPoint(x: p.x - lens.position.x, y: p.y - lens.position.y)
        }
        func beyond(_ d: CGPoint) -> CGFloat? {
            let past = max(abs(d.x) - half.width, abs(d.y) - half.height)
            return past > -2 ? max(0, past) : nil
        }
        func consider(_ world: Vec2, color: UIColor, floor: CGFloat = 0) {
            let d = offset(of: world)
            guard let past = beyond(d), past < reach || floor > 0 else { return }
            marks.append((d, color, max(floor, 1 - past / reach)))
        }

        for rock in frame.rocks { consider(rock.position, color: Self.rockMarker) }
        for echo in frame.echoes { consider(echo, color: VisualPalette.echoRim) }
        if let spark = nearestSpark(in: frame) { consider(spark, color: VisualPalette.spark, floor: 0.3) }

        marks.sort { $0.closeness > $1.closeness }
        for (index, node) in markerPool.enumerated() {
            guard index < marks.count else {
                node.isHidden = true
                continue
            }
            let mark = marks[index]
            node.isHidden = false
            node.position = rim(mark.offset, half: half, inset: 6)
            node.fillColor = mark.color
            node.setScale(2.2 + 3 * mark.closeness)
            node.alpha = 0.4 + 0.6 * mark.closeness
        }

        let exit = offset(of: level.exit)
        if beyond(exit) != nil {
            exitMarker.isHidden = false
            exitMarker.position = rim(exit, half: half, inset: 8)
            exitMarker.zRotation = atan2(exit.y, exit.x)
            exitMarker.alpha = frame.exitOpen ? 1 : 0.35
        } else {
            exitMarker.isHidden = true
        }
    }

    private func nearestSpark(in frame: RemoteFrame) -> Vec2? {
        let orbiting = Dictionary(frame.orbiting.map { ($0.id, $0.position) }, uniquingKeysWith: { first, _ in first })
        return layout.sparks
            .filter { !RemoteFrame.contains(frame.collected, $0.id) && !RemoteFrame.contains(frame.timedOut, $0.id) }
            .map { orbiting[$0.id] ?? $0.position }
            .min { $0.distance(to: frame.player) < $1.distance(to: frame.player) }
    }

    /// Where the ray from the centre toward `d` meets the face, following
    /// the rounded corners of the display.
    func rim(_ d: CGPoint, half: CGSize, inset: CGFloat) -> CGPoint {
        let w = half.width - inset
        let h = half.height - inset
        let t = min(w / max(abs(d.x), 0.001), h / max(abs(d.y), 0.001))
        var edge = CGPoint(x: d.x * t, y: d.y * t)
        let corner: CGFloat = 20
        let cx = w - corner
        let cy = h - corner
        if abs(edge.x) > cx, abs(edge.y) > cy {
            let centre = CGPoint(x: edge.x < 0 ? -cx : cx, y: edge.y < 0 ? -cy : cy)
            let vx = edge.x - centre.x
            let vy = edge.y - centre.y
            let length = max(hypot(vx, vy), 0.001)
            edge = CGPoint(x: centre.x + vx / length * corner, y: centre.y + vy / length * corner)
        }
        return edge
    }
}
