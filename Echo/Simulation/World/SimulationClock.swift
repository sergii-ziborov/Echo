import Foundation

extension WorldSimulation {
    func tickEffects(dt: TimeInterval) {
        if effects.freezeRemaining > 0 { effects.freezeRemaining = max(0, effects.freezeRemaining - dt) }
        if effects.surgeRemaining > 0 { effects.surgeRemaining = max(0, effects.surgeRemaining - dt) }
        if effects.magnetRemaining > 0 { effects.magnetRemaining = max(0, effects.magnetRemaining - dt) }
        if effects.phaseRemaining > 0 {
            effects.phaseRemaining = max(0, effects.phaseRemaining - dt)
            effects.iFrames = max(effects.iFrames, effects.phaseRemaining)
        }
        if effects.anchorRemaining > 0 { effects.anchorRemaining = max(0, effects.anchorRemaining - dt) }
        if effects.prismRemaining > 0 { effects.prismRemaining = max(0, effects.prismRemaining - dt) }
        if effects.dashCooldown > 0 { effects.dashCooldown = max(0, effects.dashCooldown - dt) }
        if effects.iFrames > 0 { effects.iFrames = max(0, effects.iFrames - dt) }
        if riftTravelCooldown > 0 { riftTravelCooldown = max(0, riftTravelCooldown - dt) }
        if realityRemaining > 0 {
            realityRemaining = max(0, realityRemaining - dt)
            if realityRemaining == 0 { reality = .normal }
        }
        inSlowField = level.fields.contains { $0.area.contains(playerPosition) }
    }

    func movePlayer(dt: TimeInterval, target: Vec2?) {
        var velocity = Vec2.zero
        if let target {
            let effectiveTarget = reality == .mirror
                ? Vec2(x: level.worldWidth - target.x, y: target.y)
                : target
            let delta = effectiveTarget - playerPosition
            let dist = delta.length
            if dist > config.inputDeadzone {
                lastAim = delta.normalized()
                let stepLen = min(currentSpeed * dt, dist)
                playerPosition = playerPosition + lastAim * stepLen
                velocity = lastAim * (stepLen / max(dt, 0.0001))
            }
        }
        lastVelocity = velocity
        playerPosition = clampToArena(playerPosition, radius: config.playerRadius)
        playerPosition = resolveWalls(playerPosition, radius: config.playerRadius)

        if velocity.length > 1 {
            distanceAcc += velocity.length * dt
            while distanceAcc >= config.moveQuantum {
                moves += 1
                distanceAcc -= config.moveQuantum
            }
        }
    }

    func spawnEchoesIfNeeded() -> [SimEvent] {
        var events: [SimEvent] = []
        let clock = echoClock
        let desired = min(level.maxEchoes, Int(clock / max(level.echoInterval, 0.001)))

        if desired > echoCount {
            let previous = echoCount
            echoes = Array(repeating: level.playerStart, count: desired)
            for i in previous..<desired {
                events.append(.echoSpawned(index: i))
            }
        }

        if echoCount < level.maxEchoes {
            let remaining = (Double(echoCount + 1) * level.echoInterval) - clock
            if remaining <= level.warningLead, remaining > 0, warnedFor != echoCount {
                warnedFor = echoCount
                events.append(.echoWillSpawn(index: echoCount, in: remaining))
            }
        }
        return events
    }

    func refreshEchoPositions() {
        guard echoCount > 0 else { return }
        for i in 0..<echoCount {
            let delay = Double(i + 1) * level.echoInterval
            echoes[i] = recorder.position(at: max(0, playbackTime - delay)) ?? level.playerStart
        }
    }

    static func makeSparks(_ spawns: [SparkSpawn]) -> [SparkState] {
        spawns.map {
            let expandedTimer = $0.timer.map { max(12, $0 * 1.25) }
            return SparkState(
                id: $0.id,
                position: $0.position,
                collected: false,
                timerDuration: expandedTimer,
                timerRemaining: expandedTimer,
                timedOut: false,
                orbit: $0.orbit
            )
        }
    }

    static func makeBonuses(_ spawns: [BonusSpawn]) -> [BonusState] {
        spawns.map { BonusState(id: $0.id, kind: $0.kind, position: $0.position, collected: false) }
    }

    static func makeRifts(_ spawns: [RiftSpawn]) -> [RiftState] {
        spawns.map {
            RiftState(
                id: $0.id,
                kind: $0.kind,
                position: $0.position,
                radius: $0.radius,
                period: $0.period,
                openFor: $0.openFor,
                phase: $0.phase
            )
        }
    }
}
