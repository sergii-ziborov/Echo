import Foundation
import WatchConnectivity

/// The watch end of the phone link: banks wrist clears on the iPhone, sends
/// remote-control commands, and receives the arena of the phone's run.
@MainActor
@Observable
final class WatchLink: NSObject {
    static let shared = WatchLink()

    private(set) var isReachable = false
    /// The phone run's level, built from the watch's own catalog.
    private(set) var level: LevelDefinition?
    private(set) var levelToken: UInt32 = 0
    private(set) var frame: RemoteFrame?
    private(set) var frameStamp: TimeInterval = 0
    /// How late frames arrive from the phone, smoothed, in seconds.
    private(set) var lag: TimeInterval = 0
    @ObservationIgnored private var outbox = RemoteOutbox()
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
        outbox.post(command)
        pump()
    }

    /// The live frame, if the phone is still sending them.
    var liveFrame: RemoteFrame? {
        guard isReachable, level != nil, ProcessInfo.processInfo.systemUptime - frameStamp < 2 else { return nil }
        return frame
    }

    private func pump() {
        let link = WCSession.default
        guard activated, link.activationState == .activated, link.isReachable,
              let command = outbox.next(now: ProcessInfo.processInfo.systemUptime) else { return }
        link.sendMessageData(command.data, replyHandler: { @Sendable [weak self] _ in
            Task { @MainActor in self?.delivered() }
        }, errorHandler: { @Sendable [weak self] _ in
            Task { @MainActor in self?.delivered() }
        })
    }

    private func delivered() {
        outbox.delivered()
        pump()
    }

    private func didActivate(reachable: Bool) {
        isReachable = reachable
        send(progress: WatchStore.shared.progress)
    }

    private func receive(_ data: Data) {
        switch data.first.flatMap(RemoteKind.init(rawValue:)) {
        case .level:
            guard let recipe = RemoteLevel(data: data) else { return }
            level = recipe.build()
            levelToken = RemoteLevel.token(of: data)
            frame = nil
        case .frame:
            guard let frame = RemoteFrame(data: data) else { return }
            guard frame.level == levelToken else {
                // The phone moved on to another arena; ask for it right away.
                send(.hello(level: levelToken))
                return
            }
            self.frame = frame
            frameStamp = ProcessInfo.processInfo.systemUptime
            let late = max(0, Date().timeIntervalSince1970 - frame.sentAt)
            lag = lag == 0 ? late : lag * 0.9 + late * 0.1
        default:
            break
        }
    }
}

extension WatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let reachable = session.isReachable
        Task { @MainActor in self.didActivate(reachable: reachable) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in
            self.isReachable = reachable
            if reachable { self.pump() }
        }
    }

    /// Reply at once, with a byte because an empty reply never arrives: the
    /// reply is what lets the phone send its next frame.
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        replyHandler(Data([1]))
        Task { @MainActor in self.receive(messageData) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        Task { @MainActor in self.receive(messageData) }
    }
}
