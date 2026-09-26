import Foundation
import QuartzCore
import WatchConnectivity

/// The iPhone end of the Apple Watch link. It banks clears from the wrist
/// campaign, and while a run is on screen it lets the watch steer the orb and
/// streams the run's moving parts back so the wrist can show a close-up.
@MainActor
@Observable
final class PhoneWatchLink: NSObject {
    static let shared = PhoneWatchLink()

    /// False on iPad, which cannot pair with an Apple Watch.
    static var isAvailable: Bool { WCSession.isSupported() }

    /// Run actions the watch can trigger that live in the game view.
    struct RunActions {
        var rewind: (@MainActor () -> Void)?
        var retry: (@MainActor () -> Void)?
    }

    /// The watch repeats a held stick four times a second; if nothing comes
    /// for this long (a lost release, a dropped link) the orb stops.
    static let stickTimeout: TimeInterval = 0.6
    static let frameInterval: TimeInterval = 1.0 / 20
    /// Frames allowed to wait for their replies at once.
    static let frameWindow = 3

    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    /// True while the watch remote is open and talking to this phone.
    private(set) var isSteering = false

    @ObservationIgnored var onProgress: (@MainActor (WristProgress) -> Void)?
    @ObservationIgnored private weak var session: GameSession?
    @ObservationIgnored private weak var scene: GameScene?
    @ObservationIgnored private var actions = RunActions()
    @ObservationIgnored private var level: (data: Data, token: UInt32)?
    @ObservationIgnored private var watchLevel: UInt32 = 0
    @ObservationIgnored private var stick: Vec2?
    @ObservationIgnored private var lastHello: TimeInterval = 0
    @ObservationIgnored private var lastStick: TimeInterval = 0
    @ObservationIgnored private var lastFrame: TimeInterval = 0
    @ObservationIgnored private var framesInFlight: [TimeInterval] = []
    @ObservationIgnored private var levelInFlight = false
    @ObservationIgnored private var activated = false

    func activate() {
        guard !activated, WCSession.isSupported() else { return }
        activated = true
        let link = WCSession.default
        link.delegate = self
        link.activate()
    }

    func attach(session: GameSession, scene: GameScene, level: RemoteLevel, actions: RunActions = RunActions()) {
        self.session = session
        self.scene = scene
        self.actions = actions
        let data = level.data
        self.level = (data, RemoteLevel.token(of: data))
        stick = nil
        levelInFlight = false
        framesInFlight = []
    }

    func detach(session: GameSession) {
        guard self.session === session else { return }
        self.session = nil
        scene = nil
        actions = RunActions()
        level = nil
        stick = nil
    }

    /// Called every frame by the arena: steers from the held stick and
    /// streams the run to the watch.
    func tick(now: TimeInterval = CACurrentMediaTime()) {
        if isSteering, now - lastHello > 3 { isSteering = false }
        steer(now: now)
        stream(now: now)
    }

    func apply(_ command: RemoteCommand, now: TimeInterval = CACurrentMediaTime()) {
        lastHello = now
        isSteering = true
        switch command {
        case .hello(let token):
            watchLevel = token
        case .stick(let vector):
            stick = vector
            lastStick = now
            steer(now: now)
        case .release:
            release()
        case .dash:
            guard let session, session.phase == .playing, session.sim.tryDash() else { return }
            scene?.abilityEffect(kind: .surge, at: session.sim.playerPosition)
            scene?.onEvents?([.dashed])
        case .pause:
            session?.togglePause()
        case .rewind:
            guard case .dead = session?.phase else { return }
            actions.rewind?()
        case .retry:
            switch session?.phase {
            case .dead, .won: actions.retry?()
            default: break
            }
        }
    }

    /// The orb keeps flying toward a point ahead of where it is now, every
    /// frame, so a late message never leaves it chasing a stale target.
    private func steer(now: TimeInterval) {
        guard let stick else { return }
        guard now - lastStick <= Self.stickTimeout else {
            release()
            return
        }
        guard let session, session.phase == .playing else { return }
        session.inputTarget = RemoteSteering.target(stick: stick, player: session.sim.playerPosition)
    }

    private func release() {
        guard stick != nil else { return }
        stick = nil
        session?.inputTarget = nil
    }

    /// The level once, then the newest frames, a few at a time.
    private func stream(now: TimeInterval) {
        guard activated, isSteering, let session, let level else { return }
        let link = WCSession.default
        guard link.activationState == .activated, link.isReachable else { return }
        if watchLevel != level.token {
            guard !levelInFlight else { return }
            levelInFlight = true
            let token = level.token
            link.sendMessageData(level.data, replyHandler: { @Sendable [weak self] _ in
                Task { @MainActor in self?.levelDelivered(token) }
            }, errorHandler: { @Sendable [weak self] _ in
                Task { @MainActor in self?.levelInFlight = false }
            })
            return
        }
        framesInFlight.removeAll { now - $0 >= RemoteOutbox.replyTimeout }
        guard framesInFlight.count < Self.frameWindow, now - lastFrame >= Self.frameInterval else { return }
        framesInFlight.append(now)
        lastFrame = now
        let frame = RemoteFrame(
            sim: session.sim,
            level: level.token,
            state: remoteState(of: session),
            cause: session.deathCause,
            sentAt: Date().timeIntervalSince1970
        )
        link.sendMessageData(frame.data, replyHandler: { @Sendable [weak self] _ in
            Task { @MainActor in self?.frameDelivered() }
        }, errorHandler: { @Sendable [weak self] _ in
            Task { @MainActor in self?.frameDelivered() }
        })
    }

    private func frameDelivered() {
        if !framesInFlight.isEmpty { framesInFlight.removeFirst() }
    }

    private func levelDelivered(_ token: UInt32) {
        levelInFlight = false
        watchLevel = token
    }

    private func remoteState(of session: GameSession) -> RemoteFrame.State {
        switch session.phase {
        case .playing: session.hasStarted ? .playing : .ready
        case .paused: .paused
        case .dead, .replaying: .dead
        case .won, .ballet: .won
        }
    }

    private func updateWatchState(paired: Bool, installed: Bool) {
        isPaired = paired
        isWatchAppInstalled = installed
    }
}

extension PhoneWatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        let banked = WristLink.progress(in: session.receivedApplicationContext)
        Task { @MainActor in
            self.updateWatchState(paired: paired, installed: installed)
            if let banked { self.onProgress?(banked) }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        let paired = session.isPaired
        let installed = session.isWatchAppInstalled
        Task { @MainActor in self.updateWatchState(paired: paired, installed: installed) }
    }

    /// Reply at once, with a byte because an empty reply never arrives: the
    /// reply is what lets the watch send its next message.
    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        replyHandler(Data([1]))
        guard let command = RemoteCommand(data: messageData) else { return }
        Task { @MainActor in self.apply(command) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let command = RemoteCommand(data: messageData) else { return }
        Task { @MainActor in self.apply(command) }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let progress = WristLink.progress(in: userInfo) else { return }
        Task { @MainActor in self.onProgress?(progress) }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let progress = WristLink.progress(in: applicationContext) else { return }
        Task { @MainActor in self.onProgress?(progress) }
    }
}
