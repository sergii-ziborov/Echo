import Foundation

extension ProgressStore {
    /// Starts a fresh Deep Time run and remembers it for resuming.
    func startEndlessRun(_ key: EndlessKey = .fresh()) -> EndlessKey {
        endless.start(key)
        persist()
        return key
    }

    /// Banks a cleared depth: research points, the best depth, and the next
    /// depth to play if the run is left and resumed later.
    func recordEndlessClear(_ key: EndlessKey, result: SessionResult) -> Int {
        endless.cleared(key)
        shards += result.points
        persist()
        return result.points
    }

    func endEndlessRun(_ key: EndlessKey) {
        endless.end(key)
        persist()
    }
}
