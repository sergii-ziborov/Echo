import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case automatic, english = "en", russian = "ru"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: Copy.text("settings.language.auto")
        case .english: "English"
        case .russian: "Русский"
        }
    }

    func resolvedCode(in bundle: Bundle = .main) -> String {
        self == .automatic ? (bundle.preferredLocalizations.first ?? "en") : rawValue
    }
}

/// Copy can also be read while preparing a level off the main thread. The
/// stored choice is locked, while Observation lets visible text update in place.
@Observable
final class LanguagePreference: @unchecked Sendable {
    static let shared = LanguagePreference()
    static let key = "echo.settings.language.v1"
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let lock = NSLock()
    @ObservationIgnored private var stored: AppLanguage

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stored = defaults.string(forKey: Self.key).flatMap(AppLanguage.init(rawValue:)) ?? .automatic
    }

    var selection: AppLanguage {
        get {
            access(keyPath: \.selection)
            return lock.withLock { stored }
        }
        set {
            withMutation(keyPath: \.selection) {
                lock.withLock {
                    stored = newValue
                    defaults.set(newValue.rawValue, forKey: Self.key)
                }
            }
        }
    }

    func localizedBundle(_ bundle: Bundle) -> Bundle {
        // Explicit language bundles (for previews and tests) remain explicit.
        let choice = selection
        guard bundle.bundleURL == Bundle.main.bundleURL,
              choice != .automatic,
              let path = bundle.path(forResource: choice.rawValue, ofType: "lproj"),
              let localized = Bundle(path: path) else { return bundle }
        return localized
    }
}

/// Player-facing text. Every sentence the game shows lives in
/// Localizable.xcstrings under a stable key, in English and Russian. Save
/// data, level IDs, enum raw values and the watch wire protocol never pass
/// through here, so a change of language cannot change a run.
enum Copy {
    /// The text for `key` in the app's language.
    static func text(_ key: String, bundle: Bundle = .main) -> String {
        let value = LanguagePreference.shared.localizedBundle(bundle).localizedString(forKey: key, value: missing, table: nil)
        guard value != missing else {
#if DEBUG
            assertionFailure("No copy for \(key)")
#endif
            return key
        }
        return value
    }

    /// A text with parameters. Counts pick their plural form from the catalog
    /// by the rules of the language the text is shown in, not the region.
    static func format(_ key: String, _ arguments: CVarArg..., bundle: Bundle = .main, locale: Locale? = nil) -> String {
        String(format: text(key, bundle: bundle), locale: locale ?? language(of: bundle), arguments: arguments)
    }

    /// The language `bundle` shows its text in.
    static func language(of bundle: Bundle = .main) -> Locale {
        Locale(identifier: bundle.bundleURL == Bundle.main.bundleURL
               ? LanguagePreference.shared.selection.resolvedCode(in: bundle)
               : bundle.preferredLocalizations.first ?? "en")
    }

    /// Whether the catalog has `key`, for optional lines such as a place
    /// name that only some maps carry.
    static func has(_ key: String, bundle: Bundle = .main) -> Bool {
        LanguagePreference.shared.localizedBundle(bundle).localizedString(forKey: key, value: missing, table: nil) != missing
    }

    /// Seconds for display, in the reader's decimal style: "3.5" or "3,5".
    static func seconds(_ value: Double) -> String {
        value.formatted(.number.locale(language()).precision(.fractionLength(0...1)))
    }

    /// A tuned value with up to two decimals: "0.18", "2.37", "184".
    static func number(_ value: Double) -> String {
        value.formatted(.number.locale(language()).precision(.fractionLength(0...2)))
    }

    /// A fraction as whole percent, without the sign: 0.28 → "28".
    static func percent(_ fraction: Double) -> String {
        (fraction * 100).formatted(.number.locale(language()).precision(.fractionLength(0)))
    }

    private static let missing = "\u{1}missing"
}
