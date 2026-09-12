import SwiftUI

struct WikiView: View {
    @Environment(AppModel.self) private var model
    @State private var section: WikiSection = .basics

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        archiveHeader
                        sectionPicker
                        sectionContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
        }
        .foregroundStyle(EchoTheme.text)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button {
                model.audio.play(.tap)
                model.goHome()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
                    .background(EchoTheme.panel, in: Circle())
                    .overlay(Circle().stroke(EchoTheme.panelStroke, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to home")

            VStack(alignment: .leading, spacing: 2) {
                Text("TIMELINE ARCHIVE")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .tracking(1.2)
                Text("FIELD NOTES · REVISION 77")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer()

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(section.tint)
                .frame(width: 42, height: 42)
                .background(section.tint.opacity(0.13), in: Circle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    private var archiveHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(EchoTheme.cyan.opacity(0.12))
                    .frame(width: 68, height: 68)
                Circle()
                    .stroke(EchoTheme.cyan.opacity(0.32), lineWidth: 1)
                    .frame(width: 53, height: 53)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(EchoTheme.cyan)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("SURVIVOR'S FIELD MANUAL")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.1)
                Text("Everything the timeline never had time to explain.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [EchoTheme.cyan.opacity(0.14), EchoTheme.panel.opacity(0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(EchoTheme.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    private var sectionPicker: some View {
        HStack(spacing: 5) {
            ForEach(WikiSection.allCases) { item in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeOut(duration: 0.2)) {
                        section = item
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(item.title.uppercased())
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .tracking(0.35)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .foregroundStyle(section == item ? EchoTheme.navyDeep : Color.white.opacity(0.68))
                    .frame(maxWidth: .infinity)
                    .frame(height: 47)
                    .background(
                        section == item ? AnyShapeStyle(item.tint) : AnyShapeStyle(EchoTheme.panel),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(section == item ? item.tint.opacity(0.7) : EchoTheme.panelStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(section == item ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .research:
            researchContent
        case .acts:
            actsContent
        default:
            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    WikiEntryCard(entry: entry)
                }
            }
        }
    }

    private var entries: [WikiEntry] {
        switch section {
        case .basics:
            return [
                WikiEntry(
                    icon: "scope",
                    eyebrow: "PRIMARY DIRECTIVE",
                    title: "Close the loop",
                    detail: "Collect every spark, then enter the awakened exit before the cycle expires. The exit remains dormant while even one spark is missing.",
                    facts: ["Gold sparks are required", "The exit flashes when it opens"],
                    tint: EchoTheme.gold
                ),
                WikiEntry(
                    icon: "hand.draw.fill",
                    eyebrow: "CONTROL",
                    title: "Drag the present · tap the past",
                    detail: "Drag anywhere to steer. Double-tap open space to spend a Rewind charge and snap back along your recent route.",
                    facts: ["Release to coast", "Rewind also grants a brief ward"],
                    tint: EchoTheme.primaryBlueHi
                ),
                WikiEntry(
                    icon: "timer",
                    eyebrow: "ECHO CLOCK",
                    title: "Zero creates another past",
                    detail: "The number inside the beacon at your starting point counts down to the next Echo. At zero, a copy begins replaying your route; after the map's Echo limit is reached, the clock disappears.",
                    facts: ["Freeze pauses this countdown", "Shift and Pulse delay the next Echo"],
                    tint: .orange
                ),
                WikiEntry(
                    icon: "waveform.path.ecg",
                    eyebrow: "RESONANCE",
                    title: "Chain sparks for fragments",
                    detail: "Collect another spark within 3.25 seconds to raise the Resonance chain. The HUD bar shows the remaining link window, and your best chain is converted into bonus research fragments at the finish.",
                    facts: ["Every rank after ×1 adds 10 fragments", "Freeze also pauses the chain window"],
                    tint: EchoTheme.magenta
                ),
                WikiEntry(
                    icon: "person.2.wave.2.fill",
                    eyebrow: "ECHOES",
                    title: "Your previous route returns",
                    detail: "At the end of each cycle, your recorded path becomes an Echo. Touching it is dangerous unless Phase is active, so every route is also a map you draw for your future self.",
                    facts: ["Seals can permanently erase Echoes", "Keep corridors reusable"],
                    tint: EchoTheme.violet
                ),
                WikiEntry(
                    icon: "seal.fill",
                    eyebrow: "PERMANENT PROGRESS",
                    title: "Seals and fragments",
                    detail: "Finish maps and optional objectives to earn Seals. Fragments are spent on abilities and research; neither is lost when a single run fractures.",
                    facts: ["Research applies to every act", "Daily routes award bonus fragments"],
                    tint: .green
                )
            ]
        case .threats:
            return [
                WikiEntry(icon: "hexagon.fill", eyebrow: "KINETIC · MATERIAL SYSTEM", title: "Asteroids", detail: "Debris now carries a readable material shell. A brittle asteroid arms its own fracture clock on the first wall impact, gains deeper cracks over time, and can shatter early after enough rebounds.", facts: ["Freeze pauses movement and fracture clocks", "The timer belongs to the asteroid, not the HUD"], tint: .orange),
                WikiEntry(icon: "square.3.layers.3d", eyebrow: "DEBRIS INDEX", title: "Four materials", detail: "Cyan Cryo Ice breaks in 2 impacts, violet Chrono Crystal in 3, and amber Basalt in 4. Silver Void Alloy is permanent and keeps ricocheting, so color changes the route strategy.", facts: ["ICE 5.2s · CHR 7.0s · BAS 9.0s", "ALLOY has no fracture timer"], tint: EchoTheme.cyan),
                WikiEntry(icon: "laser.burst", eyebrow: "ENERGY", title: "Laser arrays", detail: "Emitter pairs telegraph, charge, fire and cool down. Sweep arrays rotate through a marked arc; pulse arrays alternate their timing.", facts: ["Thin line = telegraph", "Solid core = lethal beam"], tint: EchoTheme.danger),
                WikiEntry(icon: "hurricane", eyebrow: "TEMPORAL", title: "Reality rifts", detail: "Calm tears freeze hostile time, collapsing tears kill, Warp tears fold your position and controls, and Candy tears open a ten-second pocket timeline.", facts: ["Warp rewinds the Echo clock", "Candy raises speed and Resonance time"], tint: EchoTheme.violet),
                WikiEntry(icon: "circle.circle.fill", eyebrow: "GRAVITY", title: "Black holes", detail: "A lensing ring marks the pull radius around a lethal dark core. The force grows as you approach and can bend a route into walls or old Echoes.", facts: ["Freeze suspends gravity", "Surge helps escape the outer pull"], tint: EchoTheme.gold),
                WikiEntry(icon: "rectangle.portrait.and.arrow.forward", eyebrow: "SPATIAL", title: "Time gates", detail: "Solid bars vanish and return on a clock. Their glow fades while open; freezing time also freezes the current gate state.", facts: ["Cross during the dim phase", "Asteroids rebound while a gate is solid"], tint: EchoTheme.cyan),
                WikiEntry(icon: "circle.dotted.circle.fill", eyebrow: "ENVIRONMENT", title: "Slow fields", detail: "Blue-violet fields damp movement while you remain inside them. Their boundary is soft, but their effect is immediate.", facts: ["Surge counters the drag", "Asteroids are not slowed"], tint: EchoTheme.primaryBlueHi),
                WikiEntry(icon: "clock.badge.exclamationmark.fill", eyebrow: "VOLATILE BONUS", title: "Timed crystals", detail: "The orbiting ring is a bonus window, not the spark's lifetime. Secure the crystal before it closes to gain Freeze time and extra fragments; after zero, the spark stays collectible but loses that bonus.", facts: ["Reward: +1.5 sec Freeze and +15 fragments", "Freeze pauses the crystal countdown"], tint: EchoTheme.gold),
                WikiEntry(icon: "scribble.variable", eyebrow: "PARADOX", title: "Collision scars", detail: "A failed contact leaves a temporary scar in the timeline. Scars block careless repeats and make repeated routes progressively harder.", facts: ["They decay between cycles", "Rewind can escape a closing scar"], tint: EchoTheme.magenta)
            ]
        case .abilities:
            return abilityEntries
        case .research, .acts:
            return []
        }
    }

    private var abilityEntries: [WikiEntry] {
        [
            WikiEntry(icon: "snowflake", eyebrow: "CONTROL · 3.2 SEC · 11 SEC COOLDOWN", title: "Freeze", detail: "Locks the whole hostile simulation: asteroids and their fracture clocks, rifts, moving walls, laser phase and Echo playback all stop for the duration.", facts: ["Every active asteroid freezes", "Cryostasis extends the duration"], tint: EchoTheme.cyan),
            WikiEntry(icon: "bolt.fill", eyebrow: "MOBILITY · 4 SEC · 9 SEC COOLDOWN", title: "Surge", detail: "Temporarily raises acceleration and maximum speed without breaking your current steering line.", facts: ["Best for long clear lanes", "Momentum remains after the burst"], tint: EchoTheme.gold),
            WikiEntry(icon: "waveform.circle.fill", eyebrow: "DISRUPTION · 8 SEC COOLDOWN", title: "Pulse", detail: "Pushes the next Echo farther into the future, buying clean space when several copies are about to overlap.", facts: ["Instant activation", "Unlocked through Chrono Theory"], tint: EchoTheme.magenta),
            WikiEntry(icon: "shield.fill", eyebrow: "DEFENSE · 7 SEC COOLDOWN", title: "Shield", detail: "Absorbs one collision and shatters with a clear flash instead of fracturing the current run.", facts: ["One impact per charge", "Does not erase the obstacle"], tint: .green),
            WikiEntry(icon: "magnet.fill", eyebrow: "COLLECTION · 5 SEC · 10 SEC COOLDOWN", title: "Magnet", detail: "Pulls nearby sparks and timed crystals into your path, making risky clusters safer to collect.", facts: ["Range grows through research", "Does not pull hazards"], tint: .pink),
            WikiEntry(icon: "sparkles", eyebrow: "INTANGIBILITY · 2.4 SEC · 12 SEC COOLDOWN", title: "Phase", detail: "Lets you pass through Echoes for a short window. Solid arena borders and walls still contain you.", facts: ["The player turns translucent", "Pickups remain usable"], tint: EchoTheme.cyanBright),
            WikiEntry(icon: "clock.arrow.circlepath", eyebrow: "TIME · 13 SEC COOLDOWN", title: "Shift", detail: "Pushes the next Echo farther out, buying room for a final spark or an exit run without changing steering.", facts: ["Combines well with Surge", "Unlocked through Chrono Theory"], tint: EchoTheme.violet),
            WikiEntry(icon: "hourglass.bottomhalf.filled", eyebrow: "WORLD CONTROL · 5 SEC · 14 SEC COOLDOWN", title: "Anchor", detail: "Slows Echo playback, rocks, gravity, gates, lasers, rifts and countdowns while your own movement remains at full speed.", facts: ["Different from Freeze: danger still moves", "World Anchor improves strength and duration"], tint: EchoTheme.cyan),
            WikiEntry(icon: "burst.fill", eyebrow: "CLEARANCE · INSTANT · 12 SEC COOLDOWN", title: "Repulse", detail: "Sends a radial shockwave through the arena. Brittle asteroids shatter, alloy is hurled away, and nearby collision scars collapse.", facts: ["Creates an emergency safe circle", "Repulse Core increases its radius"], tint: EchoTheme.magenta),
            WikiEntry(icon: "triangle.fill", eyebrow: "REFRACTION · 4.5 SEC · 13 SEC COOLDOWN", title: "Prism", detail: "Wraps the player in a rotating prism that makes every firing laser harmless for the duration.", facts: ["The beam changes color while refracted", "Other collisions remain dangerous"], tint: .green),
            WikiEntry(icon: "arrow.forward.to.line.compact", eyebrow: "SPATIAL · INSTANT · 10 SEC COOLDOWN", title: "Blink", detail: "Teleports forward along the most recent movement direction and safely skips the line between both points.", facts: ["Face the destination before tapping", "Blink Drive increases jump distance"], tint: EchoTheme.violet)
        ]
    }

    private var researchContent: some View {
        VStack(spacing: 12) {
            ForEach(UpgradeBranch.allCases, id: \.self) { branch in
                let upgrades = UpgradeKind.allCases.filter { $0.branch == branch }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: branch.wikiIcon)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(branch.wikiColor)
                            .frame(width: 34, height: 34)
                            .background(branch.wikiColor.opacity(0.13), in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(branch.title)
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .tracking(1)
                            Text(branch.wikiSummary)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(EchoTheme.muted)
                        }
                    }

                    ForEach(upgrades) { upgrade in
                        HStack(alignment: .top, spacing: 11) {
                            ZStack {
                                Circle()
                                    .fill(branch.wikiColor.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: upgrade.icon)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(branch.wikiColor)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(upgrade.title)
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                    Spacer()
                                    Text("\(upgrade.maxLevel) RANK\(upgrade.maxLevel == 1 ? "" : "S")")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .tracking(0.7)
                                        .foregroundStyle(branch.wikiColor)
                                }
                                Text(upgrade.detail)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .padding(15)
                .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(branch.wikiColor.opacity(0.16), lineWidth: 1))
            }
        }
    }

    private var actsContent: some View {
        VStack(spacing: 12) {
            ForEach(Act.allCases, id: \.rawValue) { act in
                let levels = LevelCatalog.playable.filter { act.range.contains($0.number) }
                VStack(alignment: .leading, spacing: 11) {
                    HStack {
                        Text(String(format: "%02d", act.rawValue))
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(act.wikiColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(act.title)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .tracking(1)
                            Text("MAPS \(act.range.lowerBound)–\(act.range.upperBound)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(EchoTheme.muted)
                        }
                        Spacer()
                        Image(systemName: act.wikiIcon)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(act.wikiColor)
                    }

                    Text(act.blurb)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.7))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 6) {
                        ForEach(levels) { level in
                            Text("\(level.number) · \(level.name)")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
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
}

private enum WikiSection: String, CaseIterable, Identifiable {
    case basics
    case threats
    case abilities
    case research
    case acts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basics: "Basics"
        case .threats: "Threats"
        case .abilities: "Skills"
        case .research: "Research"
        case .acts: "Acts"
        }
    }

    var icon: String {
        switch self {
        case .basics: "sparkles"
        case .threats: "exclamationmark.triangle.fill"
        case .abilities: "bolt.circle.fill"
        case .research: "point.3.filled.connected.trianglepath.dotted"
        case .acts: "map.fill"
        }
    }

    var tint: Color {
        switch self {
        case .basics: EchoTheme.cyan
        case .threats: .orange
        case .abilities: EchoTheme.magenta
        case .research: EchoTheme.violet
        case .acts: .green
        }
    }
}

private struct WikiEntry: Identifiable {
    let id = UUID()
    let icon: String
    let eyebrow: String
    let title: String
    let detail: String
    let facts: [String]
    let tint: Color
}

private struct WikiEntryCard: View {
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
                    ForEach(entry.facts, id: \.self) { fact in
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

private extension UpgradeBranch {
    var wikiColor: Color {
        Color(red: tint.r, green: tint.g, blue: tint.b)
    }

    var wikiIcon: String {
        switch self {
        case .motion: "speedometer"
        case .loadout: "square.grid.2x2.fill"
        case .temporal: "clock.arrow.2.circlepath"
        }
    }

    var wikiSummary: String {
        switch self {
        case .motion: "Speed, steering and route recovery."
        case .loadout: "Slots, reserves and new skill types."
        case .temporal: "Cooldowns, lasers and time control."
        }
    }
}

private extension Act {
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
