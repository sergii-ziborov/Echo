import Foundation

/// Wrist progress travels between the watch and the phone as a plain
/// property-list dictionary: the application context always carries the
/// whole record, and a queued transfer goes out for every first clear.
/// Remote play has its own binary messages, see `RemoteKind`.
enum WristLink {
    static let progressKey = "wrist.progress"

    static func progressPayload(_ progress: WristProgress) -> [String: Any] {
        guard let data = try? JSONEncoder().encode(progress) else { return [:] }
        return [progressKey: data]
    }

    static func progress(in payload: [String: Any]) -> WristProgress? {
        guard let data = payload[progressKey] as? Data else { return nil }
        return try? JSONDecoder().decode(WristProgress.self, from: data)
    }
}
