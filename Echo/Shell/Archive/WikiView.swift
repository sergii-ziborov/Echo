import SwiftUI

struct WikiView: View {
    @Environment(AppModel.self) private var model
    @State var section: WikiSection

    init(section: WikiSection = ProcessInfo.processInfo.arguments.contains("-shot-wiki-research") ? .research : .basics) {
        _section = State(initialValue: section)
    }

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
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") {
                model.audio.play(.tap)
                model.goHome()
            }
            .accessibilityLabel("Back to home")

            VStack(alignment: .leading, spacing: 2) {
                Text("TIMELINE ARCHIVE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.2)
                Text("FIELD NOTES · REVISION 77")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer()

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(section.tint)
                .frame(width: 38, height: 38)
                .background(section.tint.opacity(0.13), in: Circle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
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
                    title: "Drag to steer · double-tap to dash",
                    detail: "Drag anywhere to steer the white orb. Double-tap the arena to dash. If you crash, the Rewind button on the fracture screen can return you along your recent route when a charge is available.",
                    facts: ["Release to coast", "Rewind is offered after a crash"],
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
                ),
                WikiEntry(
                    icon: "infinity",
                    eyebrow: "ENDLESS MODE",
                    title: "Deep Time",
                    detail: "A run of random arenas that never repeat, separate from the campaign. Each clear goes one depth deeper and pays fragments; rocks, beams, echoes and new materials ramp up as you descend. Paradox Rewind still works, but a crash you cannot rewind ends the run.",
                    facts: ["Every map is checked to be solvable", "Leave after a clear and resume from Home"],
                    tint: EchoTheme.magenta
                )
            ]
        case .threats:
            return [
                WikiEntry(icon: "hexagon.fill", eyebrow: "KINETIC · MATERIAL SYSTEM", title: "Asteroids", detail: "Every rock is drawn fresh from one of eight materials. All of them except alloy fracture after wall impacts; alloy never breaks. Some maps have a large fixed core with smaller satellites; others use ricochets, patrols or paired orbits. Moving rocks leave a faint trail. Watch for spreading cracks and loose chips: the rock is about to break.", facts: ["Freeze pauses movement and fracture", "A fixed core resists Repulse while its satellites circle", "Damage is shown on the rock, without a countdown"], tint: .orange),
                WikiEntry(icon: "square.3.layers.3d", eyebrow: "DEBRIS INDEX", title: "Eight materials", detail: "Cyan Cryo Ice breaks in 2 impacts, violet Chrono Crystal in 3, and amber Basalt in 4. Silver Void Alloy is permanent and keeps ricocheting, so color changes the route strategy. From DEBRIS on, glowing Magma Cores break in 3 and scatter embers, and pitted Meteoric Iron takes 6 hits. From RIFT on, sandy Hollow Geodes split in 2 to show crystal inside, and Comet Frost trails vapour and bursts after its first hit.", facts: ["COM 4.0s · ICE 5.2s · MAG 6.0s · GEO 6.5s", "CHR 7.0s · BAS 9.0s · IRON 12s", "ALLOY never fractures"], tint: EchoTheme.cyan),
                WikiEntry(icon: "laser.burst", eyebrow: "ENERGY", title: "Laser arrays", detail: "Emitter pairs telegraph, charge, fire and cool down. Sweep arrays rotate through a marked arc; pulse arrays alternate their timing.", facts: ["Thin line = telegraph", "Solid core = lethal beam"], tint: EchoTheme.danger),
                WikiEntry(icon: "hurricane", eyebrow: "TEMPORAL", title: "Reality rifts", detail: "Calm tears freeze hostile time, collapsing tears kill, Warp tears fold your position and controls, and Candy tears open a ten-second pocket timeline.", facts: ["Warp rewinds the Echo clock", "Candy raises speed and Resonance time"], tint: EchoTheme.violet),
                WikiEntry(icon: "circle.circle.fill", eyebrow: "GRAVITY", title: "Black holes", detail: "A lensing ring marks the pull radius around a lethal dark core. The force grows as you approach and can bend a route into walls or old Echoes.", facts: ["Freeze suspends gravity", "Surge helps escape the outer pull"], tint: EchoTheme.gold),
                WikiEntry(icon: "rectangle.portrait.and.arrow.forward", eyebrow: "SPATIAL", title: "Time gates", detail: "Solid bars vanish and return on a clock. Red actuator plates mean closed; cyan open frames mark a safe crossing. Freezing time also freezes the current gate state.", facts: ["Cross while the red bar is absent", "Asteroids rebound while a gate is solid"], tint: EchoTheme.cyan),
                WikiEntry(icon: "circle.dotted.circle.fill", eyebrow: "ENVIRONMENT", title: "Slow fields", detail: "A translucent blue membrane and soft boundary mark the zone that dampens your movement while you remain inside it.", facts: ["Surge counters the drag", "Asteroids are not slowed"], tint: EchoTheme.primaryBlueHi),
                WikiEntry(icon: "clock.badge.exclamationmark.fill", eyebrow: "VOLATILE BONUS", title: "Timed crystals", detail: "Gold sparks marked BONUS give Freeze time if you reach them before the countdown ends. After zero they stay collectible, but the extra reward is gone.", facts: ["Reward: +1.5 sec Freeze and +15 fragments", "Freeze pauses the crystal countdown"], tint: EchoTheme.gold),
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
            WikiEntry(icon: "hare.fill", eyebrow: "MOBILITY · 4 SEC · 9 SEC COOLDOWN", title: "Surge", detail: "Temporarily raises acceleration and maximum speed without breaking your current steering line.", facts: ["Best for long clear lanes", "Momentum remains after the burst"], tint: EchoTheme.gold),
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
            HStack(spacing: 10) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundStyle(EchoTheme.violet)
                VStack(alignment: .leading, spacing: 3) {
                    Text("24 TECHNOLOGIES · 3 BRANCHES")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("All listed prerequisites are required. Spend points in the Temporal Lab.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer(minLength: 0)
                Button {
                    model.openShop()
                } label: {
                    Text("LAB")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(EchoTheme.violet, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(13)
            .background(EchoTheme.violet.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            ForEach(UpgradeBranch.allCases, id: \.self) { branch in
                let upgrades = UpgradeKind.allCases.filter { $0.branch == branch }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ResearchIconView(kind: upgrades[0], size: 29)
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
                                ResearchIconView(kind: upgrade, size: 29)
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
                                if !upgrade.prerequisites.isEmpty {
                                    Text("REQUIRES ALL · " + upgrade.prerequisites.map { "\($0.kind.title) \($0.level)" }.joined(separator: " + "))
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(branch.wikiColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
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
