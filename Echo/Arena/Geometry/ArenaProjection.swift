import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    var worldScale: CGFloat {
        size.width / CGFloat(max(session.level.worldWidth, 1))
    }

    var actorRadius: CGFloat {
        max(8, CGFloat(session.sim.config.playerRadius) * worldScale * VisualStyle.actorBodyScale)
    }

    func beamPath(for laser: LaserState) -> CGPath {
        let path = CGMutablePath()
        path.move(to: scenePoint(laser.start))
        path.addLine(to: scenePoint(laser.end))
        return path
    }

    func wallCornerRadius(_ rect: CGRect) -> CGFloat {
        min(12, min(rect.width, rect.height) * 0.22)
    }

    func roundedMaterialPanel(
        texture: SKTexture,
        rect: CGRect,
        zPosition: CGFloat,
        name: String = "material"
    ) -> SKCropNode {
        let crop = SKCropNode()
        crop.name = name
        crop.position = CGPoint(x: rect.midX, y: rect.midY)
        crop.zPosition = zPosition
        let mask = SKShapeNode(rectOf: rect.size, cornerRadius: wallCornerRadius(rect))
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        let tile = SKSpriteNode(texture: texture, size: rect.size)
        tile.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        crop.addChild(tile)
        return crop
    }

    func mapped(_ wall: AABB) -> CGRect {
        CGRect(
            x: wall.minX * Double(worldScale),
            y: wall.minY * Double(worldScale),
            width: wall.width * Double(worldScale),
            height: wall.height * Double(worldScale)
        )
    }

    func wallTextureComponentPaths(_ walls: [AABB]) -> [CGPath] {
        let rectangles = walls.map(mapped)
        var visited = Set<Int>()
        var paths: [CGPath] = []

        for seed in rectangles.indices where !visited.contains(seed) {
            var queue = [seed]
            var component: [Int] = []
            visited.insert(seed)
            while let current = queue.popLast() {
                component.append(current)
                for next in rectangles.indices where !visited.contains(next) {
                    if rectangles[current].insetBy(dx: -0.5, dy: -0.5).intersects(rectangles[next]) {
                        visited.insert(next)
                        queue.append(next)
                    }
                }
            }
            let path = CGMutablePath()
            for index in component { path.addRect(rectangles[index]) }
            paths.append(path)
        }
        return paths
    }

    func wallBoundaryPath(_ walls: [AABB]) -> CGPath {
        let xs = Array(Set(walls.flatMap { [$0.minX, $0.maxX] })).sorted()
        let ys = Array(Set(walls.flatMap { [$0.minY, $0.maxY] })).sorted()
        let path = CGMutablePath()
        guard xs.count > 1, ys.count > 1 else { return path }

        func occupied(_ x: Int, _ y: Int) -> Bool {
            guard x >= 0, y >= 0, x < xs.count - 1, y < ys.count - 1 else { return false }
            let point = Vec2(x: (xs[x] + xs[x + 1]) / 2, y: (ys[y] + ys[y + 1]) / 2)
            return walls.contains { $0.contains(point) }
        }

        func segment(_ a: Vec2, _ b: Vec2) {
            path.move(to: scenePoint(a))
            path.addLine(to: scenePoint(b))
        }

        // Merge adjacent collinear edges before stroking. Without this pass every
        // rectangle-grid cell contributes a round-capped line, creating bright dots
        // and hairline overlaps at otherwise seamless wall joints.
        for x in 0..<xs.count {
            var runStart: Int?
            var runSide = 0
            for y in 0..<ys.count {
                let side: Int
                if y < ys.count - 1 {
                    let left = occupied(x - 1, y)
                    let right = occupied(x, y)
                    side = left == right ? 0 : (left ? -1 : 1)
                } else {
                    side = 0
                }

                if let start = runStart, side != runSide {
                    segment(Vec2(x: xs[x], y: ys[start]), Vec2(x: xs[x], y: ys[y]))
                    runStart = nil
                }
                if side != 0, runStart == nil {
                    runStart = y
                    runSide = side
                }
            }
        }

        for y in 0..<ys.count {
            var runStart: Int?
            var runSide = 0
            for x in 0..<xs.count {
                let side: Int
                if x < xs.count - 1 {
                    let below = occupied(x, y - 1)
                    let above = occupied(x, y)
                    side = below == above ? 0 : (below ? -1 : 1)
                } else {
                    side = 0
                }

                if let start = runStart, side != runSide {
                    segment(Vec2(x: xs[start], y: ys[y]), Vec2(x: xs[x], y: ys[y]))
                    runStart = nil
                }
                if side != 0, runStart == nil {
                    runStart = x
                    runSide = side
                }
            }
        }
        return path
    }

    func scenePoint(_ v: Vec2) -> CGPoint {
        CGPoint(x: v.x * Double(worldScale), y: v.y * Double(worldScale))
    }

    func world(_ p: CGPoint) -> Vec2 {
        Vec2(x: Double(p.x / worldScale), y: Double(p.y / worldScale))
    }
}

extension RGB {
    var uiColor: UIColor { UIColor(red: r, green: g, blue: b, alpha: 1) }
}
