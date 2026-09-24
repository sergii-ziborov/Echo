import Foundation
import QuartzCore
import WatchConnectivity

/// The iPhone end of the Apple Watch link. It banks clears from the wrist
/// campaign, and while a run is on screen it lets the watch steer the orb and
/// streams a small radar back so the wrist shows what it is driving.
@MainActor
@Observable
final class PhoneWatchLink: NSObject {
    static let shared = PhoneWatchLink()

    /// False on iPad, which cannot pair with an Apple Watch.
    static var isAvailable: Bool { WCSession.isSupported() }

    private(set) var isPaired = false
    private(set) var isWatchAppInstalled = false
    /// True while the watch remote is open and talking to this phone.
    private(set) var isSteering = false

    @ObservationIgnored var onProgress: (@MainActor (WristProgress) -> Void)?
    @ObservationIgnored private weak var session: GameSession?
    @ObservationIgnored private weak var scene: GameScene?
    @ObservationIgnored private var lastHello: TimeInterval = 0
    @ObservationIgnored private var lastStick: TimeInterval = 0
    @ObservationIgnored private var lastRadar: TimeInterval = 0
    @ObservationIgnored private var stickHeld = false
    @ObservationIgnored private var activated = false

    func activate() {
        guard !activated, WCSession.isSupported() else { return }
        activated = true
        let link = WCSession.default
        link.delegate = self
        link.activate()
    }

    func attach(session: GameSession, scene: GameScene) {
        self.session = session
        self.scene = scene
        stickHeld = false
    }

    func detach(session: GameSession) {
        guard self.session === session else { return }
        self.session = nil
        scene = nil
        stickHeld = false
    }

    /// Called every frame by the arena: lets go of a stick the watch stopped
    /// sending and streams the radar at a watch-friendly rate.
    func tick() {
        guard activated else { return }
        let now = CACurrentMediaTime()
        if isSteering, now - lastHello > 3 { isSteering = false }
        if stickHeld, now - lastStick > 1.0 { release() }
        guard isSteering, now - lastRadar > 1.0 / 12, let session else { return }
        let link = WCSession.default
        guard link.activationState == .activated, link.isReachable else { return }
        lastRadar = now
        let frame = RadarFrame(simulation: session.sim, state: radarState(of: session))
        link.sendMessage(frame.payload, replyHandler: nil, errorHandler: nil)
    }

    func apply(_ command: RemoteCommand) {
        let now = CACurrentMediaTime()
        lastHello = now
        isSteering = true
        guard let session else { return }
        switch command {
        case .hello:
            break
        case .stick(let vector):
            guard session.phase == .playing else { return }
            lastStick = now
            stickHeld = true
            session.inputTarget = RemoteSteering.target(stick: vector, player: session.sim.playerPosition)
        case .release:
            release()
        case .dash:
            guard session.phase == .playing, session.sim.tryDash() else { return }
            scene?.abilityEffect(kind: .surge, at: session.sim.playerPosition)
            scene?.onEvents?([.dashed])
        case .pause:
            session.togglePause()
        }
    }

    private func release() {
        stickHeld = false
        session?.inputTarget = nil
    }

    private func radarState(of session: GameSession) -> RadarFrame.State {
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

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let command = RemoteCommand(message) else { return }
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
