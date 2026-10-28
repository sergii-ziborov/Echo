import Foundation

struct AdReservation: Codable, Equatable {
    var id: UUID
    var runID: UUID
    var resultID: UUID
    var reservedAt: Date
}
struct AdBudget: Codable, Equatable {
    var version = 1
    var eligibleWins = 0
    var activeSeconds: Double = 0
    var recordedRuns: [UUID] = []
    var started: [Date] = []
    var reservation: AdReservation?
    var wallHighWater = Date.distantPast
    var pendingNextCampaignNumber: Int?
}

@MainActor
final class AdBudgetStore {
    private(set) var value: AdBudget
    private let defaults: UserDefaults
    private let key = "echo.monetization.adBudget.v1"
    private var unpersistedSeconds: Double = 0
    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key), let decoded = try? JSONDecoder().decode(AdBudget.self, from: data), decoded.version == 1 {
            value = decoded
        } else {
            value = AdBudget()
            if defaults.object(forKey: key) != nil { value.wallHighWater = now.addingTimeInterval(86400) }
        }
        // A reservation left by a crash is conservatively treated as a used slot.
        if let pending = value.reservation {
            value.started.append(max(now, pending.reservedAt))
            value.reservation = nil
            value.eligibleWins = 0
            value.activeSeconds = 0
        }
        save()
    }
    func recordWin(_ context: AdContext) {
        guard context.isEligibleWin, !value.recordedRuns.contains(context.runID) else { return }
        value.recordedRuns.append(context.runID)
        value.recordedRuns = Array(value.recordedRuns.suffix(256))
        value.eligibleWins = min(100, value.eligibleWins + 1)
        save()
    }
    func addActiveSeconds(_ duration: Double) {
        guard duration.isFinite, duration > 0 else { return }
        value.activeSeconds = min(3600, value.activeSeconds + min(duration, 0.25))
        unpersistedSeconds += duration
        if unpersistedSeconds >= 5 { unpersistedSeconds = 0; save() }
    }
    func observeClock(_ now: Date) {
        value.wallHighWater = max(now, value.wallHighWater)
        // Preserve future timestamps on clock rollback.
        let highWater = value.wallHighWater
        value.started.removeAll { highWater.timeIntervalSince($0) >= 86400 }
        save()
    }
    func reserve(_ context: AdContext, now: Date) -> AdReservation? {
        guard value.reservation == nil, now >= value.wallHighWater else { return nil }
        let ticket = AdReservation(id: UUID(), runID: context.runID, resultID: context.resultID, reservedAt: now)
        value.reservation = ticket
        value.pendingNextCampaignNumber = context.campaignNumber + 1
        save()
        return ticket
    }
    func started(_ ticket: AdReservation, now: Date) {
        guard value.reservation?.id == ticket.id else { return }
        value.started.append(max(ticket.reservedAt, now))
        value.reservation = nil
        value.eligibleWins = 0
        value.activeSeconds = 0
        save()
    }
    func cancel(_ ticket: AdReservation) {
        guard value.reservation?.id == ticket.id else { return }
        value.reservation = nil
        save()
    }
    func completeTransition() {
        value.pendingNextCampaignNumber = nil
        save()
    }
    private func save() {
        if let bytes = try? JSONEncoder().encode(value) { defaults.set(bytes, forKey: key) }
    }
}
