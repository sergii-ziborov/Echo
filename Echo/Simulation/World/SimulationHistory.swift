import Foundation

extension WorldSimulation {
    func clampToArena(_ position: Vec2, radius: Double) -> Vec2 {
        let inset = config.edgeInset + radius
        return position.clamped(
            minX: inset,
            minY: inset,
            maxX: level.worldWidth - inset,
            maxY: level.worldHeight - inset
        )
    }

    func resolveWalls(_ position: Vec2, radius: Double) -> Vec2 {
        var p = position
        for wall in level.walls {
            p = CircleMath.resolve(center: p, radius: radius, box: wall)
        }
        for gate in gates where gate.solid {
            p = CircleMath.resolve(center: p, radius: radius, box: gate.area)
        }
        return clampToArena(p, radius: radius)
    }

    func captureSnapshot() {
        snapshots.append(
            WorldSnapshot(
                time: time,
                playbackTime: playbackTime,
                player: playerPosition,
                lastVelocity: lastVelocity,
                lastAim: lastAim,
                echoes: echoes,
                sparks: sparks,
                bonuses: bonuses,
                movers: movers,
                lasers: lasers,
                rifts: rifts,
                gates: gates,
                scars: scars,
                effects: effects,
                exitOpen: exitOpen,
                moves: moves,
                bonusesCollected: bonusesCollected,
                timedSparksSecured: timedSparksSecured,
                resonanceChain: resonanceChain,
                bestResonance: bestResonance,
                resonanceRemaining: resonanceRemaining,
                hasStarted: hasStarted,
                recorder: recorder,
                pulseDelay: pulseDelay,
                warnedFor: warnedFor,
                distanceAcc: distanceAcc,
                ghosts: ghosts,
                dashed: dashed,
                usedItem: usedItem,
                scarsCreated: scarsCreated,
                riftsUsed: riftsUsed,
                closestApproach: closestApproach,
                reality: reality,
                realityRemaining: realityRemaining,
                riftTravelCooldown: riftTravelCooldown
            )
        )
        let window = max(config.snapshotWindow, tuning.rewindSeconds) + 0.25
        let keep = Int((window * config.snapshotHz).rounded(.up)) + 8
        if snapshots.count > keep {
            snapshots.removeFirst(snapshots.count - keep)
        }
        if lastReviewTime < 0 || time - lastReviewTime >= 1.0 / 12.0 || phase != .playing {
            reviewFrames.append(RenderFrame(simulation: self))
            lastReviewTime = time
        }
    }

    func refreshGhosts() {
        ghosts.removeAll { !$0.isAlive(at: time) }
    }

    func collideGhosts() -> DeathCause? {
        let limit = config.playerRadius + config.echoRadius - config.collisionSlop
        for ghost in ghosts {
            if let point = ghost.position(at: time), playerPosition.distance(to: point) < limit {
                return .ghost
            }
        }
        return nil
    }

    func trackClosest() {
        for echo in echoes {
            closestApproach = min(closestApproach, playerPosition.distance(to: echo))
        }
        for ghost in ghosts {
            if let point = ghost.position(at: time) {
                closestApproach = min(closestApproach, playerPosition.distance(to: point))
            }
        }
    }
}
