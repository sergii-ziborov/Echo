import Foundation

struct PathSample: Equatable, Sendable {
    var time: TimeInterval
    var position: Vec2
}

/// Ordered timeline of the player's positions. Echoes read this at a fixed delay.
struct PathRecorder: Equatable, Sendable {
    private(set) var samples: [PathSample] = []

    mutating func record(time: TimeInterval, position: Vec2) {
        if let last = samples.last, time < last.time {
            return
        }
        samples.append(PathSample(time: time, position: position))
    }

    func position(at time: TimeInterval) -> Vec2? {
        guard let first = samples.first, let last = samples.last else { return nil }
        if time <= first.time { return first.position }
        if time >= last.time { return last.position }

        var lo = 0
        var hi = samples.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if samples[mid].time < time {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        let i = max(lo, 1)
        let b = samples[i]
        let a = samples[i - 1]
        let span = b.time - a.time
        let u = span > 0 ? (time - a.time) / span : 0
        return a.position.lerp(b.position, u)
    }

    /// Upcoming samples for telegraphing an echo's next motion.
    func polyline(from start: TimeInterval, duration: TimeInterval, stride: TimeInterval = 0.05) -> [Vec2] {
        guard duration > 0, stride > 0 else { return [] }
        var points: [Vec2] = []
        var t = start
        let end = start + duration
        while t <= end {
            if let p = position(at: t) {
                points.append(p)
            }
            t += stride
        }
        return points
    }

    func slice(from start: TimeInterval, to end: TimeInterval) -> [PathSample] {
        samples.filter { $0.time >= start && $0.time <= end }.map {
            PathSample(time: $0.time - start, position: $0.position)
        }
    }

    mutating func truncate(after time: TimeInterval) {
        samples.removeAll { $0.time > time }
    }
}
