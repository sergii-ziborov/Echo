import XCTest
@testable import Echo

/// The catalog ships English and Russian: every line exists in both with the
/// same parameters, Russian counts take all four plural forms, and every
/// rule the game names has its words.
@MainActor
final class LocalizationTests: XCTestCase {
    private static let languages = ["en", "ru"]

    private func bundle(_ language: String) throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: language, ofType: "lproj"), "No \(language).lproj in the app")
        return try XCTUnwrap(Bundle(path: path))
    }

    /// The compiled table: plain lines, or plural entries by key.
    private func table(_ language: String, _ ext: String) throws -> [String: Any] {
        let url = try XCTUnwrap(try bundle(language).url(forResource: "Localizable", withExtension: ext))
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: Any])
    }

    private func specifiers(_ text: String) -> [String] {
        text.matches(of: /%(?:\d+\$)?(?:lld|ld|d|@|\.?\d*f)/).map { String($0.output) }.sorted()
    }

    func testBothLanguagesResolve() throws {
        XCTAssertEqual(Copy.text("home.tagline", bundle: try bundle("en")), "THE ROAD REMEMBERS. KEEP MOVING.")
        XCTAssertEqual(Copy.text("home.tagline", bundle: try bundle("ru")), "ДОРОГА ПОМНИТ. ДВИГАЙСЯ ДАЛЬШЕ.")
    }

    func testRussianPlurals() throws {
        let ru = try bundle("ru")
        func charges(_ count: Int) -> String {
            Copy.format("lab.charges", count, bundle: ru, locale: Locale(identifier: "ru"))
        }
        XCTAssertEqual(charges(1), "1 заряд")
        XCTAssertEqual(charges(3), "3 заряда")
        XCTAssertEqual(charges(5), "5 зарядов")
        XCTAssertEqual(charges(21), "21 заряд")
        XCTAssertEqual(charges(11), "11 зарядов")
        XCTAssertEqual(Copy.format("lab.charges", 1, bundle: try bundle("en"), locale: Locale(identifier: "en")), "1 charge")
        XCTAssertEqual(Copy.format("lab.charges", 2, bundle: try bundle("en"), locale: Locale(identifier: "en")), "2 charges")
    }

    func testEveryLineExistsInBothLanguagesWithTheSameParameters() throws {
        let en = try table("en", "strings"), ru = try table("ru", "strings")
        XCTAssertGreaterThan(en.count, 1000)
        XCTAssertEqual(Set(en.keys).symmetricDifference(ru.keys), [])
        for (key, english) in en {
            let english = try XCTUnwrap(english as? String), russian = try XCTUnwrap(ru[key] as? String, key)
            XCTAssertFalse(russian.isEmpty, key)
            XCTAssertEqual(specifiers(english), specifiers(russian), key)
        }

        let enPlurals = try table("en", "stringsdict"), ruPlurals = try table("ru", "stringsdict")
        XCTAssertEqual(Set(enPlurals.keys).symmetricDifference(ruPlurals.keys), [])
        for (key, entry) in enPlurals {
            func forms(_ entry: Any?) throws -> [String: String] {
                let rules = try XCTUnwrap(entry as? [String: Any], key)
                let variable = try XCTUnwrap(rules.first { $0.value is [String: Any] }?.value as? [String: Any], key)
                return variable.compactMapValues { $0 as? String }.filter { !$0.key.hasPrefix("NSString") }
            }
            let english = try forms(entry), russian = try forms(ruPlurals[key])
            XCTAssertEqual(Set(english.keys), ["one", "other"], key)
            XCTAssertEqual(Set(russian.keys), ["one", "few", "many", "other"], key)
            let shape = specifiers(try XCTUnwrap(english["other"]))
            for text in Array(english.values) + Array(russian.values) {
                XCTAssertEqual(specifiers(text), shape, key)
            }
        }
    }

    func testEveryRuleHasItsWords() throws {
        for language in Self.languages {
            let copy = try bundle(language)
            func expect(_ key: String) {
                XCTAssertTrue(Copy.has(key, bundle: copy), "\(language) has no \(key)")
            }
            for number in 1...LevelLore.count {
                ["title", "log", "tip"].forEach { expect("level.\(number).\($0)") }
            }
            for act in Act.allCases {
                ["name", "arrival", "meaning", "science", "act", "blurb", "trait1", "trait2", "trait3"]
                    .forEach { expect("region.\(act.key).\($0)") }
            }
            for kind in BonusKind.allCases {
                ["name", "field", "rule", "command", "best"].forEach { expect("ability.\(kind.rawValue).\($0)") }
            }
            for kind in UpgradeKind.allCases {
                ["name", "effect", "best"].forEach { expect("upgrade.\(kind.rawValue).\($0)") }
                ["before", "after"].forEach { expect("tech.\(kind.rawValue).\($0)") }
            }
            for branch in UpgradeBranch.allCases {
                ["title", "summary"].forEach { expect("branch.\(branch.rawValue).\($0)") }
            }
            for material in AsteroidMaterial.allCases {
                ["name", "code", "about"].forEach { expect("material.\(material.rawValue).\($0)") }
            }
            for scenario in MechanicDemoScenario.allCases {
                expect("demo.\(scenario.rawValue)")
            }
            for number in 1...WristCatalog.maps.count {
                ["name", "tip", "log"].forEach { expect("wrist.\(number).\($0)") }
            }
            for relic in WristRelic.allCases {
                ["name", "detail"].forEach { expect("relic.\(relic.rawValue).\($0)") }
            }
            for skill in WristSkill.allCases {
                ["name", "detail"].forEach { expect("wristSkill.\(skill.rawValue).\($0)") }
            }
            for record in StoryRecord.allCases {
                ["title", "text", "author"].forEach { expect("story.\(record.rawValue).\($0)") }
            }
            for hint in ["echo", "asteroid", "rift", "collision", "gate", "laser", "timeCrystal", "resonance", "blackHole", "realityShift"] {
                ["title", "detail", "action"].forEach { expect("hint.\(hint).\($0)") }
            }
        }
    }

    /// The Lab words its numbers from the tuning the run applies.
    func testResearchEffectsQuoteTheRunTuning() {
        XCTAssertEqual(UpgradeKind.velocity.effect(atRank: 0), "Base movement speed")
        XCTAssertEqual(UpgradeKind.velocity.effect(atRank: 7), "+28% movement speed")
        XCTAssertEqual(UpgradeKind.sparkSense.effect(atRank: 2), "+7 pickup radius")
        XCTAssertEqual(UpgradeKind.dashCapacitor.effect(atRank: 0), "Dash cooldown 2.6 s")
        XCTAssertEqual(UpgradeKind.slots.effect(atRank: 4), "6 active skill slots")
        XCTAssertEqual(UpgradeKind.shieldLattice.effect(atRank: 5), "+0.6 s grace · double layer")
        XCTAssertEqual(UpgradeKind.crystalMemory.effect(atRank: 0), "Crystal Freeze +1.5 s")
        XCTAssertEqual(UpgradeKind.rewind.effect(atRank: 5), "Rewind 5.25 s · 3 charges")
        XCTAssertEqual(UpgradeKind.anchorResearch.effect(atRank: 0), "Anchor locked")
        XCTAssertEqual(UpgradeKind.chronoResearch.effect(atRank: 1), "Shift +3.6 s · Pulse +2.4 s")
        for kind in UpgradeKind.allCases {
            for rank in 0...kind.maxLevel {
                let text = kind.effect(atRank: rank)
                XCTAssertNil(text.range(of: #"%(\d+\$)?(lld|@)"#, options: .regularExpression), "\(kind) \(rank): \(text)")
                XCTAssertFalse(text.hasPrefix("lab."), "\(kind) \(rank): \(text)")
            }
        }
    }
}
