import SwiftUI

/// The wrist campaign: twelve maps in three acts, opened one after another.
struct WatchMapsView: View {
    @State private var store = WatchStore.shared

    var body: some View {
        List {
            ForEach(WristCatalog.actTitles.indices, id: \.self) { act in
                Section {
                    ForEach(maps(in: act), id: \.id) { level in
                        if store.progress.isPlayable(level) {
                            NavigationLink(value: WristRoute.map(level.number)) {
                                row(level)
                            }
                        } else {
                            row(level).opacity(0.4)
                        }
                    }
                } header: {
                    Text("\(["I", "II", "III"][act]) · \(WristCatalog.actTitles[act])".uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(act == 0 ? .cyan : act == 1 ? .purple : .orange)
                }
            }
        }
        .navigationTitle(Copy.text("watch.rooms"))
    }

    private func maps(in act: Int) -> [LevelDefinition] {
        WristCatalog.maps.filter { WristCatalog.act(of: $0) == act }
    }

    private func row(_ level: LevelDefinition) -> some View {
        let cleared = store.progress.cleared.contains(level.id)
        let playable = store.progress.isPlayable(level)
        return HStack(spacing: 8) {
            Text(String(format: "%02d", level.number))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(cleared ? .yellow : .cyan)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(level.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                if let best = store.progress.bestTimes[level.id] {
                    Text(Copy.format("watch.best", Copy.seconds(best)))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text(level.tip)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 2)
            Image(systemName: cleared ? "checkmark.seal.fill" : playable ? "chevron.right" : "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(cleared ? .yellow : .secondary)
        }
    }
}
