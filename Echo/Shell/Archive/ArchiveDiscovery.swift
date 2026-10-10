import Foundation

/// A recovered article, place or Keeper record. IDs are independent of language
/// and difficulty passes; the collection follows lifetime progress.
struct ArchiveDiscovery: Identifiable {
    enum Requirement {
        case encounter(String), regionVisited(Act), regionCleared(Act)
        case deepTime, daily, chronometer, campaign

        @MainActor
        func met(in progress: ProgressStore) -> Bool {
            switch self {
            case .encounter(let key): progress.seenHints.contains(key)
            case .regionVisited(let act):
                progress.completedDifficultyCycles > 0 || act.range.contains { number in
                    LevelCatalog.level(number: number).map { progress.progress(for: $0.id, cycle: 0).stars > 0 } ?? false
                }
            case .regionCleared(let act): progress.hasCleared(act)
            case .deepTime: progress.endless.runs > 0
            case .daily: progress.lastDailyKey != nil
            case .chronometer: !progress.wrist.cleared.isEmpty
            case .campaign: progress.hasFinishedCampaign
            }
        }

        var instruction: String {
            switch self {
            case .encounter(let key):
                Copy.text(key == "archive.rewind" ? "archive.find.require.rewind" : "archive.find.require.encounter")
            case .regionVisited(let act): Copy.format("archive.find.require.visit", act.region)
            case .regionCleared(let act): Copy.format("wiki.records.lockedRegion", act.region)
            case .deepTime: Copy.text("archive.find.require.deep")
            case .daily: Copy.text("archive.find.require.daily")
            case .chronometer: Copy.text("archive.find.require.watch")
            case .campaign: Copy.text("wiki.records.lockedCampaign")
            }
        }

        var recoveryReason: String {
            switch self {
            case .encounter: Copy.text("archive.find.reason.encounter")
            case .regionVisited(let act): Copy.format("archive.find.reason.visit", act.region)
            case .regionCleared(let act): Copy.format("archive.find.reason.clear", act.region)
            case .deepTime: Copy.text("archive.find.reason.deep")
            case .daily: Copy.text("archive.find.reason.daily")
            case .chronometer: Copy.text("archive.find.reason.watch")
            case .campaign: Copy.text("archive.find.reason.campaign")
            }
        }
    }

    let id: String
    let titleKey: String
    let section: WikiSection
    let icon: String
    let requirement: Requirement
    var title: String { Copy.text(titleKey) }

    @MainActor
    static var catalog: [ArchiveDiscovery] {
        let notes: [(String, WikiSection, String, Requirement)] = [
            ("wiki.guide.resonance", .basics, "waveform.path.ecg", .encounter("resonance")),
            ("wiki.guide.deepTime", .basics, "infinity", .deepTime),
            ("wiki.hazard.debris", .threats, "hexagon.fill", .encounter("asteroid")),
            ("wiki.hazard.materials", .threats, "square.3.layers.3d", .encounter("asteroid")),
            ("wiki.hazard.beams", .threats, "laser.burst", .encounter("laser")),
            ("wiki.hazard.rifts", .threats, "hurricane", .encounter("rift")),
            ("wiki.hazard.wells", .threats, "circle.circle.fill", .encounter("blackHole")),
            ("wiki.hazard.gates", .threats, "rectangle.portrait.and.arrow.forward", .encounter("gate")),
            ("wiki.hazard.mire", .threats, "circle.dotted.circle.fill", .encounter("realityShift")),
            ("wiki.hazard.crystals", .threats, "clock.badge.exclamationmark.fill", .encounter("timeCrystal")),
            ("wiki.hazard.scars", .threats, "scribble.variable", .encounter("collision")),
            ("wiki.hazard.ghost", .threats, "figure.walk.motion", .encounter("archive.rewind")),
            ("wiki.story.break", .story, "bolt.horizontal.circle.fill", .regionCleared(.trace)),
            ("wiki.story.philosophy", .story, "sparkle", .regionCleared(.trace)),
            ("wiki.story.rewind", .story, "clock.arrow.circlepath", .encounter("archive.rewind")),
            ("wiki.story.deep", .story, "water.waves", .deepTime),
            ("wiki.story.daily", .story, "calendar", .daily),
            ("wiki.story.chronometer", .story, "applewatch", .chronometer),
            ("wiki.story.science", .story, "atom", .regionCleared(.trace)),
        ]
        var items = notes.map { ArchiveDiscovery(id: $0.0, titleKey: "\($0.0).title", section: $0.1, icon: $0.2, requirement: $0.3) }
        items += Act.allCases.map {
            ArchiveDiscovery(id: "region.\($0.key)", titleKey: "region.\($0.key).name", section: .acts, icon: $0.wikiIcon, requirement: .regionVisited($0))
        }
        items += StoryRecord.allCases.filter { $0 != .lighthouse }.map {
            ArchiveDiscovery(id: "story.\($0.rawValue)", titleKey: "story.\($0.rawValue).title", section: .story, icon: "waveform", requirement: $0.region.map(Requirement.regionCleared) ?? .campaign)
        }
        return items
    }

    @MainActor
    static func item(_ id: String) -> ArchiveDiscovery? { catalog.first { $0.id == id } }

    @MainActor
    static func availableIDs(in progress: ProgressStore) -> Set<String> {
        Set(catalog.filter { $0.requirement.met(in: progress) }.map(\.id))
    }
}

extension ProgressStore {
    /// Upgrading an existing save never creates a wall of historical popups.
    /// Its recovered pages remain readable; only later discoveries are announced.
    func seedArchiveCollectionIfNeeded() {
        guard defaults.object(forKey: archiveAnnouncementsKey) == nil else { return }
        announcedArchiveIDs = ArchiveDiscovery.availableIDs(in: self)
        defaults.set(Array(announcedArchiveIDs), forKey: archiveAnnouncementsKey)
    }

    var pendingArchiveDiscoveries: [ArchiveDiscovery] {
        ArchiveDiscovery.catalog.filter { !announcedArchiveIDs.contains($0.id) && $0.requirement.met(in: self) }
    }

    func acknowledgeArchiveDiscoveries(_ items: [ArchiveDiscovery]) {
        announcedArchiveIDs.formUnion(items.filter { $0.requirement.met(in: self) }.map(\.id))
        persist()
    }
}
