import Foundation

extension ProgressStore {
    var wristRelics: [WristRelic] { wrist.relics }

    /// The Tourbillon relic recolours the iPhone comet unless the player
    /// switched it off.
    var usesTourbillonTail: Bool {
        wrist.isUnlocked(.tourbillonTail) && wristTrailEnabled
    }

    /// Folds in clears reported by the watch and pays shards once per new map.
    @discardableResult
    func mergeWrist(_ incoming: WristProgress) -> Int {
        let fresh = wrist.merge(incoming)
        let reward = fresh.count * WristProgress.shardsPerMap
        shards += reward
        persist()
        return reward
    }

    func setWristTrail(_ enabled: Bool) {
        wristTrailEnabled = enabled
        persist()
    }
}
