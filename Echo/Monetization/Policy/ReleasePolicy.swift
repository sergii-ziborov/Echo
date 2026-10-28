import Foundation
import CryptoKit

struct AdLimits: Codable, Equatable, Sendable {
    var minimumEligibleWins = 3
    var minimumActiveSeconds: Double = 240
    var maxPer24Hours = 2
    var cacheMaxAge: Double = 50 * 60
    var bounded: AdLimits {
        AdLimits(minimumEligibleWins: max(3, minimumEligibleWins),
            minimumActiveSeconds: max(240, minimumActiveSeconds),
            maxPer24Hours: min(2, max(0, maxPer24Hours)), cacheMaxAge: min(3000, max(0, cacheMaxAge)))
    }
}

struct ReleasePolicy: Codable, Equatable, Sendable {
    enum Phase: String, Codable { case preFree, freeQuiet, freeLive, adsOff }
    var schema = 1
    var version: UInt64 = 0
    var phase: Phase = .preFree
    var issuedAt: Date = .distantPast
    var expiresAt: Date = .distantPast
    var cutover: CutoverPolicy?
    var audienceReviewed = false
    var familySharingEnabled = false
    var limits = AdLimits()

    func permitsAds(at now: Date) -> Bool {
        schema == 1 && version > 0 && phase == .freeLive && audienceReviewed
            && issuedAt <= now && now < expiresAt && expiresAt > issuedAt
    }
    /// Selected only after StoreKit supplies a verified non-production environment.
    static var storeKitTesting: ReleasePolicy {
        ReleasePolicy(version: 1, phase: .freeLive, issuedAt: .distantPast, expiresAt: .distantFuture,
            audienceReviewed: true)
    }
}

struct SignedReleasePolicy: Codable {
    /// Sign exact UTF-8 JSON bytes, not a JSON object re-serialized by the client.
    var payload: String
    var signature: String
    func verified(publicKey: Data, now: Date) throws -> ReleasePolicy {
        guard let bytes = Data(base64Encoded: payload), let signature = Data(base64Encoded: signature),
              try Curve25519.Signing.PublicKey(rawRepresentation: publicKey).isValidSignature(signature, for: bytes)
        else { throw MonetizationError.invalidPolicy }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let value = try decoder.decode(ReleasePolicy.self, from: bytes)
        guard value.schema == 1, value.version > 0, value.issuedAt <= now,
              value.expiresAt > now, value.expiresAt > value.issuedAt,
              value.cutover.map({ $0.approved && !$0.id.isEmpty && !($0.paidBuilds ?? []).isEmpty && $0.rolloutUncertaintyEnd >= $0.legacyEligibilityEnd }) ?? (value.phase == .preFree || value.phase == .adsOff)
        else { throw MonetizationError.invalidPolicy }
        return value
    }
}

@MainActor
@Observable
final class ReleasePolicyStore {
    private(set) var policy = ReleasePolicy()
    private let configuration: MonetizationConfiguration
    private let defaults: UserDefaults
    @ObservationIgnored private var lastClock: Date
    private(set) var clockUncertain = false
    var onChange: (() -> Void)?

    init(configuration: MonetizationConfiguration = .init(), defaults: UserDefaults = .standard) {
        self.configuration = configuration
        self.defaults = defaults
        lastClock = defaults.object(forKey: "echo.monetization.policy.clock") as? Date ?? .distantPast
        // No cached permission at launch: fetch/reverify before enabling production requests.
    }
    func current(at now: Date = Date()) -> ReleasePolicy {
        guard !clockUncertain, now >= lastClock, policy.expiresAt > now else { return ReleasePolicy() }
        return policy
    }
    func accept(_ envelope: SignedReleasePolicy, at now: Date = Date()) throws {
        guard let key = configuration.publicKey else { throw MonetizationError.invalidPolicy }
        let value = try envelope.verified(publicKey: key, now: now)
        let highest = UInt64(max(0, defaults.integer(forKey: "echo.monetization.policy.highest")))
        guard value.version >= highest, now >= lastClock else { throw MonetizationError.invalidPolicy }
        defaults.set(value.version, forKey: "echo.monetization.policy.highest")
        policy = value
        lastClock = now
        defaults.set(lastClock, forKey: "echo.monetization.policy.clock")
        onChange?()
    }
    func refresh() async {
        guard let url = configuration.policyURL, url.scheme == "https", configuration.publicKey?.count == 32 else { return }
        do {
            let session = URLSession(configuration: .ephemeral)
            defer { session.invalidateAndCancel() }
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.cachePolicy = .reloadIgnoringLocalCacheData
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200, data.count <= 32_768,
                  response.url?.scheme == "https", response.url?.host == url.host else { throw MonetizationError.invalidPolicy }
            try accept(JSONDecoder().decode(SignedReleasePolicy.self, from: data))
        } catch {
            policy = ReleasePolicy()
            onChange?()
        }
    }
}
