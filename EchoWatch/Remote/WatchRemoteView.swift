import SwiftUI
import WatchKit

/// Steer the orb that is running on the iPhone. The whole screen is a
/// thumbstick: drag away from where you touched to fly that way. The radar
/// underneath mirrors the phone's arena so you can play without looking up.
struct WatchRemoteView: View {
    @State private var link = WatchLink.shared
    @State private var anchor: CGPoint?
    @State private var knob: CGPoint?
    @State private var touchBegan: Date?
    @State private var lastTap = Date.distantPast
    @State private var lastSent = Date.distantPast
    @State private var lastState: RadarFrame.State?
    @State private var keepAlive: Task<Void, Never>?

    private let travel: CGFloat = 34

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadarView(frame: link.radar, live: isLive)
                    .padding(6)
                if let anchor {
                    Circle()
                        .stroke(Color.cyan.opacity(0.45), lineWidth: 1.5)
                        .frame(width: travel * 2, height: travel * 2)
                        .position(anchor)
                    Circle()
                        .fill(Color.cyan.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .shadow(color: .cyan, radius: 6)
                        .position(knob ?? anchor)
                }
                if !isLive {
                    VStack(spacing: 4) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.purple)
                        Text(link.isReachable ? "Start a map on iPhone" : "Open ECHO on iPhone")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                    .padding(10)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(stick)
        }
        .navigationTitle("Remote")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    link.send(.pause)
                    WKInterfaceDevice.current().play(.click)
                } label: {
                    Image(systemName: link.radar?.state == .paused ? "play.fill" : "pause.fill")
                }
            }
        }
        .onAppear(perform: startKeepAlive)
        .onDisappear {
            keepAlive?.cancel()
            link.send(.release)
        }
        .onChange(of: link.radar?.state) { _, state in announce(state) }
    }

    private var isLive: Bool {
        link.isReachable && link.radar != nil && Date().timeIntervalSince(link.radarStamp) < 2
    }

    private var stick: some Gesture {
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
                guard value.time.timeIntervalSince(lastSent) > 0.05 else { return }
                lastSent = value.time
                // Screen y grows downward; the arena's grows upward.
                link.send(.stick(Vec2(x: Double(dx / travel), y: Double(-dy / travel))))
            }
            .onEnded { value in
                let quick = value.time.timeIntervalSince(touchBegan ?? value.time) < 0.25
                let still = hypot(value.translation.width, value.translation.height) < 10
                anchor = nil
                knob = nil
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
                if tick % 12 == 0 { link.send(.hello) }
                if demo {
                    let angle = Double(tick) / 12 * 1.2
                    link.send(.stick(Vec2(x: cos(angle), y: sin(angle))))
                }
                tick += 1
                try? await Task.sleep(for: .milliseconds(demo ? 83 : 1000 / 12))
            }
        }
    }

    private func announce(_ state: RadarFrame.State?) {
        defer { lastState = state }
        guard let state, state != lastState else { return }
        switch state {
        case .dead: WKInterfaceDevice.current().play(.failure)
        case .won: WKInterfaceDevice.current().play(.success)
        default: break
        }
    }
}
