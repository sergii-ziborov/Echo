import SwiftUI

enum WikiSection: String, CaseIterable, Identifiable {
    case basics
    case story
    case threats
    case abilities
    case research
    case acts

    var id: String { rawValue }

    /// The page a screenshot run opens on (`-shot-wiki-story` and so on).
    static var launch: WikiSection {
        let args = ProcessInfo.processInfo.arguments
        return allCases.first { args.contains("-shot-wiki-\($0.rawValue)") } ?? .basics
    }

    var title: String { Copy.text("archive.section.\(rawValue)") }

    var icon: String {
        switch self {
        case .basics: "sparkles"
        case .story: "book.closed.fill"
        case .threats: "exclamationmark.triangle.fill"
        case .abilities: "bolt.circle.fill"
        case .research: "point.3.filled.connected.trianglepath.dotted"
        case .acts: "map.fill"
        }
    }

    var tint: Color {
        switch self {
        case .basics: EchoTheme.cyan
        case .story: EchoTheme.gold
        case .threats: .orange
        case .abilities: EchoTheme.magenta
        case .research: EchoTheme.violet
        case .acts: .green
        }
    }
}

/// One article. `id` is its stable catalog key, never the translated text.
struct WikiEntry: Identifiable {
    let id: String
    let icon: String
    let eyebrow: String
    let title: String
    let detail: String
    let facts: [String]
    let tint: Color
}

extension WikiEntry {
    /// An article whose words live under `key` in the catalog: eyebrow,
    /// title, body and `facts` numbered lines.
    init(_ key: String, icon: String, tint: Color, facts: Int = 2, body: String? = nil, factLines: [String]? = nil) {
        self.init(
            id: key,
            icon: icon,
            eyebrow: Copy.text("\(key).eyebrow"),
            title: Copy.text("\(key).title"),
            detail: body ?? Copy.text("\(key).body"),
            facts: factLines ?? (0..<facts).map { Copy.text("\(key).fact\($0 + 1)") },
            tint: tint
        )
    }
}

struct WikiEntryCard: View {
    let entry: WikiEntry

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: entry.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(entry.tint)
                .frame(width: 42, height: 42)
                .background(entry.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(entry.eyebrow)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(entry.tint)
                Text(entry.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(entry.detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(entry.facts.enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle()
                                .fill(entry.tint)
                                .frame(width: 4, height: 4)
                            Text(fact)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(EchoTheme.muted)
                        }
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(entry.tint.opacity(0.15), lineWidth: 1))
    }
}

extension UpgradeBranch {
    var wikiColor: Color {
        Color(red: tint.r, green: tint.g, blue: tint.b)
    }
}

extension Act {
    var wikiColor: Color {
        switch self {
        case .trace: EchoTheme.cyan
        case .drift: EchoTheme.primaryBlueHi
        case .fracture: EchoTheme.violet
        case .debris: .orange
        case .paradox: EchoTheme.magenta
        case .singularity: EchoTheme.danger
        case .rift: Color(red: 0.40, green: 0.62, blue: 1.0)
        case .gravity: EchoTheme.gold
        case .mirage: Color(red: 0.44, green: 0.96, blue: 0.86)
        case .confection: Color(red: 1.0, green: 0.40, blue: 0.76)
        case .eternity: .white
        }
    }

    var wikiIcon: String {
        switch self {
        case .trace: "point.topleft.down.to.point.bottomright.curvepath.fill"
        case .drift: "wind"
        case .fracture: "hurricane"
        case .debris: "hexagon.fill"
        case .paradox: "person.2.wave.2.fill"
        case .singularity: "laser.burst"
        case .rift: "hurricane"
        case .gravity: "circle.circle.fill"
        case .mirage: "arrow.left.and.right"
        case .confection: "birthday.cake.fill"
        case .eternity: "infinity.circle.fill"
        }
    }
}
