import SwiftUI

enum WristRoute: Hashable {
    case maps
    case map(Int)
    case remote
    case skills
    case relics
}

/// The watch home: the wrist campaign, the iPhone remote, skills and relics.
struct WatchRootView: View {
    @State private var store = WatchStore.shared
    @State private var path: [WristRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                WatchHero(clears: store.clears, total: WristCatalog.maps.count)
                    .listRowBackground(Color.clear)

                NavigationLink(value: WristRoute.maps) {
                    WatchMenuRow(title: "Wrist Timeline", detail: "\(store.clears)/\(WristCatalog.maps.count) cleared", symbol: "circle.hexagonpath.fill", tint: .cyan)
                }
                NavigationLink(value: WristRoute.remote) {
                    WatchMenuRow(title: "iPhone Remote", detail: "Steer the orb on your phone", symbol: "iphone.radiowaves.left.and.right", tint: .purple)
                }
                NavigationLink(value: WristRoute.skills) {
                    WatchMenuRow(title: "Skills", detail: "\(store.skills.count)/\(WristSkill.allCases.count) awake", symbol: "digitalcrown.arrow.counterclockwise", tint: .mint)
                }
                NavigationLink(value: WristRoute.relics) {
                    WatchMenuRow(title: "iPhone Relics", detail: "\(store.progress.relics.count)/\(WristRelic.allCases.count) unlocked", symbol: "crown.fill", tint: .yellow)
                }
            }
            .navigationTitle("ECHO")
            .navigationDestination(for: WristRoute.self) { route in
                switch route {
                case .maps: WatchMapsView()
                case .map(let number): WatchRunView(level: WristCatalog.maps[max(0, min(WristCatalog.maps.count - 1, number - 1))])
                case .remote: WatchRemoteView()
                case .skills: WatchSkillsView()
                case .relics: WatchRelicsView()
                }
            }
        }
#if DEBUG
        .onAppear(perform: applyLaunchArguments)
#endif
    }

#if DEBUG
    /// Screenshot and review shortcuts, like the phone's -shot-* arguments.
    private func applyLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-wrist-unlock-all") {
            store.debugClearAll()
        }
        if let index = args.firstIndex(of: "-wrist-map"), index + 1 < args.count, let number = Int(args[index + 1]) {
            path = [.maps, .map(number)]
        } else if args.contains("-wrist-remote") || args.contains("-wrist-remote-demo") {
            path = [.remote]
        } else if args.contains("-wrist-skills") {
            path = [.skills]
        } else if args.contains("-wrist-relics") {
            path = [.relics]
        } else if args.contains("-wrist-maps") {
            path = [.maps]
        }
    }
#endif
}

struct WatchHero: View {
    let clears: Int
    let total: Int
    @State private var spin = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(Color.purple.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [3, 4]))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: spin)
                Circle()
                    .fill(RadialGradient(colors: [.white, Color(red: 0.62, green: 0.92, blue: 1)], center: .init(x: 0.4, y: 0.35), startRadius: 1, endRadius: 12))
                    .frame(width: 20, height: 20)
                    .shadow(color: .cyan.opacity(0.8), radius: 6)
            }
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text("You survive the timeline you created.")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.75))
                ProgressView(value: Double(clears), total: Double(max(total, 1)))
                    .tint(.yellow)
            }
        }
        .onAppear { spin = true }
    }
}

struct WatchMenuRow: View {
    let title: String
    let detail: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
