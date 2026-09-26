import SwiftUI

/// The Story page: why the Signal is out here, what is real science and
/// what is ours, and the records the Road gives back as regions are cleared.
/// Rules are never locked behind the story; only records wait for progress,
/// and the ending stays sealed until the campaign is finished.
struct WikiStoryContent: View {
    @Environment(AppModel.self) private var model

    private static let entries: [(key: String, icon: String, tint: Color)] = [
        ("wiki.story.break", "bolt.horizontal.circle.fill", EchoTheme.magenta),
        ("wiki.story.signal", "circle.circle.fill", EchoTheme.cyan),
        ("wiki.story.lighthouse", "light.beacon.max.fill", EchoTheme.gold),
        ("wiki.story.road", "point.3.connected.trianglepath.dotted", EchoTheme.cyan),
        ("wiki.story.rewind", "clock.arrow.circlepath", EchoTheme.violet),
        ("wiki.story.deep", "water.waves", EchoTheme.magenta),
        ("wiki.story.daily", "calendar", .orange),
        ("wiki.story.chronometer", "applewatch", .green),
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Self.entries, id: \.key) { entry in
                WikiEntryCard(entry: WikiEntry(entry.key, icon: entry.icon, tint: entry.tint))
            }
            WikiScienceCard()
            records
        }
    }

    private var records: some View {
        let unlocked = StoryRecord.allCases.filter { $0.isRecovered(in: model.progress) }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Copy.text("wiki.records.title"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.2)
                Spacer()
                Text(Copy.format("wiki.records.count", unlocked, StoryRecord.allCases.count))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
            ForEach(StoryRecord.allCases) { record in
                StoryRecordRow(record: record, recovered: record.isRecovered(in: model.progress))
            }
        }
        .padding(15)
        .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(EchoTheme.gold.opacity(0.18), lineWidth: 1))
    }
}

/// A record the Road gives back, and what recovers it.
enum StoryRecord: String, CaseIterable, Identifiable {
    case lighthouse, gardens, cinder, `break`, ashcrown, glass, mika, final, next

    var id: String { rawValue }

    /// The region whose last map recovers the record; nil for the start and
    /// for the ending, which needs the whole campaign.
    var region: Act? {
        switch self {
        case .lighthouse, .final, .next: nil
        case .gardens: .drift
        case .cinder: .debris
        case .break: .paradox
        case .ashcrown: .singularity
        case .glass: .mirage
        case .mika: .confection
        }
    }

    var isEnding: Bool { self == .final || self == .next }

    @MainActor
    func isRecovered(in progress: ProgressStore) -> Bool {
        if isEnding { return progress.hasFinishedCampaign }
        guard let region else { return true }
        return progress.hasCleared(region)
    }
}

private struct StoryRecordRow: View {
    let record: StoryRecord
    let recovered: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: recovered ? "waveform" : "lock.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(recovered ? EchoTheme.gold : EchoTheme.muted)
                .frame(width: 30, height: 30)
                .background((recovered ? EchoTheme.gold : Color.white).opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                if recovered {
                    Text(Copy.text("story.\(record.rawValue).title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(Copy.text("story.\(record.rawValue).author").uppercased())
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(EchoTheme.gold)
                    Text(Copy.text("story.\(record.rawValue).text"))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // The ending's title stays sealed so the Archive never spoils it.
                    Text(record.isEnding ? Copy.text("wiki.records.sealed") : Copy.text("story.\(record.rawValue).title"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                    Text(record.region.map { Copy.format("wiki.records.lockedRegion", $0.region) } ?? Copy.text("wiki.records.lockedCampaign"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Real science next to the Keepers' fiction, each note labelled.
private struct WikiScienceCard: View {
    private static let notes: [(key: String, label: String)] = [
        ("science.loschmidt", "archive.science.established"),
        ("science.timecrystal", "archive.science.established"),
        ("science.lensing", "archive.science.established"),
        ("science.correction", "archive.science.theory"),
        ("science.keepers", "archive.science.fiction"),
        ("science.mire", "archive.science.metaphor"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WikiEntryCard(entry: WikiEntry("wiki.story.science", icon: "atom", tint: EchoTheme.primaryBlueHi, facts: 0))
            ForEach(Self.notes, id: \.key) { note in
                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.text(note.label))
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.9)
                        .foregroundStyle(EchoTheme.primaryBlueHi)
                    Text(Copy.text(note.key))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.74))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 15)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.bottom, 12)
        .background(EchoTheme.panel.opacity(0.6), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Every region: where it is, what its name means, and where the fiction
/// parts with science.
struct WikiRegionsContent: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(Act.allCases, id: \.rawValue) { act in
                let levels = LevelCatalog.playable.filter { act.range.contains($0.number) }
                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        Text(String(format: "%02d", act.rawValue))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(act.wikiColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(act.region.uppercased())
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(1)
                            Text(Copy.format("wiki.region.maps", act.title, act.range.lowerBound, act.range.upperBound))
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(EchoTheme.muted)
                        }
                        Spacer()
                        Image(systemName: act.wikiIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(act.wikiColor)
                    }

                    paragraph(nil, act.intro, tint: act.wikiColor)
                    paragraph(Copy.text("wiki.region.meaning"), act.meaning, tint: act.wikiColor)
                    paragraph(Copy.text("wiki.region.science"), act.scienceNote, tint: act.wikiColor)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                        ForEach(levels) { level in
                            Text("\(level.number) · \(level.title)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 9)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 27)
                                .background(act.wikiColor.opacity(0.09), in: Capsule())
                        }
                    }
                }
                .padding(15)
                .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(act.wikiColor.opacity(0.17), lineWidth: 1))
            }
        }
    }

    private func paragraph(_ heading: String?, _ text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if let heading {
                Text(heading)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.9)
                    .foregroundStyle(tint)
            }
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
