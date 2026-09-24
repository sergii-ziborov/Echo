import Foundation
import WatchConnectivity

/// The watch end of the phone link: banks wrist clears on the iPhone, sends
/// remote-control commands and receives the radar of the phone's arena.
@MainActor
@Observable
final class WatchLink: NSObject {
    static let shared = WatchLink()

    private(set) var isReachable = false
    private(set) var radar: RadarFrame?
    private(set) var radarStamp = Date.distantPast
    @ObservationIgnored private var activated = false

    func activate() {
        guard !activated, WCSession.isSupported() else { return }
        activated = true
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// The application context always carries the whole record, so the phone
    /// catches up even after missing messages; a queued transfer also goes
    /// out for every first clear.
    func send(progress: WristProgress, fresh: Bool = false) {
        let link = WCSession.default
        guard activated, link.activationState == .activated else { return }
        let payload = WristLink.progressPayload(progress)
        try? link.updateApplicationContext(payload)
        if fresh { link.transferUserInfo(payload) }
    }

    func send(_ command: RemoteCommand) {
        let link = WCSession.default
        guard activated, link.activationState == .activated, link.isReachable else { return }
        link.sendMessage(command.message, replyHandler: nil, errorHandler: nil)
    }

    private func didActivate(reachable: Bool) {
        isReachable = reachable
        send(progress: WatchStore.shared.progress)
    }

    private func receive(_ frame: RadarFrame) {
        radar = frame
        radarStamp = Date()
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor in self.didActivate(reachable: reachable) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.isReachable = reachable }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let frame = RadarFrame(payload: message) else { return }
        Task { @MainActor in self.receive(frame) }
    }
}
