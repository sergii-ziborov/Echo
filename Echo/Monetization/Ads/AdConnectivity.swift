import Foundation
import Network

/// Reachability only: observes the system path without contacting a server.
@MainActor
@Observable
final class AdConnectivity {
    private(set) var isOnline: Bool
    var onChange: (() -> Void)?
    @ObservationIgnored private var monitor: NWPathMonitor?

    init(initialStatus: Bool = false) { isOnline = initialStatus }

    static func system() -> AdConnectivity {
        let result = AdConnectivity()
        let monitor = NWPathMonitor()
        result.monitor = monitor
        monitor.pathUpdateHandler = { [weak result] path in
            let online = path.status == .satisfied
            Task { @MainActor [weak result] in result?.update(online: online) }
        }
        monitor.start(queue: DispatchQueue(label: "echo.monetization.connectivity"))
        return result
    }

    func update(online: Bool) {
        guard online != isOnline else { return }
        isOnline = online
        onChange?()
    }

    deinit { monitor?.cancel() }
}
