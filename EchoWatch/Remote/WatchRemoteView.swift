import SpriteKit
import SwiftUI
import WatchKit

/// Steer the orb that is running on the iPhone. The whole face is a
/// thumbstick: drag away from where you touched to fly that way, double-tap
/// to dash. Underneath, a close-up of the phone's arena follows the orb, with
/// rocks, echoes, the next spark and the exit pinned to the rim while they
/// are off the face. After a crash, turn the Crown back to rewind the phone.
struct WatchRemoteView: View {
    @State private var link = WatchLink.shared
    @State private var scene: RemoteScopeScene?
    @State private var anchor: CGPoint?
    @State private var knob: CGPoint?
    @State private var stick: Vec2?
    @State private var touchBegan: Date?
    @State private var lastTap = Date.distantPast
    @State private var crown = 0.0
    @State private var crownPull = 0.0
    @State private var keepAlive: Task<Void, Never>?
    @State private var haptics = RemoteHaptics()
    @Environment(\.dismiss) private var dismiss

    private let travel: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            let arena = CGSize(width: geo.size.width, height: max(40, geo.size.height - WatchRunView.band))
            ZStack(alignment: .top) {
                Color(uiColor: scene.map { WatchArenaScene.color($0.level.theme.sky) } ?? .black)
                if let scene, let frame = link.liveFrame {
                    SpriteView(scene: scene, preferredFramesPerSecond: 60)
                        .frame(width: arena.width, height: arena.height)
                        .padding(.top, WatchRunView.band)
                        .allowsHitTesting(false)
                    stickRing
                    RemoteHUD(frame: frame, level: scene.level, lag: link.lag, onBack: { dismiss() }, onPause: { link.send(.pause) })
                    card(for: frame)
                } else {
                    waiting
                }
            }
            .contentShape(Rectangle())
            .gesture(stickGesture)
            .onAppear { prepare(size: arena) }
            .onChange(of: link.levelToken) { prepare(size: arena) }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .focusable()
        .digitalCrownRotation($crown, from: -1_000_000, through: 1_000_000, by: 0.05, sensitivity: .medium, isContinuous: true, isHapticFeedbackEnabled: true)
        .onChange(of: crown) { old, new in crownTurned(by: new - old) }
        .onChange(of: link.frame) { _, frame in haptics.feel(frame, level: scene?.level) }
        .onAppear(perform: startKeepAlive)
        .onDisappear {
            keepAlive?.cancel()
            link.send(.release)
        }
    }

    /// Builds the close-up once the phone has said which level it is running.
    private func prepare(size: CGSize) {
        guard let level = link.level, size.width > 10 else { return }
        if let scene, scene.level == level { return }
        let fresh = RemoteScopeScene(level: level, size: size)
        fresh.source = {
            let link = WatchLink.shared
            guard let frame = link.liveFrame else { return nil }
            return (frame, link.frameStamp)
        }
        scene = fresh
    }

    private var waiting: some View {
        VStack(spacing: 6) {
            HStack {
                RemoteRoundButton(symbol: "chevron.left") { dismiss() }
                    .accessibilityLabel("Leave remote")
                Spacer()
            }
            .frame(height: WatchRunView.band)
            .padding(.top, 2)
            .padding(.leading, 12)
            Spacer()
            Image(systemName: "iphone.radiowaves.left.and.right")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.purple)
            Text(link.isReachable ? "Start a map on iPhone" : "Open ECHO on iPhone")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
            Text("This face becomes the stick")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var stickRing: some View {
        if let anchor {
            Circle()
                .stroke(Color.cyan.opacity(0.45), lineWidth: 1.5)
                .frame(width: travel * 2, height: travel * 2)
                .position(anchor)
                .allowsHitTesting(false)
            Circle()
                .fill(Color.cyan.opacity(0.85))
                .frame(width: 22, height: 22)
                .shadow(color: .cyan, radius: 6)
                .position(knob ?? anchor)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func card(for frame: RemoteFrame) -> some View {
        switch frame.state {
        case .paused:
            WatchRunCard(title: "Paused", tint: .cyan) {
                HStack(spacing: 6) {
                    Button("Resume", systemImage: "play.fill") { link.send(.pause) }
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .frame(width: 48)
                        .accessibilityLabel("Leave remote")
                }
            }
        case .dead:
            WatchRunCard(title: "Crashed", subtitle: frame.cause?.watchLabel, tint: .pink) {
                if frame.rewindsLeft > 0 {
                    Label("Turn the Crown back · \(frame.rewindsLeft)", systemImage: "digitalcrown.arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan)
                }
                Button("Retry", systemImage: "arrow.counterclockwise") { link.send(.retry) }
            }
        case .won:
            WatchRunCard(title: "Cleared", subtitle: "Pick the next map on iPhone", tint: .yellow) {
                Button("Replay", systemImage: "arrow.counterclockwise") { link.send(.retry) }
            }
        case .ready, .playing:
            EmptyView()
        }
    }

    private var stickGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if anchor == nil {
                    anchor = value.startLocation
                    touchBegan = value.time
                }
                guard let anchor else { return }
                var dx = value.location.x - anchor.x
                var dy = value.location.y - anchor.y
                let length = hypot(dx, dy)
                if length > travel {
                    dx *= travel / length
                    dy *= travel / length
                }
                knob = CGPoint(x: anchor.x + dx, y: anchor.y + dy)
                // Screen y grows downward; the arena's grows upward.
                let vector = Vec2(x: Double(dx / travel), y: Double(-dy / travel))
                stick = vector
                link.send(.stick(vector))
            }
            .onEnded { value in
                let quick = value.time.timeIntervalSince(touchBegan ?? value.time) < 0.25
                let still = hypot(value.translation.width, value.translation.height) < 10
                anchor = nil
                knob = nil
                stick = nil
                touchBegan = nil
                link.send(.release)
                guard quick, still else { return }
                if value.time.timeIntervalSince(lastTap) < 0.35 {
                    link.send(.dash)
                    WKInterfaceDevice.current().play(.directionUp)
                    lastTap = .distantPast
                } else {
                    lastTap = value.time
                }
            }
    }

    /// After a crash, a deliberate backward turn asks the phone to rewind.
    private func crownTurned(by delta: Double) {
        guard let frame = link.liveFrame, frame.state == .dead, frame.rewindsLeft > 0 else {
            crownPull = 0
            return
        }
        crownPull = delta < 0 ? crownPull + delta : 0
        if crownPull < -1.2 {
            crownPull = 0
            link.send(.rewind)
        }
    }

    /// Says hello every second and, while a finger holds the stick, repeats
    /// it four times a second: the phone lets go of a stick that goes quiet.
    private func startKeepAlive() {
        keepAlive?.cancel()
#if DEBUG
        // Review aid: circle the stick so the phone can be checked without touch input.
        let demo = ProcessInfo.processInfo.arguments.contains("-wrist-remote-demo")
#else
        let demo = false
#endif
        keepAlive = Task { @MainActor in
            var tick = 0
            while !Task.isCancelled {
                if tick % 4 == 0 { link.send(.hello(level: link.levelToken)) }
                if demo {
                    let angle = Double(tick) * 0.3
                    link.send(.stick(Vec2(x: cos(angle), y: sin(angle))))
                } else if let stick {
                    link.send(.stick(stick))
                }
                tick += 1
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }
}
