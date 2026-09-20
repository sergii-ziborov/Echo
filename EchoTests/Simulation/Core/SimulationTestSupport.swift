import XCTest
@testable import Echo

func advance(_ sim: WorldSimulation, seconds: TimeInterval, target: Vec2) {
    let steps = Int((seconds * 60).rounded(.up))
    for _ in 0..<steps {
        if sim.phase != .playing { return }
        sim.step(dt: 1.0 / 60.0, target: target)
    }
}
