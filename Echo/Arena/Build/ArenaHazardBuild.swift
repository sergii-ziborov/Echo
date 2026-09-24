import QuartzCore
import SpriteKit
import UIKit

extension GameScene {
    func buildGravityWells() {
        for well in session.sim.gravityWells {
            let root = SKNode()
            root.zPosition = 9.4
            root.position = scenePoint(well.position)

            let influence = SKShapeNode(circleOfRadius: CGFloat(well.influenceRadius) * worldScale)
            influence.name = "influence"
            influence.fillColor = UIColor(red: 0.35, green: 0.20, blue: 0.65, alpha: 0.045)
            influence.strokeColor = UIColor(red: 0.45, green: 0.70, blue: 1, alpha: 0.20)
            influence.lineWidth = 1.2
            influence.glowWidth = 0
            influence.run(.repeatForever(.sequence([
                .scale(to: 0.92, duration: 1.4),
                .scale(to: 1.04, duration: 1.4),
            ])))

            let lensing = SKNode()
            lensing.name = "lensing"
            for index in 0..<3 {
                let radius = CGFloat(well.coreRadius) * worldScale * (1.05 + CGFloat(index) * 0.30)
                let arc = SKShapeNode(
                    path: Self.segmentedCirclePath(
                        radius: radius,
                        segments: 3 + index,
                        coverage: 0.42
                    )
                )
                arc.strokeColor = index == 1
                    ? UIColor(red: 1, green: 0.78, blue: 0.35, alpha: 0.86)
                    : UIColor(red: 0.42, green: 0.82, blue: 1, alpha: 0.72)
                arc.lineWidth = 1.5 + CGFloat(index) * 0.35
                arc.glowWidth = 0
                arc.xScale = 1.25
                arc.yScale = 0.58 + CGFloat(index) * 0.08
                arc.zRotation = CGFloat(index) * 0.72
                arc.run(.repeatForever(.rotate(
                    byAngle: index.isMultiple(of: 2) ? .pi * 2 : -.pi * 2,
                    duration: 3.8 + Double(index) * 1.2
                )))
                lensing.addChild(arc)
            }

            let orbiters = SKNode()
            orbiters.name = "orbiters"
            for index in 0..<6 {
                let angle = CGFloat(index) / 6 * .pi * 2
                let mote = SKSpriteNode(texture: GlowTextures.blob)
                mote.size = CGSize(width: 5 + CGFloat(index % 2) * 2, height: 5 + CGFloat(index % 2) * 2)
                mote.position = CGPoint(
                    x: cos(angle) * CGFloat(well.coreRadius) * worldScale * 1.55,
                    y: sin(angle) * CGFloat(well.coreRadius) * worldScale * 0.82
                )
                mote.color = index.isMultiple(of: 3)
                    ? UIColor(red: 1, green: 0.75, blue: 0.3, alpha: 1)
                    : UIColor(red: 0.45, green: 0.85, blue: 1, alpha: 1)
                mote.colorBlendFactor = 0.8
                mote.blendMode = .add
                orbiters.addChild(mote)
            }
            orbiters.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 4.8)))

            let sprite = SKSpriteNode(texture: GlowTextures.blackHole)
            sprite.name = "core"
            let diameter = max(92, CGFloat(well.coreRadius) * worldScale * 3.4)
            sprite.size = CGSize(width: diameter, height: diameter)
            sprite.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: 8.5)))

            root.addChild(influence)
            root.addChild(lensing)
            root.addChild(orbiters)
            root.addChild(sprite)
            addChild(root)
            gravityWellNodes[well.id] = root
        }
    }

    func buildRifts() {
        for rift in session.sim.rifts {
            let root = SKNode()
            root.zPosition = 8
            root.position = scenePoint(rift.position)
            let color: UIColor = switch rift.kind {
            case .calm: UIColor(red: 0.55, green: 0.82, blue: 1, alpha: 1)
            case .collision: UIColor(red: 1, green: 0.30, blue: 0.48, alpha: 1)
            case .warp: UIColor(red: 0.45, green: 0.48, blue: 1, alpha: 1)
            case .candy: UIColor(red: 1, green: 0.40, blue: 0.78, alpha: 1)
            }
            let glow = SKSpriteNode(texture: GlowTextures.blob)
            let s = CGFloat(rift.radius) * worldScale * 2.4
            glow.size = CGSize(width: s, height: s)
            glow.blendMode = .add
            glow.color = color
            glow.colorBlendFactor = 0.8
            glow.alpha = 0.7
            glow.run(.repeatForever(.sequence([
                .scale(to: 1.12, duration: 0.7),
                .scale(to: 0.88, duration: 0.7),
            ])))
            let ring = SKShapeNode(circleOfRadius: CGFloat(rift.radius) * worldScale)
            ring.strokeColor = color
            ring.lineWidth = 2
            ring.glowWidth = 0
            ring.fillColor = color.withAlphaComponent(0.08)
            ring.run(.repeatForever(.rotate(byAngle: .pi, duration: 5)))
            root.addChild(glow)

            let core = SKSpriteNode(texture: GlowTextures.blob)
            core.size = CGSize(width: s * 0.72, height: s * 0.72)
            core.blendMode = .add
            core.color = color
            core.colorBlendFactor = 0.85
            core.alpha = 0.55
            core.run(.repeatForever(.sequence([
                .scale(to: 1.18, duration: 0.55),
                .scale(to: 0.82, duration: 0.55),
            ])))
            root.addChild(core)

            let orbit = SKNode()
            orbit.name = "riftOrbit"
            for index in 0..<8 {
                let angle = CGFloat(index) / 8 * .pi * 2
                let shard = SKShapeNode(rectOf: CGSize(width: 2.2, height: 8 + CGFloat(index % 3) * 2), cornerRadius: 1)
                shard.position = CGPoint(
                    x: cos(angle) * s * 0.72,
                    y: sin(angle) * s * 0.48
                )
                shard.zRotation = angle - .pi / 2
                shard.fillColor = index.isMultiple(of: 3) ? .white : color
                shard.strokeColor = .clear
                shard.glowWidth = 0
                orbit.addChild(shard)
            }
            orbit.run(.repeatForever(.rotate(byAngle: -.pi * 2, duration: rift.kind == .candy ? 3.8 : 5.4)))
            root.addChild(orbit)

            root.addChild(ring)
            addChild(root)
            riftNodes[rift.id] = root
        }
    }

    func buildGates() {
        let theme = session.level.theme
        for gate in session.sim.gates {
            let rect = mapped(gate.area)
            let root = SKNode()
            root.zPosition = 2.6
            if let material = GlowTextures.wall(for: theme, levelNumber: session.level.number) {
                let plate = roundedMaterialPanel(texture: material, rect: rect, zPosition: -1, name: "plate")
                root.addChild(plate)
            }
            let node = SKShapeNode(rect: rect, cornerRadius: 10)
            node.fillColor = theme.wallStroke.uiColor.withAlphaComponent(0.12)
            node.strokeColor = theme.wallStroke.uiColor
            node.lineWidth = 1.5
            node.glowWidth = 0
            root.addChild(node)
            addChild(root)
            gateNodes[gate.id] = root
            gateSolidStates[gate.id] = gate.solid

            let horizontal = rect.width >= rect.height
            let frameSize = max(23, min(rect.width, rect.height) * 1.05)
            let framePositions: [CGPoint] = horizontal
                ? [CGPoint(x: rect.minX, y: rect.midY), CGPoint(x: rect.maxX, y: rect.midY)]
                : [CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.maxY)]
            gateFrames[gate.id] = framePositions.compactMap { position in
                guard let texture = GlowTextures.closedGate else { return nil }
                let frame = SKSpriteNode(texture: texture)
                frame.position = position
                frame.size = CGSize(width: frameSize, height: frameSize)
                frame.zPosition = 2.72
                frame.alpha = 0.92
                addChild(frame)
                return frame
            }
        }
    }

    func buildLasers() {
        for laser in session.sim.lasers {
            let path = beamPath(for: laser)

            let root = SKNode()
            root.zPosition = 8.6

            let aura = SKShapeNode(path: path)
            aura.name = "aura"
            aura.strokeColor = UIColor(red: 1, green: 0.16, blue: 0.42, alpha: 1)
            aura.lineWidth = max(6, CGFloat(laser.beamWidth) * worldScale * 2.1)
            aura.lineCap = .round
            aura.glowWidth = 0
            aura.alpha = 0

            let warning = SKShapeNode(path: path)
            warning.name = "warning"
            warning.strokeColor = UIColor(red: 1, green: 0.32, blue: 0.46, alpha: 1)
            warning.lineWidth = max(2, CGFloat(laser.beamWidth) * worldScale * 0.65)
            warning.lineCap = .round
            warning.glowWidth = 0

            let core = SKShapeNode(path: path)
            core.name = "core"
            core.strokeColor = .white
            core.lineWidth = max(2, CGFloat(laser.beamWidth) * worldScale)
            core.lineCap = .round
            core.glowWidth = 0
            core.alpha = 0

            root.addChild(aura)
            root.addChild(warning)
            root.addChild(core)
            root.addChild(laserEmitter(at: scenePoint(laser.start), name: "start"))
            root.addChild(laserEmitter(at: scenePoint(laser.end), name: "end"))
            for index in 0..<4 {
                let pulse = SKSpriteNode(texture: GlowTextures.blob)
                pulse.name = "pulse-\(index)"
                pulse.size = CGSize(width: 18, height: 18)
                pulse.blendMode = .add
                pulse.color = UIColor(red: 1, green: 0.22, blue: 0.48, alpha: 1)
                pulse.colorBlendFactor = 0.72
                pulse.alpha = 0
                root.addChild(pulse)
            }
            addChild(root)
            laserNodes[laser.id] = root
        }
        syncLasers()
    }

    func laserEmitter(at point: CGPoint, name: String) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = point
        let glow = SKSpriteNode(texture: GlowTextures.blob)
        glow.name = "glow"
        glow.size = CGSize(width: 42, height: 42)
        glow.blendMode = .add
        glow.color = UIColor(red: 1, green: 0.18, blue: 0.46, alpha: 1)
        glow.colorBlendFactor = 0.72
        glow.alpha = 0.44
        let housing = SKShapeNode(circleOfRadius: 11)
        housing.name = "housing"
        housing.fillColor = UIColor(red: 0.18, green: 0.06, blue: 0.14, alpha: 0.92)
        housing.strokeColor = UIColor(red: 1, green: 0.28, blue: 0.48, alpha: 0.88)
        housing.lineWidth = 1.6
        housing.glowWidth = 0
        let lens = SKSpriteNode(texture: GlowTextures.blob)
        lens.size = CGSize(width: 12, height: 12)
        lens.blendMode = .add
        lens.color = UIColor(red: 1, green: 0.32, blue: 0.68, alpha: 1)
        lens.colorBlendFactor = 0.65
        lens.name = "lens"
        lens.run(.repeatForever(.sequence([
            .scale(to: 1.22, duration: 0.42),
            .scale(to: 0.82, duration: 0.42),
        ])))
        root.addChild(glow)
        root.addChild(housing)
        root.addChild(lens)
        return root
    }
}
