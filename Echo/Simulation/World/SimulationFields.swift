import Foundation

extension WorldSimulation {

    func tickRifts() -> [SimEvent] {
        var events: [SimEvent] = []
        for i in rifts.indices {
            let open = rifts[i].isOpen(at: playbackTime)
            if open, !rifts[i].open {
                rifts[i].usedThisCycle = false
                events.append(.riftOpened(id: rifts[i].id))
            }
            if !open { rifts[i].usedThisCycle = false }
            rifts[i].open = open
            guard open, !rifts[i].usedThisCycle, riftTravelCooldown <= 0 else { continue }
            if playerPosition.distance(to: rifts[i].position) < config.playerRadius + rifts[i].radius {
                rifts[i].usedThisCycle = true
                events.append(.riftEntered(kind: rifts[i].kind))
                riftsUsed += 1
                switch rifts[i].kind {
                case .calm:
                    effects.freezeRemaining = max(effects.freezeRemaining, 1.6)
                case .collision:
                    break
                case .warp:
                    let from = playerPosition
                    let folded = Vec2(
                        x: level.worldWidth - playerPosition.x,
                        y: level.worldHeight - playerPosition.y
                    )
                    playerPosition = resolveWalls(clampToArena(folded, radius: config.playerRadius), radius: config.playerRadius)
                    playbackTime = max(0, playbackTime - 1.35)
                    effects.iFrames = max(effects.iFrames, 0.75)
                    reality = .mirror
                    realityRemaining = 4.5
                    riftTravelCooldown = 1.1
                    events.append(.playerTeleported(from: from, to: playerPosition, reason: .warp))
                case .candy:
                    reality = .candy
                    realityRemaining = max(realityRemaining, 10)
                    effects.iFrames = max(effects.iFrames, 0.45)
                    riftTravelCooldown = 1.1
                }
            }
        }
        return events
    }

    static func makeGravityWells(_ spawns: [GravityWellSpawn]) -> [GravityWellState] {
        spawns.map {
            GravityWellState(
                id: $0.id,
                position: $0.position,
                coreRadius: $0.coreRadius,
                influenceRadius: $0.influenceRadius,
                strength: $0.strength
            )
        }
    }

    func applyGravityWells(dt: TimeInterval) {
        guard !effects.isFrozen else { return }
        for well in gravityWells {
            let delta = well.position - playerPosition
            let distance = delta.length
            guard distance > 0.5, distance < well.influenceRadius else { continue }
            let falloff = 1 - distance / well.influenceRadius
            let pull = min(distance, well.strength * falloff * falloff * dt)
            playerPosition = playerPosition + delta.normalized() * pull
        }
        playerPosition = resolveWalls(clampToArena(playerPosition, radius: config.playerRadius), radius: config.playerRadius)
    }

    func collideGravityWells() -> DeathCause? {
        for well in gravityWells {
            if playerPosition.distance(to: well.position) < config.playerRadius + well.coreRadius * 0.68 {
                return .blackHole
            }
        }
        return nil
    }

    static func makeGates(_ spawns: [TimeGateSpawn]) -> [TimeGateState] {
        spawns.map {
            TimeGateState(id: $0.id, area: $0.area, period: $0.period, openFor: $0.openFor, phase: $0.phase)
        }
    }

    func tickGates() {
        for i in gates.indices {
            gates[i].solid = gates[i].isSolid(at: playbackTime)
        }
    }

    func tickScars(dt: TimeInterval) {
        for i in scars.indices {
            scars[i].remaining -= dt
        }
        scars.removeAll { $0.remaining <= 0 }
    }

    func collideScars() -> DeathCause? {
        for scar in scars {
            if playerPosition.distance(to: scar.position) < config.playerRadius + scar.radius - config.collisionSlop {
                return .collision
            }
        }
        return nil
    }

    func collideRifts() -> DeathCause? {
        for rift in rifts where rift.open && rift.kind == .collision {
            if playerPosition.distance(to: rift.position) < config.playerRadius + rift.radius * 0.72 {
                return .rift
            }
        }
        return nil
    }

    func detectTimeCollision(dt: TimeInterval) -> [SimEvent] {
        if collisionCooldown > 0 {
            collisionCooldown = max(0, collisionCooldown - dt)
            return []
        }
        guard echoes.count >= 2 else { return [] }
        for i in 0..<echoes.count {
            for j in (i + 1)..<echoes.count {
                if echoes[i].distance(to: echoes[j]) < config.echoRadius * 2.2 {
                    collisionCooldown = 3.2
                    let mid = echoes[i].lerp(echoes[j], 0.5)
                    scars.append(CollisionScar(id: scars.count + 17, position: mid, radius: 34, remaining: 2.8))
                    scarsCreated += 1
                    return [.timeCollision(at: mid)]
                }
            }
        }
        return []
    }

    static func makeMovers(_ spawns: [MoverSpawn]) -> [MoverState] {
        spawns.map {
            MoverState(
                id: $0.id,
                kind: $0.kind,
                material: $0.material,
                position: $0.position,
                velocity: $0.velocity,
                radius: $0.radius,
                path: $0.path,
                hitsRemaining: $0.material.wallHitsToShatter
            )
        }
    }

    static func makeLasers(_ spawns: [LaserSpawn]) -> [LaserState] {
        spawns.map {
            var state = LaserState(
                id: $0.id,
                start: $0.start,
                end: $0.end,
                beamWidth: $0.beamWidth,
                period: $0.period,
                chargeFor: $0.chargeFor,
                activeFor: $0.activeFor,
                offset: $0.phase,
                motion: $0.motion
            )
            state.updateGeometry(at: 0)
            return state
        }
    }
}
