import SpriteKit

/// Comet tails for the orb, its echoes and paradox ghosts. Each actor keeps a
/// short, time-stamped history of where it has been. Every frame that history
/// is laid out along its own path as soft additive puffs (the body of the
/// tail), a hotter streak close to the head, and dust motes that drift out of
/// the tail as they age. The tail starts as wide as the head, so the orb reads
/// as a comet's nucleus instead of a ball on a string. Everything is a pure
/// function of the samples and the clock, so replays, rewinds and pauses draw
/// the same tail.
@MainActor
final class TrailRenderer {
    struct Station: Equatable {
        var position: CGPoint
        /// 0 at the head, 1 where the tail's lifetime runs out.
        var age: CGFloat
    }

    struct Mote: Equatable {
        var position: CGPoint
        var size: CGFloat
        var alpha: CGFloat
    }

    @MainActor
    private final class Actor {
        var samples: [VisualTrailPoint] = []
        var lastPosition: CGPoint?
        let layer = SKNode()
        var puffs: [SKSpriteNode] = []
        var streak: [SKSpriteNode] = []
        var motes: [SKSpriteNode] = []

        init(parent: SKNode) {
            parent.addChild(layer)
        }

        func remove() {
            layer.removeFromParent()
        }
    }

    /// How many sprites a comet may use; the watch draws a lighter tail.
    struct Budget: Sendable {
        var spacing: CGFloat = 1
        var puffs = VisualStyle.cometPuffCap
        var streak = VisualStyle.cometStreakCap
        var motes = VisualStyle.cometMoteCap

        static let phone = Budget()
        static let watch = Budget(spacing: 1.6, puffs: 28, streak: 14, motes: 12)
    }

    var budget = Budget.phone
    private weak var parent: SKNode?
    private var actors: [String: Actor] = [:]

    init(parent: SKNode) {
        self.parent = parent
    }

    func reset() {
        actors.values.forEach { $0.remove() }
        actors.removeAll()
    }

    func beginBranch(_ id: String) {
        guard let actor = actors[id], let last = actor.samples.last else { return }
        actor.samples.append(VisualTrailPoint(position: last.position, time: last.time, breakBefore: true))
        actor.lastPosition = nil
    }

    func sample(
        id: String,
        position: CGPoint,
        time: TimeInterval,
        color: UIColor,
        headWidth: CGFloat,
        moving _: Bool,
        breakBefore: Bool = false
    ) {
        guard let parent else { return }
        let actor = actors[id] ?? {
            let created = Actor(parent: parent)
            actors[id] = created
            return created
        }()

        if breakBefore {
            actor.samples.append(VisualTrailPoint(position: position, time: time, breakBefore: true))
            actor.lastPosition = position
            redraw(actor, now: time, width: headWidth, color: color)
            return
        }

        let step = max(2.2, headWidth * VisualStyle.trailStepFactor)
        if let last = actor.lastPosition {
            let gap = hypot(position.x - last.x, position.y - last.y)
            if gap < 0.6 {
                redraw(actor, now: time, width: headWidth, color: color)
                return
            }
            if gap > VisualStyle.teleportGap {
                actor.samples.append(VisualTrailPoint(position: position, time: time, breakBefore: true))
                actor.lastPosition = position
                redraw(actor, now: time, width: headWidth, color: color)
                return
            }
            var remaining = gap
            let dx = (position.x - last.x) / gap
            let dy = (position.y - last.y) / gap
            var cursor = last
            while remaining > step {
                cursor = CGPoint(x: cursor.x + dx * step, y: cursor.y + dy * step)
                remaining -= step
                actor.samples.append(VisualTrailPoint(position: cursor, time: time))
            }
        }
        actor.samples.append(VisualTrailPoint(position: position, time: time))
        actor.lastPosition = position
        if actor.samples.count > VisualStyle.trailCapacity {
            actor.samples.removeFirst(actor.samples.count - VisualStyle.trailCapacity)
        }
        redraw(actor, now: time, width: headWidth, color: color)
    }

    func prune(ids: Set<String>) {
        for key in actors.keys where !ids.contains(key) {
            actors.removeValue(forKey: key)?.remove()
        }
    }

