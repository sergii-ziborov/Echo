import Foundation

/// Wrist campaign progress kept on the watch and mirrored to the phone.
@MainActor
@Observable
final class WatchStore {
    static let shared = WatchStore()

    private let defaults: UserDefaults
    private let key = "echo.watch.progress.v1"
    private(set) var progress: WristProgress

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(WristProgress.self, from: data) {
            progress = decoded
        } else {
            progress = WristProgress()
        }
    }

    var clears: Int { progress.cleared.count }

    var skills: Set<WristSkill> {
        Set(WristSkill.allCases.filter { clears >= $0.requiredClears })
    }

    /// Stores a clear and tells the phone. Returns true for a first clear.
    @discardableResult
    func record(_ level: LevelDefinition, time: TimeInterval) -> Bool {
        let fresh = !progress.cleared.contains(level.id)
        progress.record(clear: level.id, time: time)
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: key)
        }
        WatchLink.shared.send(progress: progress, fresh: fresh)
        return fresh
    }

#if DEBUG
    func debugClearAll() {
        for level in WristCatalog.maps where !progress.cleared.contains(level.id) {
            progress.record(clear: level.id, time: level.parTime)
        }
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: key)
        }
        WatchLink.shared.send(progress: progress, fresh: true)
    }
#endif
}
