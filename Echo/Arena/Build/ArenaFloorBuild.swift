import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func buildArena() {
        let w = size.width
        let h = size.height
        let grid = SKShapeNode()
        let path = CGMutablePath()
        let cols = 8
        let rows = max(8, Int((h / w) * 8))
        let dx = w / CGFloat(cols)
        let dy = h / CGFloat(rows)
        for i in 0...cols {
            let x = CGFloat(i) * dx
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
        }
        for i in 0...rows {
            let y = CGFloat(i) * dy
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: w, y: y))
        }
        let theme = session.level.theme
        grid.path = path
        grid.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.10)
        grid.lineWidth = 1
        grid.zPosition = 0
        addChild(grid)

        let border = SKShapeNode(rectOf: CGSize(width: w - 10, height: h - 10), cornerRadius: 8)
        border.position = CGPoint(x: w / 2, y: h / 2)
        border.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.40)
        border.lineWidth = 2
        border.glowWidth = 0
        border.fillColor = .clear
        border.zPosition = 1
        addChild(border)

        if !session.level.walls.isEmpty {
            let fillPath = CGMutablePath()
            for wall in session.level.walls {
                fillPath.addRect(mapped(wall))
            }
            let fill = SKShapeNode(path: fillPath)
            fill.fillColor = theme.wallFill.uiColor.withAlphaComponent(0.42)
            fill.strokeColor = .clear
            fill.zPosition = 2
            addChild(fill)

            if let material = GlowTextures.wall(for: theme, levelNumber: session.level.number) {
                let crop = SKCropNode()
                crop.name = "wallMaterial"
                crop.zPosition = 2.02
                let mask = SKShapeNode(path: fillPath)
                mask.fillColor = .white
                mask.strokeColor = .clear
                crop.maskNode = mask
                let tileWorld: CGFloat = 140
                let tileScene = max(24, tileWorld * worldScale)
                let bounds = fillPath.boundingBox
                var x = floor(bounds.minX / tileScene) * tileScene
                while x < bounds.maxX {
                    var y = floor(bounds.minY / tileScene) * tileScene
                    while y < bounds.maxY {
                        let cell = SKSpriteNode(texture: material, size: CGSize(width: tileScene, height: tileScene))
                        cell.position = CGPoint(x: x + tileScene / 2, y: y + tileScene / 2)
                        crop.addChild(cell)
                        y += tileScene
                    }
                    x += tileScene
                }
                addChild(crop)
            }

            let boundaryPath = wallBoundaryPath(session.level.walls)
            let bevel = SKShapeNode(path: boundaryPath)
            bevel.name = "wallBevel"
            bevel.fillColor = .clear
            bevel.strokeColor = UIColor.white.withAlphaComponent(0.16)
            bevel.lineWidth = 1.1
            bevel.glowWidth = 0
            bevel.lineCap = .round
            bevel.lineJoin = .round
            bevel.zPosition = 2.03
            addChild(bevel)
            let energy = SKShapeNode(path: boundaryPath)
            energy.fillColor = .clear
            energy.strokeColor = theme.wallStroke.uiColor
            energy.lineWidth = 2.4
            energy.glowWidth = 0
            energy.lineCap = .round
            energy.lineJoin = .round
            energy.zPosition = 2.06
            energy.alpha = 0.52
            energy.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.84, duration: 1.15),
                .fadeAlpha(to: 0.34, duration: 1.15),
            ])))
            addChild(energy)

            let glow = SKShapeNode(path: boundaryPath)
            glow.fillColor = .clear
            glow.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.30)
            glow.lineWidth = 5
            glow.glowWidth = 0
            glow.lineCap = .round
            glow.lineJoin = .round
            glow.zPosition = 2.05
            addChild(glow)

            let edge = SKShapeNode(path: boundaryPath)
            edge.fillColor = .clear
            edge.strokeColor = theme.wallStroke.uiColor.withAlphaComponent(0.88)
            edge.lineWidth = 1.6
            edge.lineCap = .round
            edge.lineJoin = .round
            edge.zPosition = 2.1
            addChild(edge)
        }
    }

    func buildAmbient() {
        let theme = session.level.theme
        let tint = theme.nebula.uiColor
        let nebulaCount: Int
        let moteCount: Int
        let rockCount: Int
        switch session.level.atmosphere {
        case .clear:
            nebulaCount = 0
            moteCount = 6
            rockCount = 0
        case .drift:
            nebulaCount = 1
            moteCount = 11
            rockCount = 3
        case .nebula:
            nebulaCount = 4
            moteCount = 17
            rockCount = 5
        }

        for _ in 0..<nebulaCount {
            let nebula = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat.random(in: 160...280)
            nebula.size = CGSize(width: s, height: s)
            nebula.alpha = CGFloat.random(in: 0.07...0.15)
            nebula.blendMode = .add
            nebula.color = tint
            nebula.colorBlendFactor = 0.85
            nebula.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            nebula.zPosition = 0.4
            nebula.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -30...40), duration: TimeInterval.random(in: 10...16)),
                .moveBy(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -40...30), duration: TimeInterval.random(in: 10...16)),
            ])))
            ambienceNode.addChild(nebula)
        }
        for _ in 0..<moteCount {
            let mote = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat.random(in: 8...24)
            mote.size = CGSize(width: s, height: s)
            mote.alpha = CGFloat.random(in: 0.10...0.28)
            mote.blendMode = .add
            mote.color = tint
            mote.colorBlendFactor = 0.55
            mote.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            mote.zPosition = 1.5
            let drift = SKAction.moveBy(
                x: CGFloat.random(in: -40...40),
                y: CGFloat.random(in: 30...90),
                duration: TimeInterval.random(in: 6...12)
            )
            let fade = SKAction.sequence([
                .fadeAlpha(to: mote.alpha + 0.08, duration: 2.4),
                .fadeAlpha(to: mote.alpha, duration: 2.4),
            ])
            mote.run(.repeatForever(.group([drift, fade])))
            mote.run(.repeatForever(.sequence([
                .wait(forDuration: TimeInterval.random(in: 4...9)),
                .move(to: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ), duration: 0),
            ])))
            ambienceNode.addChild(mote)
        }
        for index in 0..<rockCount {
            let s = CGFloat.random(in: 10...18)
            let rock = Self.asteroidShape(
                radius: s,
                seed: session.level.number * 17 + index,
                sides: 6 + index % 3,
                jaggedness: 0.24
            )
            rock.fillColor = tint.withAlphaComponent(0.18)
            rock.strokeColor = tint.withAlphaComponent(0.28)
            rock.lineWidth = 0.8
            rock.alpha = 0.22
            rock.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            rock.zPosition = 1.2
            if index.isMultiple(of: 2) {
                rock.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: TimeInterval.random(in: 14...28))))
            }
            rock.run(.repeatForever(.sequence([
                .moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: 40...120), duration: TimeInterval.random(in: 9...16)),
                .moveBy(x: CGFloat.random(in: -80...80), y: CGFloat.random(in: -60...40), duration: TimeInterval.random(in: 9...16)),
            ])))
            ambienceNode.addChild(rock)
        }
    }

    func buildDecorations() {
        for decoration in session.level.decorations {
            let tint = decorationColor(decoration.tone)
            switch decoration.kind {
            case .anchor(let radius):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(12, CGFloat(radius) * worldScale)

                let bloom = SKSpriteNode(texture: GlowTextures.blob)
                bloom.size = CGSize(width: r * 2.8, height: r * 2.8)
                bloom.blendMode = .add
                bloom.color = tint
                bloom.colorBlendFactor = 0.82
                bloom.alpha = 0.10

                let plate = SKShapeNode(path: Self.polygonPath(radius: r, sides: 6))
                plate.fillColor = tint.withAlphaComponent(0.045)
                plate.strokeColor = tint.withAlphaComponent(0.34)
                plate.lineWidth = 1.2
                plate.glowWidth = 0

                let dial = SKShapeNode(path: Self.segmentedCirclePath(radius: r * 0.66, segments: 6, coverage: 0.56))
                dial.fillColor = .clear
                dial.strokeColor = tint.withAlphaComponent(0.46)
                dial.lineWidth = 2
                dial.glowWidth = 2
                dial.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 15)))

                let core = SKShapeNode(circleOfRadius: max(2.5, r * 0.10))
                core.fillColor = tint.withAlphaComponent(0.72)
                core.strokeColor = .clear
                core.glowWidth = 0

                root.addChild(bloom)
                root.addChild(plate)
                root.addChild(dial)
                root.addChild(core)
                decorationNode.addChild(root)

            case .reactor(let radius, let spokes):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(24, CGFloat(radius) * worldScale)

                let bloom = SKSpriteNode(texture: GlowTextures.blob)
                bloom.size = CGSize(width: r * 2.35, height: r * 2.35)
                bloom.blendMode = .add
                bloom.color = tint
                bloom.colorBlendFactor = 0.86
                bloom.alpha = 0.055

                let spokePath = CGMutablePath()
                for index in 0..<max(4, spokes) {
                    let angle = CGFloat(index) / CGFloat(max(4, spokes)) * .pi * 2
                    spokePath.move(to: CGPoint(x: cos(angle) * r * 0.44, y: sin(angle) * r * 0.44))
                    spokePath.addLine(to: CGPoint(x: cos(angle) * r * 0.93, y: sin(angle) * r * 0.93))
                }
                let spokeNode = SKShapeNode(path: spokePath)
                spokeNode.strokeColor = tint.withAlphaComponent(0.16)
                spokeNode.lineWidth = 1
                spokeNode.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 36)))

                for (index, factor) in [CGFloat(1), 0.73, 0.45].enumerated() {
                    let ring = SKShapeNode(path: Self.segmentedCirclePath(
                        radius: r * factor,
                        segments: max(6, spokes - index * 2),
                        coverage: index == 1 ? 0.58 : 0.72
                    ))
                    ring.fillColor = .clear
                    ring.strokeColor = tint.withAlphaComponent(index == 2 ? 0.36 : 0.23)
                    ring.lineWidth = index == 2 ? 1.7 : 1.1
                    ring.glowWidth = 0
                    let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                    ring.run(.repeatForever(.rotate(byAngle: direction * .pi * 2, duration: 22 + Double(index) * 7)))
                    root.addChild(ring)
                }

                root.addChild(bloom)
                root.addChild(spokeNode)
                decorationNode.addChild(root)

            case .lane(let end, let chevrons):
                let startPoint = scenePoint(decoration.position)
                let endPoint = scenePoint(end)
                let dx = endPoint.x - startPoint.x
                let dy = endPoint.y - startPoint.y
                let length = max(1, hypot(dx, dy))
                let direction = CGPoint(x: dx / length, y: dy / length)
                let normal = CGPoint(x: -direction.y, y: direction.x)

                let linePath = CGMutablePath()
                linePath.move(to: startPoint)
                linePath.addLine(to: endPoint)
                let line = SKShapeNode(path: linePath)
                line.strokeColor = tint.withAlphaComponent(0.13)
                line.lineWidth = 1.2
                line.glowWidth = 0

                let arrowPath = CGMutablePath()
                for index in 1...max(1, chevrons) {
                    let t = CGFloat(index) / CGFloat(max(1, chevrons) + 1)
                    let center = CGPoint(x: startPoint.x + dx * t, y: startPoint.y + dy * t)
                    let tip = CGPoint(x: center.x + direction.x * 7, y: center.y + direction.y * 7)
                    let tail = CGPoint(x: center.x - direction.x * 6, y: center.y - direction.y * 6)
                    arrowPath.move(to: CGPoint(x: tail.x + normal.x * 5, y: tail.y + normal.y * 5))
                    arrowPath.addLine(to: tip)
                    arrowPath.addLine(to: CGPoint(x: tail.x - normal.x * 5, y: tail.y - normal.y * 5))
                }
                let arrows = SKShapeNode(path: arrowPath)
                arrows.strokeColor = tint.withAlphaComponent(0.30)
                arrows.lineWidth = 1.4
                arrows.lineCap = .round
                arrows.lineJoin = .round
                arrows.glowWidth = 2
                arrows.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.48, duration: 1.1),
                    .fadeAlpha(to: 1, duration: 1.1),
                ])))

                decorationNode.addChild(line)
                decorationNode.addChild(arrows)

            case .hazardRing(let radius, let segments):
                let root = SKNode()
                root.position = scenePoint(decoration.position)
                root.zRotation = CGFloat(decoration.rotation)
                let r = max(16, CGFloat(radius) * worldScale)

                let outer = SKShapeNode(path: Self.segmentedCirclePath(radius: r, segments: max(6, segments), coverage: 0.54))
                outer.fillColor = .clear
                outer.strokeColor = tint.withAlphaComponent(0.34)
                outer.lineWidth = 2
                outer.glowWidth = 0
                outer.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 19)))

                let inner = SKShapeNode(path: Self.segmentedCirclePath(radius: r * 0.78, segments: max(4, segments / 2), coverage: 0.30))
                inner.fillColor = .clear
                inner.strokeColor = tint.withAlphaComponent(0.15)
                inner.lineWidth = 1
                inner.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 27)))

                root.addChild(outer)
                root.addChild(inner)
                decorationNode.addChild(root)
            }
        }
    }
}