    func visibleSpriteCount(id: String) -> Int {
        guard let actor = actors[id] else { return 0 }
        return (actor.puffs + actor.streak + actor.motes).filter { !$0.isHidden }.count
    }

    func layerZPositions(id: String) -> [CGFloat] {
        guard let actor = actors[id] else { return [] }
        return [actor.puffs, actor.streak, actor.motes].compactMap { $0.first?.zPosition }
    }

    // MARK: - Layout

    /// Evenly spaced points along the recorded path, newest first. `spacing`
    /// maps a station's age to the gap before the next one, so wide puffs near
    /// the head stay sparse and the thin end of the tail stays dense.
    static func stations(
        samples: [VisualTrailPoint],
        now: TimeInterval,
        lifetime: TimeInterval,
        reach: CGFloat = 1,
        spacing: (CGFloat) -> CGFloat
    ) -> [Station] {
        guard now.isFinite, lifetime > 0, reach > 0 else { return [] }
        var result: [Station] = []
        var newer: VisualTrailPoint?
        var carry: CGFloat = 0
        for sample in samples.reversed() {
            guard sample.time.isFinite,
                  sample.position.x.isFinite,
                  sample.position.y.isFinite,
                  sample.time <= now + 0.000_001 else {
                newer = nil
                continue
            }
            if let head = newer, !head.breakBefore, sample.time <= head.time {
                let dx = sample.position.x - head.position.x
                let dy = sample.position.y - head.position.y
                let length = hypot(dx, dy)
                if length > 0.0001 {
                    var travelled = carry
                    while travelled <= length {
                        let t = travelled / length
                        let age = CGFloat((now - (head.time + (sample.time - head.time) * Double(t))) / lifetime)
                        guard age <= reach else { break }
                        result.append(Station(
                            position: CGPoint(x: head.position.x + dx * t, y: head.position.y + dy * t),
                            age: max(0, age)
                        ))
                        travelled += max(0.5, spacing(max(0, age)))
                    }
                    carry = travelled - length
                }
            } else {
                carry = 0
            }
            newer = CGFloat((now - sample.time) / lifetime) > reach ? nil : sample
        }
        return result
    }

    /// Dust shed from the tail. Each mote belongs to one recorded sample, so it
    /// stays put in the world while the comet moves on, then drifts outward and
    /// back as it ages and twinkles out.
    static func motes(samples: [VisualTrailPoint], now: TimeInterval, lifetime: TimeInterval, width: CGFloat, cap: Int = VisualStyle.cometMoteCap) -> [Mote] {
        guard now.isFinite, lifetime > 0, width > 0, samples.count > 1 else { return [] }
        var result: [Mote] = []
        for index in samples.indices.reversed() {
            let sample = samples[index]
            let age = CGFloat((now - sample.time) / lifetime)
            guard sample.time.isFinite, sample.position.x.isFinite, sample.position.y.isFinite,
                  age >= 0, age <= 1 else { continue }
            let grain = grain(sample.position)
            guard grain % 3 == 0 else { continue }
            let ahead = index + 1 < samples.count && !samples[index + 1].breakBefore ? samples[index + 1].position : sample.position
            let behind = index > 0 && !sample.breakBefore ? samples[index - 1].position : sample.position
            let length = hypot(ahead.x - behind.x, ahead.y - behind.y)
            guard length > 0.0001 else { continue }
            let tx = (ahead.x - behind.x) / length
            let ty = (ahead.y - behind.y) / length
            let side = CGFloat((grain >> 8) & 0xFF) / 127.5 - 1
            let lift = CGFloat((grain >> 16) & 0xFF) / 255
            let spread = width * (0.16 + 0.62 * age) * side
            let lag = width * 0.4 * age
            let twinkle = 0.5 + 0.5 * sin(CGFloat(grain & 0xFF) * 0.37 + age * 21)
            result.append(Mote(
                position: CGPoint(x: sample.position.x - ty * spread - tx * lag, y: sample.position.y + tx * spread - ty * lag),
                size: width * (0.1 + 0.12 * lift) * (1 - 0.45 * age),
                alpha: (0.35 + 0.65 * twinkle) * pow(1 - age, 1.3)
            ))
            if result.count >= cap { break }
        }
        return result
    }

