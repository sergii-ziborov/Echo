import SwiftUI

/// Watch-only skills and when each one wakes up.
struct WatchSkillsView: View {
    @State private var store = WatchStore.shared

    var body: some View {
        List(WristSkill.allCases) { skill in
            let awake = store.skills.contains(skill)
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: skill.symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(awake ? .mint : .gray)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(skill.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Text(skill.detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    if !awake {
                        Text("Clear \(skill.requiredClears) wrist maps")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.orange)
                    }
                }
            }
            .opacity(awake ? 1 : 0.6)
            .padding(.vertical, 3)
        }
        .navigationTitle("Skills")
    }
}

/// Relics the wrist campaign unlocks in the iPhone game.
struct WatchRelicsView: View {
    @State private var store = WatchStore.shared

    var body: some View {
        List {
            Text("Every new wrist clear also pays \(WristProgress.shardsPerMap) research points on iPhone.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear)
            ForEach(WristRelic.allCases) { relic in
                let unlocked = store.progress.isUnlocked(relic)
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: relic.symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(unlocked ? .yellow : .gray)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(relic.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Text(relic.detail)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Text(unlocked ? "Active on iPhone" : "\(store.clears)/\(relic.requiredClears) wrist maps")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(unlocked ? .yellow : .orange)
                    }
                }
                .opacity(unlocked ? 1 : 0.65)
                .padding(.vertical, 3)
            }
        }
        .navigationTitle("Relics")
    }
}
