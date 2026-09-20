import Foundation

extension WorldSimulation {
    func stepMovers(dt: TimeInterval) -> [SimEvent] {
        var events: [SimEvent] = []
        for i in movers.indices {
            movers[i].impactCooldown = max(0, movers[i].impactCooldown - dt)
            if let remaining = movers[i].fractureRemaining {
                movers[i].fractureRemaining = max(0, remaining - dt)
            }

            let impacted: Bool
            switch movers[i].path {
            case .stationary:
                impacted = false
            case .bounce:
                impacted = stepBouncingMover(at: i, dt: dt)
            case .patrol(let a, let b):
                impacted = false
                let span = max(a.distance(to: b), 1)
                let speed = 90.0 / span
                movers[i].patrolT += dt * speed * movers[i].patrolDir
                if movers[i].patrolT >= 1 {
                    movers[i].patrolT = 1
                    movers[i].patrolDir = -1
                } else if movers[i].patrolT <= 0 {
                    movers[i].patrolT = 0
                    movers[i].patrolDir = 1
                }
                let next = a.lerp(b, movers[i].patrolT)
                movers[i].velocity = (next - movers[i].position) / max(dt, 0.0001)
                movers[i].position = next
            case .orbit(let center, let radius, let period, let phase):
                impacted = false
                let angle = phase + (playbackTime / max(period, 0.1)) * (.pi * 2)
                let next = Vec2(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                movers[i].velocity = (next - movers[i].position) / max(dt, 0.0001)
                movers[i].position = next
            }

            if impacted, movers[i].impactCooldown <= 0 {
                movers[i].impactCooldown = 0.18
                if let maxHits = movers[i].material.wallHitsToShatter {
                    if movers[i].fractureRemaining == nil {
                        movers[i].fractureRemaining = movers[i].material.fractureDuration
                    }
                    movers[i].hitsRemaining = max(0, (movers[i].hitsRemaining ?? maxHits) - 1)
                }
                events.append(
                    .asteroidImpacted(
                        id: movers[i].id,
                        material: movers[i].material,
                        at: movers[i].position
                    )
                )
            }
        }

        for index in movers.indices.reversed() {
            let hitLimitReached = movers[index].hitsRemaining == 0
            let timerExpired = movers[index].fractureRemaining.map { $0 <= 0 } ?? false
            guard hitLimitReached || timerExpired else { continue }
            let mover = movers.remove(at: index)
            events.append(.asteroidShattered(id: mover.id, material: mover.material, at: mover.position))
        }
        return events
    }

    func stepBouncingMover(at index: Int, dt: TimeInterval) -> Bool {
        var mover = movers[index]
        var position = mover.position
        var impacted = false

        var xCandidate = Vec2(x: position.x + mover.velocity.x * dt, y: position.y)
        if moverIsBlocked(at: xCandidate, radius: mover.radius) {
            impacted = true
            mover.velocity.x *= -1
            xCandidate = Vec2(x: position.x + mover.velocity.x * dt, y: position.y)
        }
        if !moverIsBlocked(at: xCandidate, radius: mover.radius) {
            position.x = xCandidate.x
        }

        var yCandidate = Vec2(x: position.x, y: position.y + mover.velocity.y * dt)
        if moverIsBlocked(at: yCandidate, radius: mover.radius) {
            impacted = true
            mover.velocity.y *= -1
            yCandidate = Vec2(x: position.x, y: position.y + mover.velocity.y * dt)
        }
        if !moverIsBlocked(at: yCandidate, radius: mover.radius) {
            position.y = yCandidate.y
        }

        mover.position = clampToArena(position, radius: mover.radius)
        movers[index] = mover
        return impacted
    }

    func moverIsBlocked(at position: Vec2, radius: Double) -> Bool {
        let inset = config.edgeInset + radius
        if position.x < inset || position.x > level.worldWidth - inset
            || position.y < inset || position.y > level.worldHeight - inset {
            return true
        }
        if level.walls.contains(where: { $0.intersectsCircle(center: position, radius: radius) }) {
            return true
        }
        return gates.contains { $0.solid && $0.area.intersectsCircle(center: position, radius: radius) }
    }

    func collideMovers() -> DeathCause? {
        for mover in movers {
            let limit = config.playerRadius + mover.radius - config.collisionSlop
            if playerPosition.distance(to: mover.position) < limit {
                return .asteroid
            }
        }
        return nil
    }

    func collideLasers() -> DeathCause? {
        guard !effects.isFrozen, !effects.isPrismatic else { return nil }
        for laser in lasers where laser.phase == .firing {
            let limit = config.playerRadius + laser.beamWidth / 2 - config.collisionSlop
            if playerPosition.distance(toSegmentFrom: laser.start, to: laser.end) < limit {
                return .laser
            }
        }
        return nil
    }

    func collideEchoes() -> DeathCause? {
        for (index, echo) in echoes.enumerated() {
            let limit = config.playerRadius + config.echoRadius - config.collisionSlop
            if playerPosition.distance(to: echo) < limit {
                return .echo(index: index, delay: Double(index + 1) * level.echoInterval)
            }
        }
        return nil
    }

    func refreshThreats() {
        var best: EchoThreat?
        for (index, echo) in echoes.enumerated() {
            let dist = playerPosition.distance(to: echo)
            let delay = Double(index + 1) * level.echoInterval
            let futureEcho = recorder.position(at: max(0, playbackTime - delay + config.lookAhead)) ?? echo
            let futurePlayer: Vec2
            if lastVelocity.length > 1 {
                futurePlayer = playerPosition + lastVelocity * config.lookAhead
            } else {
                futurePlayer = playerPosition
            }
            let futureDist = futurePlayer.distance(to: futureEcho)
            let collide = futureDist < (config.playerRadius + config.echoRadius) * 1.8
            let eta = lastVelocity.length > 1 ? dist / max(currentSpeed, 1) : dist / 120
            let threat = EchoThreat(echoIndex: index, distance: dist, eta: eta, willCollide: collide)
            if best == nil || threat.willCollide && !(best!.willCollide) || threat.distance < (best?.distance ?? .infinity) {
                best = threat
            }
        }
        nearestThreat = best
    }
}