    static func puffSize(width: CGFloat, age: CGFloat) -> CGFloat {
        width * 1.75 * (1 - 0.5 * age)
    }

    static func puffAlpha(age: CGFloat) -> CGFloat {
        0.32 * pow(max(0, 1 - age), 1.6)
    }

    static func streakSize(width: CGFloat, age: CGFloat) -> CGFloat {
        width * 0.78 * pow(max(0, 1 - age / VisualStyle.cometStreakReach), 0.6)
    }

    static func streakAlpha(age: CGFloat) -> CGFloat {
        0.5 * pow(max(0, 1 - age / VisualStyle.cometStreakReach), 1.2)
    }

    private static func grain(_ point: CGPoint) -> UInt32 {
        var hash = UInt32(truncatingIfNeeded: Int((point.x * 8).rounded()) &* 73_856_093)
        hash ^= UInt32(truncatingIfNeeded: Int((point.y * 8).rounded()) &* 19_349_663)
        hash = (hash ^ (hash >> 13)) &* 0x5BD1_E995
        return hash ^ (hash >> 15)
    }

    // MARK: - Drawing

    private func redraw(_ actor: Actor, now: TimeInterval, width: CGFloat, color: UIColor) {
        let life = VisualStyle.trailLifetime
        let spread = budget.spacing
        let body = Self.stations(samples: actor.samples, now: now, lifetime: life) { age in
            Self.puffSize(width: width, age: age) * VisualStyle.cometPuffSpacing * spread
        }
        let puffs = min(body.count, budget.puffs)
        fill(&actor.puffs, in: actor.layer, count: puffs, texture: SpriteTextures.puff, z: VisualStyle.trailPuffZ, color: color)
        for index in 0..<puffs {
            let size = Self.puffSize(width: width, age: body[index].age)
            actor.puffs[index].position = body[index].position
            actor.puffs[index].size = CGSize(width: size, height: size)
            actor.puffs[index].alpha = Self.puffAlpha(age: body[index].age)
        }

        let reach = VisualStyle.cometStreakReach
        let core = Self.stations(samples: actor.samples, now: now, lifetime: life, reach: reach) { age in
            max(1.5, Self.streakSize(width: width, age: age) * 0.25 * spread)
        }
        let hot = color.blended(with: .white, amount: 0.6)
        let streaks = min(core.count, budget.streak)
        fill(&actor.streak, in: actor.layer, count: streaks, texture: SpriteTextures.puff, z: VisualStyle.trailStreakZ, color: hot)
        for index in 0..<streaks {
            let size = Self.streakSize(width: width, age: core[index].age)
            actor.streak[index].position = core[index].position
            actor.streak[index].size = CGSize(width: size, height: size)
            actor.streak[index].alpha = Self.streakAlpha(age: core[index].age)
        }

        let dust = Self.motes(samples: actor.samples, now: now, lifetime: life, width: width, cap: budget.motes)
        fill(&actor.motes, in: actor.layer, count: dust.count, texture: SpriteTextures.glint, z: VisualStyle.trailMoteZ, color: color.blended(with: .white, amount: 0.5))
        for (index, mote) in dust.enumerated() {
            actor.motes[index].position = mote.position
            actor.motes[index].size = CGSize(width: mote.size, height: mote.size)
            actor.motes[index].alpha = mote.alpha
        }
    }

    private func fill(_ pool: inout [SKSpriteNode], in layer: SKNode, count: Int, texture: SKTexture, z: CGFloat, color: UIColor) {
        while pool.count < count {
            let sprite = SKSpriteNode(texture: texture)
            sprite.blendMode = .add
            sprite.colorBlendFactor = 1
            sprite.zPosition = z
            layer.addChild(sprite)
            pool.append(sprite)
        }
        for (index, sprite) in pool.enumerated() {
            sprite.isHidden = index >= count
            sprite.color = color
        }
    }
}
