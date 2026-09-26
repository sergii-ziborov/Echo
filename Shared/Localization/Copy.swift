import Foundation

/// Player-facing text. Every sentence the game shows lives in
/// Localizable.xcstrings under a stable key, in English and Russian. Save
/// data, level IDs, enum raw values and the watch wire protocol never pass
/// through here, so a change of language cannot change a run.
enum Copy {
    /// The text for `key` in the app's language.
    static func text(_ key: String, bundle: Bundle = .main) -> String {
        let value = bundle.localizedString(forKey: key, value: missing, table: nil)
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
        Locale(identifier: bundle.preferredLocalizations.first ?? "en")
    }

    /// Whether the catalog has `key`, for optional lines such as a place
    /// name that only some maps carry.
    static func has(_ key: String, bundle: Bundle = .main) -> Bool {
        bundle.localizedString(forKey: key, value: missing, table: nil) != missing
    }

    /// Seconds for display, in the reader's decimal style: "3.5" or "3,5".
    static func seconds(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }

    /// A tuned value with up to two decimals: "0.18", "2.37", "184".
    static func number(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    /// A fraction as whole percent, without the sign: 0.28 → "28".
    static func percent(_ fraction: Double) -> String {
        (fraction * 100).formatted(.number.precision(.fractionLength(0)))
    }

    private static let missing = "\u{1}missing"
}
