import Foundation

/// What each campaign map is called, where it lies on the Fold Road and
/// what the Signal finds there. The words live in the string catalog under
/// `level.<number>.*`; the stable map IDs (`awakening-N`) never change with
/// the text, so a rename or a new language cannot touch saved progress.
enum LevelLore {
    struct Entry: Equatable, Sendable {
        let title: String
        /// A second line when the place differs from the map's name.
        let place: String?
        let log: String
    }

    static let count = 77

    static func entry(for number: Int) -> Entry? {
        guard (1...count).contains(number) else { return nil }
        let place = "level.\(number).place"
        return Entry(
            title: Copy.text("level.\(number).title"),
            place: Copy.has(place) ? Copy.text(place) : nil,
            log: Copy.text("level.\(number).log")
        )
    }
}

extension LevelDefinition {
    /// The map's name in the player's language. Save data keeps using `id`;
    /// the English `name` stays as the search alias and in bug reports.
    var title: String {
        if id.hasPrefix("wrist-") { return Copy.text("wrist.\(number).name") }
        if number >= 1000 { return Copy.format("endless.depth", number - 1000) }
        return LevelLore.entry(for: number)?.title ?? name
    }

    /// A one-line hint about how the map plays.
    var tip: String {
        if id.hasPrefix("wrist-") { return Copy.text("wrist.\(number).tip") }
        if number >= 1000 { return Copy.text("endless.tip") }
        return (1...LevelLore.count).contains(number) ? Copy.text("level.\(number).tip") : subtitle
    }
}
