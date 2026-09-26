import SpriteKit
import SwiftUI
import WatchKit

/// A wrist run. Touch a point and the orb flies there, even after the finger
/// lifts, so it never hides under your thumb. Double-tap to dash, turn the
/// Digital Crown back to rewind.
struct WatchRunView: View {
    /// Space above the arena for the HUD and the system clock.
    static let band: CGFloat = 28

    @State private var level: LevelDefinition
    @State private var run: WatchRun?
    @State private var scene: WatchArenaScene?
    @State private var crown = 0.0
    @State private var crownPull = 0.0
    @State private var touchBegan: Date?
    @State private var lastTap = Date.distantPast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(level: LevelDefinition) {
        _level = State(initialValue: level)
    }

    var body: some View {
        GeometryReader { geo in
            let arena = CGSize(width: geo.size.width, height: max(40, geo.size.height - Self.band))
            ZStack(alignment: .top) {
                Color(uiColor: WatchArenaScene.color(level.theme.sky))
                if let run, let scene {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .frame(width: arena.width, height: arena.height)
                        .gesture(steering(size: arena, run: run, scene: scene))
                        .padding(.top, Self.band)
                    WatchRunHUD(run: run, onFreeze: { run.freeze() }, onPause: { run.togglePause() })
                    overlay(run)
                }
            }
            .onAppear { start(size: arena) }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .focusable()
        .digitalCrownRotation($crown, from: -1_000_000, through: 1_000_000, by: 0.05, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crown) { old, new in crownTurned(by: new - old) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, run?.phase == .playing { run?.togglePause() }
        }
    }

    private func start(size: CGSize) {
        guard run == nil, size.width > 10 else { return }
        let fresh = WatchRun(level: level, aspect: Double(size.height / size.width), skills: WatchStore.shared.skills)
        run = fresh
        scene = WatchArenaScene(run: fresh, size: size)
    }

    private func steering(size: CGSize, run: WatchRun, scene: WatchArenaScene) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if touchBegan == nil { touchBegan = value.time }
                guard run.isLive else { return }
                run.target = scene.world(CGPoint(x: value.location.x, y: size.height - value.location.y))
            }
            .onEnded { value in
                let quick = value.time.timeIntervalSince(touchBegan ?? value.time) < 0.25
                let still = hypot(value.translation.width, value.translation.height) < 10
                touchBegan = nil
                guard quick, still else { return }
                if value.time.timeIntervalSince(lastTap) < 0.35 {
                    run.dash()
                    lastTap = .distantPast
                } else {
                    lastTap = value.time
                }
            }
    }

    /// A deliberate backward turn of the crown rewinds; forward turns reset it.
    private func crownTurned(by delta: Double) {
        guard let run else { return }
        crownPull = delta < 0 ? crownPull + delta : 0
        if crownPull < -1.2 {
            crownPull = 0
            run.rewind()
        }
    }

    @ViewBuilder
    private func overlay(_ run: WatchRun) -> some View {
        switch run.phase {
        case .ready:
            // The room's log line, until the first touch starts the run.
            VStack(spacing: 6) {
                Text(Copy.text("watch.tapToFly"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.45), in: Capsule())
                Text(Copy.text("wrist.\(level.number).log"))
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineLimit(5)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .padding(.horizontal, 14)
            }
            .frame(maxHeight: .infinity)
            .allowsHitTesting(false)
        case .playing:
            EmptyView()
        case .paused:
            WatchRunCard(title: Copy.text("watch.paused"), tint: .cyan) {
                cardActions(primary: Button(Copy.text("watch.resume"), systemImage: "play.fill") { run.togglePause() }, leaveIcon: "xmark", leaveLabel: Copy.text("watch.leave"))
            }
        case .dead(let cause):
            WatchRunCard(title: Copy.text("watch.lost"), subtitle: cause.watchLabel, tint: .pink) {
                if run.canRewind {
                    Label(Copy.format("watch.crownBack", run.rewindsLeft), systemImage: "digitalcrown.arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
                cardActions(primary: Button(Copy.text("watch.retry"), systemImage: "arrow.counterclockwise") { run.restart() }, leaveIcon: "xmark", leaveLabel: Copy.text("watch.leave"))
            }
        case .won(let time, let newClear):
            WatchRunCard(
                title: Copy.text("watch.cleared"),
                subtitle: clearedLine(time: time, newClear: newClear),
                tint: .yellow
            ) {
                if let next = WristCatalog.maps.first(where: { $0.number == level.number + 1 }) {
                    cardActions(primary: Button(next.title, systemImage: "forward.fill") { advance(to: next) }, leaveIcon: "list.bullet", leaveLabel: Copy.text("watch.rooms"))
                } else {
                    Button(Copy.text("watch.rooms"), systemImage: "list.bullet") { dismiss() }
                }
            }
        }
    }

    /// One row per card so the whole card fits the 40 mm face: the main
    /// action wide, leaving as a round icon beside it.
    private func cardActions(primary: Button<Label<Text, Image>>, leaveIcon: String, leaveLabel: String) -> some View {
        HStack(spacing: 6) {
            primary
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Button { dismiss() } label: {
                Image(systemName: leaveIcon)
            }
            .frame(width: 48)
            .accessibilityLabel(leaveLabel)
        }
    }

    private func clearedLine(time: TimeInterval, newClear: Bool) -> String {
        let seconds = Copy.format("unit.seconds", Copy.seconds(time))
        return newClear ? Copy.format("watch.reward", seconds, WristProgress.shardsPerMap) : seconds
    }

    private func advance(to next: LevelDefinition) {
        guard let size = scene?.size else { return }
        level = next
        run = nil
        scene = nil
        start(size: size)
    }
}

extension DeathCause {
    var watchLabel: String {
        switch self {
        case .echo: Copy.text("watch.cause.echo")
        case .asteroid: Copy.text("watch.cause.asteroid")
        case .laser: Copy.text("watch.cause.laser")
        default: Copy.text("watch.cause.other")
        }
    }
}

/// The small overlay on top of a wrist run: pause and counters in the band
/// above the arena, skills tucked into the lower corners.
struct WatchRunHUD: View {
    let run: WatchRun
    let onFreeze: () -> Void
    let onPause: () -> Void

    /// The echo ring becomes a countdown digit while the next echo is on its
    /// way, so the band never grows into the system clock on a 40 mm face.
    private var echoSymbol: String {
        guard run.phase == .playing, let second = run.nextEchoSecond, (0...50).contains(second) else {
            return "circle.dotted"
        }
        return "\(second).circle"
    }

    private var echoIsClose: Bool {
        run.phase == .playing && (run.nextEchoSecond ?? .max) <= 2
    }

    var body: some View {
        VStack {
            // Sized so a 24-hour system clock still fits beside it on a 40 mm face.
            HStack(spacing: 5) {
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 8, weight: .black))
                        .frame(width: 20, height: 20)
                        .background(.white.opacity(0.14), in: Circle())
                }
                .buttonStyle(.plain)
                Label("\(run.collected)/\(run.sim.sparks.count)", systemImage: "sparkle")
                    .foregroundStyle(.cyan)
                Label("\(run.echoCount)/\(run.level.maxEchoes)", systemImage: echoSymbol)
                    .foregroundStyle(echoIsClose ? .pink : Color(red: 0.8, green: 0.5, blue: 1))
                Spacer()
            }
            .labelStyle(.compact)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .frame(height: WatchRunView.band)
            .padding(.top, 2)
            .padding(.leading, 12)

            Spacer()

            HStack(alignment: .bottom) {
                if run.skills.contains(.crownRewind) {
                    Label("\(run.rewindsLeft)", systemImage: "digitalcrown.arrow.counterclockwise")
                        .labelStyle(.compact)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.cyan.opacity(run.canRewind ? 0.85 : 0.35))
                        .padding(.bottom, 6)
                }
                Spacer()
                if run.skills.contains(.tickFreeze) {
                    Button(action: onFreeze) {
                        Image(systemName: "snowflake")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(run.canFreeze ? .cyan : .gray)
                            .frame(width: 30, height: 30)
                            .background(.black.opacity(0.4), in: Circle())
                            .overlay(Circle().stroke(.cyan.opacity(run.canFreeze ? 0.8 : 0.2), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .handGestureShortcut(.primaryAction)
                    .disabled(!run.canFreeze)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }
}

struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == CompactLabelStyle {
    static var compact: CompactLabelStyle { CompactLabelStyle() }
}

/// A compact result card shown over a paused or finished run.
struct WatchRunCard<Actions: View>: View {
    let title: String
    var subtitle: String?
    let tint: Color
    @ViewBuilder let actions: Actions

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 7) {
                    Text(title.uppercased())
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(tint)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    actions
                }
                .padding(.horizontal, 10)
                .padding(.top, 26)
            }
        }
    }
}
