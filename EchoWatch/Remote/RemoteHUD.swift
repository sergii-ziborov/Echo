import SwiftUI
import WatchKit

/// The band above the close-up: back, sparks, echoes with the countdown to
/// the next one, and pause tucked into the lower corner of the face.
struct RemoteHUD: View {
    let frame: RemoteFrame
    let level: LevelDefinition
    let lag: TimeInterval
    let onBack: () -> Void
    let onPause: () -> Void

    private var echoSymbol: String {
        guard frame.state == .playing, let next = frame.nextEcho else { return "circle.dotted" }
        let second = Int(next.rounded(.up))
        return (0...50).contains(second) ? "\(second).circle" : "circle.dotted"
    }

    private var echoIsClose: Bool {
        frame.state == .playing && (frame.nextEcho ?? .infinity) <= 2
    }

    var body: some View {
        VStack {
            HStack(spacing: 5) {
                RemoteRoundButton(symbol: "chevron.left", action: onBack)
                    .accessibilityLabel("Leave remote")
                Label("\(frame.collected.nonzeroBitCount)/\(level.sparks.count)", systemImage: "sparkle")
                    .foregroundStyle(.cyan)
                Label("\(frame.echoes.count)/\(level.maxEchoes)", systemImage: echoSymbol)
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
                RemoteRoundButton(symbol: frame.state == .paused ? "play.fill" : "pause.fill", size: 26, action: onPause)
                    .accessibilityLabel(frame.state == .paused ? "Resume on iPhone" : "Pause on iPhone")
                Spacer()
#if DEBUG
                // Review aid: how late frames from the phone arrive.
                Text("\(Int((lag * 1000).rounded())) ms")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .padding(.bottom, 4)
#endif
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }
}

struct RemoteRoundButton: View {
    let symbol: String
    var size: CGFloat = 20
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(.white.opacity(0.16), in: Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Wrist taps for what happens on the phone, so the run can be felt without
/// looking down: sparks, echoes, the exit opening, and a warning when a rock
/// or an echo is about to reach the orb.
struct RemoteHaptics {
    /// World units between the edges of the orb and a threat that count as close.
    static let warningGap = 70.0

    private var last: RemoteFrame?
    private var lastGap = Double.infinity
    private var lastWarning: TimeInterval = 0

    mutating func feel(_ frame: RemoteFrame?, level: LevelDefinition?) {
        guard let frame else {
            last = nil
            return
        }
        defer { last = frame }
        let gap = level.map { Self.closestGap(in: frame, level: $0) } ?? .infinity
        defer { lastGap = gap }
        guard let last else { return }
        let device = WKInterfaceDevice.current()
        if frame.state != last.state {
            switch frame.state {
            case .dead: device.play(.failure)
            case .won: device.play(.success)
            case .playing where last.state == .dead: device.play(.retry)
            default: break
            }
            return
        }
        guard frame.state == .playing else { return }
        if frame.collected.nonzeroBitCount > last.collected.nonzeroBitCount { device.play(.click) }
        if frame.exitOpen, !last.exitOpen { device.play(.start) }
        if frame.echoes.count > last.echoes.count { device.play(.directionDown) }
        let now = ProcessInfo.processInfo.systemUptime
        if gap < Self.warningGap, gap < lastGap - 1, now - lastWarning > 1.2 {
            lastWarning = now
            device.play(.notification)
        }
    }

    /// The smallest distance between the orb's edge and a rock or an echo.
    static func closestGap(in frame: RemoteFrame, level: LevelDefinition) -> Double {
        let config = SimConfig()
        let radii = Dictionary(level.movers.map { ($0.id, $0.radius) }, uniquingKeysWith: { first, _ in first })
        let rocks = frame.rocks.map { $0.position.distance(to: frame.player) - (radii[$0.id] ?? 30) - config.playerRadius }
        let echoes = frame.echoes.map { $0.distance(to: frame.player) - config.playerRadius - config.echoRadius }
        return (rocks + echoes).min() ?? .infinity
    }
}
