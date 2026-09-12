import SwiftUI
import UIKit

struct ShopView: View {
    private static var screenshotUpgrade: UpgradeKind {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-shot-tech-surge") { return .surgeMastery }
        if arguments.contains("-shot-tech-magnet") { return .magnetism }
        if arguments.contains("-shot-tech-loadout") { return .shieldLattice }
        if arguments.contains("-shot-tech-temporal") { return .beamForecast }
        return .velocity
    }

    @Environment(AppModel.self) private var model
    var onBack: (() -> Void)? = nil
    var hostTopInset: CGFloat = 0

    @State private var section: LabSection = ProcessInfo.processInfo.arguments.contains("-shot-research")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-loadout")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-time")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-detail")
        ? .research
        : .loadout
    @State private var flash: String?
    @State private var researchBranch: UpgradeBranch = ProcessInfo.processInfo.arguments.contains("-shot-research-loadout")
        ? .loadout
        : (ProcessInfo.processInfo.arguments.contains("-shot-research-time") ? .temporal : .motion)
    @State private var inspectedUpgrade: UpgradeKind? = ProcessInfo.processInfo.arguments.contains("-shot-research-detail")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-surge")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-magnet")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-loadout")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-temporal")
        ? ShopView.screenshotUpgrade
        : nil
    @State private var inspectedSkill: BonusKind? = ProcessInfo.processInfo.arguments.contains("-shot-ability")
        ? .freeze
        : nil

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 12) {
                header
                balanceCard
                sectionPicker

                ScrollView(showsIndicators: false) {
                    Group {
                        switch section {
                        case .loadout:
                            loadoutSection
                        case .research:
                            researchSection
                        }
                    }
                    .padding(.bottom, 28)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, hostTopInset + 8)
        }
        .sheet(item: $inspectedUpgrade) { kind in
            researchInspector(kind)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(EchoTheme.navyDeep)
        }
        .sheet(item: $inspectedSkill) { kind in
            abilityInspector(kind)
                .presentationDetents([.height(570)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(30)
                .presentationBackground(EchoTheme.navyDeep)
        }
    }

    private var header: some View {
        HStack {
            IconCircle(system: "chevron.left") { goBack() }
            VStack(alignment: .leading, spacing: 2) {
                Text("TEMPORAL LAB")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2.5)
                Text("SKILLS & PERMANENT UPGRADES")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer()
            if let flash {
                Text(flash)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(EchoTheme.gold)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .transition(.opacity)
            }
        }
    }

    private var balanceCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(EchoTheme.magenta.opacity(0.15))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(EchoTheme.magenta)
            }
            .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(model.progress.points)")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Text("RESEARCH POINTS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.3)
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(model.progress.skillSlotCount) SLOTS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(EchoTheme.cyan)
                Text("\(model.progress.inventoryCapacity) MAX / SKILL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(EchoTheme.muted)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EchoTheme.panel.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EchoTheme.panelStroke, lineWidth: 1)
        )
    }

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(LabSection.allCases, id: \.rawValue) { item in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeOut(duration: 0.18)) { section = item }
                } label: {
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(section == item ? .white : EchoTheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(section == item ? EchoTheme.primaryBlue.opacity(0.82) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private var loadoutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("ACTIVE LOADOUT")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                    Spacer()
                    Text("\(model.progress.equippedSkills.count)/\(model.progress.skillSlotCount)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(EchoTheme.cyan)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<model.progress.skillSlotCount, id: \.self) { index in
                            loadoutSlot(index)
                                .frame(width: 58)
                        }
                    }
                }

                Text("Equipped skills appear in the arena. Each charge is consumed on use; cooldown prevents rapid repeats.")
                    .font(.system(size: 11))
                    .foregroundStyle(EchoTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )

            Text("ARSENAL")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.6)
                .foregroundStyle(EchoTheme.muted)

            ForEach(BonusKind.allCases.filter(\.canBuy), id: \.self) { kind in
                skillRow(kind)
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func loadoutSlot(_ index: Int) -> some View {
        let equipped = model.progress.equippedSkills
        if equipped.indices.contains(index) {
            let kind = equipped[index]
            let tint = color(kind.tint)
            VStack(spacing: 4) {
                AbilityIconView(kind: kind, size: 31)
                Text(kind.title.uppercased())
                    .font(.system(size: 7, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(tint.opacity(0.42), lineWidth: 1)
            )
        } else {
            VStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                Text("EMPTY")
                    .font(.system(size: 7, weight: .bold))
            }
            .foregroundStyle(EchoTheme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
        }
    }

    private func skillRow(_ kind: BonusKind) -> some View {
        let unlocked = model.progress.isSkillUnlocked(kind)
        let owned = model.progress.count(kind)
        let equipped = model.progress.equippedSkills.contains(kind)
        let full = owned >= model.progress.inventoryCapacity
        let affordable = model.progress.canBuy(kind)
        let tint = color(kind.tint)

        return VStack(spacing: 11) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(tint.opacity(unlocked ? 0.17 : 0.06))
                    AbilityIconView(kind: kind, size: 42)
                        .saturation(unlocked ? 1 : 0)
                        .opacity(unlocked ? 1 : 0.35)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 7) {
                        Text(kind.title)
                            .font(.system(size: 17, weight: .semibold))
                        Text("\(Int(kind.cooldown))s CD")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(EchoTheme.muted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06), in: Capsule())
                    }
                    Text(unlocked ? kind.detail : model.progress.skillUnlockHint(kind))
                        .font(.system(size: 11))
                        .foregroundStyle(unlocked ? EchoTheme.muted : EchoTheme.gold)
                        .lineLimit(2)
                    Text(unlocked ? "Reserve \(owned)/\(model.progress.inventoryCapacity)" : "LOCKED")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(unlocked && owned > 0 ? EchoTheme.cyan : EchoTheme.muted)
                }
                Spacer(minLength: 0)
            }

            Button {
                guard unlocked else { return }
                model.audio.play(.select)
                inspectedSkill = kind
            } label: {
                Label(unlocked ? "ANIMATED DEMO · TAP TO WATCH" : "DEMO LOCKED", systemImage: unlocked ? "play.rectangle.fill" : "lock.fill")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundStyle(unlocked ? tint : EchoTheme.muted)
                    .background(tint.opacity(unlocked ? 0.10 : 0.035), in: Capsule())
                    .overlay(Capsule().stroke(tint.opacity(unlocked ? 0.26 : 0.07), lineWidth: 1))
            }
            .buttonStyle(PressStyle())
            .disabled(!unlocked)

            HStack(spacing: 9) {
                Button {
                    toggle(kind)
                } label: {
                    Label(equipped ? "EQUIPPED" : "EQUIP", systemImage: equipped ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 10, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .foregroundStyle(equipped ? EchoTheme.cyan : .white)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(PressStyle())
                .disabled(!unlocked)

                Button {
                    buy(kind)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "diamond.fill")
                        Text(full ? "FULL" : "\(model.progress.skillPrice(kind))")
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .foregroundStyle(affordable ? .white : EchoTheme.muted)
                    .background(affordable ? EchoTheme.primaryBlue : Color.white.opacity(0.05), in: Capsule())
                }
                .buttonStyle(PressStyle())
                .disabled(!affordable)
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EchoTheme.panel.opacity(unlocked ? 0.90 : 0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(unlocked ? tint.opacity(0.20) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func abilityInspector(_ kind: BonusKind) -> some View {
        let tint = color(kind.tint)
        return ZStack {
            LinearGradient.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 13) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 38, height: 4)
                        .padding(.top, 10)

                    HStack(spacing: 11) {
                        AbilityIconView(kind: kind, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ABILITY TRAINING")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(1.6)
                                .foregroundStyle(tint)
                            Text(kind.title)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                            Text(kind.command)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(EchoTheme.cyan)
                        }
                        Spacer()
                        Button { inspectedSkill = nil } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    MechanicDemoView(scenario: MechanicDemoScenario(bonus: kind), height: 188)

                    HStack(spacing: 8) {
                        abilityStep("1", "SEE", icon: "eye.fill", tint: EchoTheme.cyan)
                        Image(systemName: "chevron.right").foregroundStyle(EchoTheme.muted.opacity(0.55))
                        abilityStep("2", "TAP", icon: "hand.tap.fill", tint: tint)
                        Image(systemName: "chevron.right").foregroundStyle(EchoTheme.muted.opacity(0.55))
                        abilityStep("3", "MOVE", icon: "location.fill", tint: EchoTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(kind.detail)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Label(kind.bestUse, systemImage: "lightbulb.fill")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            abilityStat(icon: "timer", value: kind.duration > 0 ? String(format: "%.1fs", kind.duration) : "INSTANT", title: "EFFECT", tint: tint)
                            abilityStat(icon: "arrow.clockwise", value: "\(Int(kind.cooldown))s", title: "COOLDOWN", tint: EchoTheme.cyan)
                        }
                    }
                    .padding(13)
                    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
    }

    private func abilityStep(_ number: String, _ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.13))
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 27, height: 27)
            VStack(alignment: .leading, spacing: 0) {
                Text(number).font(.system(size: 7, weight: .black, design: .rounded)).foregroundStyle(tint)
                Text(title).font(.system(size: 8, weight: .black, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func abilityStat(icon: String, value: String, title: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(size: 11, weight: .bold, design: .rounded))
                Text(title).font(.system(size: 7, weight: .bold, design: .rounded)).foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var researchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            researchSummary
            researchGuide
            researchBranchPicker
            researchRoute
        }
        .padding(.top, 2)
    }

    private var researchSummary: some View {
        let earned = UpgradeKind.allCases.reduce(0) { $0 + model.progress.upgradeLevel($1) }
        let total = UpgradeKind.allCases.reduce(0) { $0 + $1.maxLevel }
        let progress = total == 0 ? 0 : Double(earned) / Double(total)

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            colors: [EchoTheme.cyan, EchoTheme.magenta, EchoTheme.gold, EchoTheme.cyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: EchoTheme.cyan.opacity(0.45), radius: 5)
                Text("\(earned)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text("TIMELINE MATRIX")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.8)
                Text("\(total)-rank journey · \(earned) synchronized")
                    .font(.system(size: 11))
                    .foregroundStyle(EchoTheme.muted)
                Text("Choose a branch. Only fully unlocked nodes can be opened.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(EchoTheme.cyan.opacity(0.82))
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.96), EchoTheme.violet.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private var researchGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("HOW THE TREE WORKS", systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                Spacer()
                Label("ALL PARENTS REQUIRED", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(EchoTheme.magenta)
            }

            Text("A node opens only after every listed prerequisite reaches its rank. Green checks are complete; locks still need research. Prerequisites can live in another branch.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                researchGuideBadge("✓ REQUIREMENT MET", tint: .green)
                researchGuideBadge("◆ POINT COST", tint: EchoTheme.gold)
            }
        }
        .padding(13)
        .background(
            LinearGradient(
                colors: [EchoTheme.primaryBlue.opacity(0.16), EchoTheme.magenta.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(EchoTheme.cyan.opacity(0.16), lineWidth: 1)
        )
    }

    private func researchGuideBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(tint.opacity(0.10), in: Capsule())
    }

    private var researchBranchPicker: some View {
        HStack(spacing: 7) {
            ForEach(UpgradeBranch.allCases, id: \.rawValue) { branch in
                let tint = color(branch.tint)
                let kinds = researchOrder(for: branch)
                let unlocked = kinds.filter {
                    model.progress.prerequisitesMet(for: $0) && model.progress.upgradeLevel($0) < $0.maxLevel
                }.count
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { researchBranch = branch }
                    model.audio.play(.select)
                } label: {
                    VStack(spacing: 5) {
                        ResearchIconView(kind: kinds[0], size: 34)
                            .opacity(researchBranch == branch ? 1 : 0.66)
                        Text(branch.title)
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.5)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("\(unlocked) UNLOCKED")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(unlocked > 0 ? tint : EchoTheme.muted)
                    }
                    .foregroundStyle(researchBranch == branch ? .white : EchoTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 77)
                    .background(
                        researchBranch == branch ? tint.opacity(0.18) : Color.white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(researchBranch == branch ? tint.opacity(0.62) : Color.white.opacity(0.07), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(branch.title) research, \(unlocked) unlocked upgrades")
            }
        }
    }

    private var researchRoute: some View {
        let kinds = researchOrder(for: researchBranch)
        let tint = color(researchBranch.tint)
        let researched = kinds.filter { model.progress.upgradeLevel($0) > 0 }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                Image(systemName: branchIcon(researchBranch))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(researchBranch.title) RESEARCH")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.1)
                    Text("\(researched) of \(kinds.count) technologies researched")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 3)

            ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
                researchRouteNode(kind, index: index)
            }
        }
        .padding(12)
        .background(EchoTheme.navyDeep.opacity(0.76), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }

    private func researchRouteNode(_ kind: UpgradeKind, index: Int) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let revealed = available || level > 0
        let complete = level >= kind.maxLevel
        let cost = model.progress.upgradeCost(kind)
        let affordable = model.progress.canUpgrade(kind)
        let tint = color(kind.branch.tint)

        return Button {
            guard available else {
                model.audio.play(.denied)
                show(model.progress.upgradeRequirement(kind) ?? "Finish the marked prerequisites")
                return
            }
            inspectedUpgrade = kind
            model.audio.play(.select)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(tint.opacity(revealed ? 0.14 : 0.04))
                        ResearchIconView(kind: kind, size: 54)
                            .saturation(revealed ? 1 : 0)
                            .opacity(revealed ? 1 : 0.13)
                        if !revealed {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white.opacity(0.70))
                        }
                    }
                    .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("NODE \(String(format: "%02d", index + 1)) · \(kind.branch.title)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(tint)
                        Text(revealed ? kind.title : "Undiscovered technology")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(revealed ? .white : EchoTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(revealed ? "Rank \(level) / \(kind.maxLevel)" : "Complete all requirements to reveal")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: revealed ? "play.rectangle.fill" : "lock.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(revealed ? tint : EchoTheme.muted.opacity(0.45))
                }

                if revealed {
                    Text(kind.detail)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.73))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !kind.prerequisites.isEmpty {
                    Text("REQUIRES ALL")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1.0)
                        .foregroundStyle(EchoTheme.muted)
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(0..<kind.prerequisites.count, id: \.self) { item in
                            let requirement = kind.prerequisites[item]
                            let met = model.progress.upgradeLevel(requirement.kind) >= requirement.level
                            HStack(spacing: 6) {
                                Image(systemName: met ? "checkmark.circle.fill" : "lock.circle.fill")
                                    .foregroundStyle(met ? .green : EchoTheme.gold)
                                Text("\(requirement.kind.branch.title.uppercased()) · \(requirement.kind.title) · rank \(requirement.level)")
                                    .foregroundStyle(met ? .white.opacity(0.82) : EchoTheme.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                Spacer(minLength: 0)
                                Text(met ? "DONE" : "MISSING")
                                    .foregroundStyle(met ? .green : EchoTheme.gold)
                            }
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                    }
                } else {
                    Label("STARTING TECHNOLOGY", systemImage: "sparkle")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                }

                HStack {
                    Text(complete ? "FULLY RESEARCHED" : revealed ? affordable ? "TAP TO WATCH & UPGRADE" : "TAP TO WATCH" : "LOCKED")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(0.5)
                        .foregroundStyle(revealed ? tint : EchoTheme.muted)
                    Spacer()
                    if let cost, revealed {
                        Label("\(cost)", systemImage: "diamond.fill")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(affordable ? EchoTheme.gold : EchoTheme.muted)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                revealed ? tint.opacity(0.075) : Color.white.opacity(0.018),
                in: RoundedRectangle(cornerRadius: 17, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(revealed ? tint.opacity(affordable ? 0.44 : 0.19) : Color.white.opacity(0.055), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(revealed ? "\(kind.title), rank \(level) of \(kind.maxLevel)" : "Undiscovered technology")
        .accessibilityHint(revealed ? "Open animated preview" : model.progress.upgradeRequirement(kind) ?? "Locked")
    }

    private func researchOrder(for branch: UpgradeBranch) -> [UpgradeKind] {
        switch branch {
        case .motion:
            [.velocity, .sparkSense, .dashCapacitor, .surgeMastery, .dashImpulse, .magnetism, .repulseResearch, .blinkResearch]
        case .loadout:
            [.slots, .reserves, .aegis, .fabricator, .shieldLattice, .phaseResearch, .prismResearch, .fieldAmplifier]
        case .temporal:
            [.recharge, .beamForecast, .cryostasis, .echoForecast, .crystalMemory, .anchorResearch, .chronoResearch, .rewind]
        }
    }

    private func selectedResearchCard(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let tint = color(kind.branch.tint)
        let cost = model.progress.upgradeCost(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let affordable = model.progress.canUpgrade(kind)
        let missingPoints = max(0, (cost ?? 0) - model.progress.points)

        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.15))
                    ResearchIconView(kind: kind, size: 44)
                        .shadow(color: tint.opacity(0.65), radius: 7)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.branch.title)
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(tint)
                    Text(kind.title)
                        .font(.system(size: 18, weight: .semibold))
                    Text("RANK \(level) / \(kind.maxLevel)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer()
                HStack(spacing: 3) {
                    ForEach(0..<kind.maxLevel, id: \.self) { rank in
                        Capsule()
                            .fill(rank < level ? tint : Color.white.opacity(0.10))
                            .frame(width: 12, height: 5)
                    }
                }
            }

            Text(kind.detail)
                .font(.system(size: 12))
                .foregroundStyle(EchoTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 9) {
                researchEffectCard(
                    eyebrow: "CURRENT",
                    value: researchEffect(kind, level: level),
                    tint: tint.opacity(0.72)
                )
                researchEffectCard(
                    eyebrow: level == kind.maxLevel ? "STATUS" : "NEXT RANK",
                    value: level == kind.maxLevel ? "Fully synchronized" : researchEffect(kind, level: level + 1),
                    tint: level == kind.maxLevel ? EchoTheme.gold : tint
                )
            }

            if let requirement = model.progress.upgradeRequirement(kind) {
                Label(requirement.uppercased(), systemImage: "lock.fill")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.6)
                    .foregroundStyle(EchoTheme.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }

            if let cost {
                Button {
                    upgrade(kind)
                } label: {
                    HStack {
                        Image(systemName: available ? "arrow.up.circle.fill" : "lock.fill")
                        Text(
                            !available
                                ? "NODE LOCKED"
                                : affordable
                                    ? "UPGRADE TO RANK \(level + 1)"
                                    : "NEED \(missingPoints) MORE"
                        )
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.7)
                        Spacer()
                        Label("\(cost)", systemImage: "diamond.fill")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(affordable ? .white : EchoTheme.muted)
                    .padding(.horizontal, 15)
                    .frame(height: 44)
                    .background(
                        affordable
                            ? AnyShapeStyle(LinearGradient(colors: [tint, tint.opacity(0.62)], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.055)),
                        in: Capsule()
                    )
                }
                .buttonStyle(PressStyle())
                .disabled(!available || !affordable)

                if available, !affordable {
                    Text("Clear levels and Daily challenges to earn research points.")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(EchoTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Label("RESEARCH COMPLETE", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(tint.opacity(0.10), in: Capsule())
            }
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.98), tint.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.20), lineWidth: 1)
        )
    }

    private func researchInspector(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let current = researchEffect(kind, level: level)
        let next = level == kind.maxLevel ? "Fully synchronized" : researchEffect(kind, level: level + 1)
        let tint = color(kind.branch.tint)

        return ZStack {
            LinearGradient.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 13) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 38, height: 4)
                        .padding(.top, 10)

                    HStack {
                        ResearchIconView(kind: kind, size: 43)
                            .frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TECHNOLOGY PREVIEW")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(1.8)
                            Text("Guided before → after · permanent upgrade")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(EchoTheme.muted)
                        }
                        Spacer()
                        Button {
                            inspectedUpgrade = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 38, height: 38)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Close upgrade details")
                    }

                    TechnologyPreviewView(
                        kind: kind,
                        level: level,
                        currentValue: current,
                        nextValue: next,
                        height: 236
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        explanationRow(
                            icon: "gearshape.2.fill",
                            eyebrow: "WHAT CHANGES",
                            text: kind.detail,
                            tint: tint
                        )
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                        explanationRow(
                            icon: "scope",
                            eyebrow: "WHEN YOU WILL FEEL IT",
                            text: kind.useCase,
                            tint: EchoTheme.gold
                        )
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )

                    selectedResearchCard(kind)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
    }

    private func explanationRow(icon: String, eyebrow: String, text: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(tint)
                Text(text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func researchEffectCard(eyebrow: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow)
                .font(.system(size: 8, weight: .bold))
                .tracking(1)
                .foregroundStyle(EchoTheme.muted)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 45, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    private func researchEffect(_ kind: UpgradeKind, level: Int) -> String {
        switch kind {
        case .velocity:
            return level == 0 ? "Base movement speed" : "+\(level * 4)% movement speed"
        case .sparkSense:
            return level == 0 ? "Base pickup radius" : "+\(level * 4) spark reach"
        case .dashCapacitor:
            return level == 0 ? "2.6s dash cooldown" : "−\(level * 9)% dash cooldown"
        case .surgeMastery:
            return level == 0 ? "4.0s Surge" : String(format: "%.2fs Surge", BonusKind.surge.duration + Double(level) * 0.45)
        case .dashImpulse:
            return level == 0 ? "1.15s dash" : String(format: "%.2fs dash", 1.15 + Double(level) * 0.09)
        case .slots:
            return "\(min(6, 2 + level)) active skill slots"
        case .reserves:
            return "\(min(ProgressStore.maxOwned, 3 + level * 2)) charges per skill"
        case .fabricator:
            return level == 0 ? "Standard skill prices" : "−\(level * 5)% skill prices"
        case .aegis:
            if level == 0 { return "Base shield recovery" }
            if level >= 5 { return "+0.9s grace · starts shielded" }
            return String(format: "+%.1fs shield grace", Double(level) * 0.18)
        case .shieldLattice:
            if level == 0 { return "Single-layer shield" }
            if level >= 5 { return "+0.6s grace · 2 layers" }
            return String(format: "+%.2fs shield grace", Double(level) * 0.12)
        case .fieldAmplifier:
            return level == 0 ? "Base effect durations" : "+\(level * 4)% timed effects"
        case .recharge:
            return level == 0 ? "Base cooldown" : "−\(level * 8)% skill cooldown"
        case .beamForecast:
            return level == 0 ? "Base beam warning" : String(format: "+%.2fs beam warning", Double(level) * 0.18)
        case .cryostasis:
            return String(format: "%.1fs Freeze duration", BonusKind.freeze.duration + Double(level) * 0.55)
        case .echoForecast:
            return level == 0 ? "Standard echo schedule" : String(format: "+%.2fs before echoes", Double(level) * 0.45)
        case .crystalMemory:
            return level == 0 ? "+1.5s crystal Freeze" : String(format: "+%.1fs crystal Freeze", 1.5 + Double(level) * 0.30)
        case .magnetism:
            return level == 0 ? "Magnet locked" : "Magnet · +\(level * 14)% radius"
        case .phaseResearch:
            return level == 0 ? "Phase locked" : String(format: "Phase · %.1fs", BonusKind.phase.duration + Double(max(0, level - 1)) * 0.45)
        case .chronoResearch:
            return level == 0 ? "Shift & Pulse locked" : String(format: "Shift · +%.1fs", 3.6 + Double(max(0, level - 1)) * 0.65)
        case .rewind:
            let seconds = 3 + Double(level) * 0.45
            let charges = level >= 5 ? 3 : level >= 2 ? 2 : 1
            return String(format: "%.1fs rewind · %d charge%@", seconds, charges, charges == 1 ? "" : "s")
        case .anchorResearch:
            return level == 0 ? "Anchor locked" : String(format: "Anchor · %d%% world · %.1fs", max(24, 44 - level * 5), BonusKind.anchor.duration + Double(level) * 0.35)
        case .repulseResearch:
            return level == 0 ? "Repulse locked" : "Repulse · \(160 + level * 24) radius"
        case .prismResearch:
            return level == 0 ? "Prism locked" : String(format: "Prism · %.1fs", BonusKind.prism.duration + Double(level) * 0.5)
        case .blinkResearch:
            return level == 0 ? "Blink locked" : "Blink · \(165 + level * 28) distance"
        }
    }

    private func branchIcon(_ branch: UpgradeBranch) -> String {
        switch branch {
        case .motion: "location.north.line.fill"
        case .loadout: "square.grid.2x2.fill"
        case .temporal: "clock.fill"
        }
    }

    private func goBack() {
        model.audio.play(.tap)
        if let onBack {
            onBack()
        } else {
            model.goHome()
        }
    }

    private func buy(_ kind: BonusKind) {
        if model.progress.buy(kind) {
            model.audio.play(.confirm)
            model.audio.haptic(.medium)
            show("+1 \(kind.title)")
        } else {
            model.audio.play(.denied)
            show(model.progress.isSkillUnlocked(kind) ? "Need points" : model.progress.skillUnlockHint(kind))
        }
    }

    private func toggle(_ kind: BonusKind) {
        let wasEquipped = model.progress.equippedSkills.contains(kind)
        if model.progress.toggleEquipped(kind) {
            model.audio.play(.select)
            show(wasEquipped ? "\(kind.title) removed" : "\(kind.title) equipped")
        } else {
            model.audio.play(.denied)
            show("All skill slots are full")
        }
    }

    private func upgrade(_ kind: UpgradeKind) {
        if model.progress.buyUpgrade(kind) {
            model.audio.play(.confirm)
            model.audio.haptic(.medium)
            show("\(kind.title) upgraded")
        } else if let requirement = model.progress.upgradeRequirement(kind) {
            model.audio.play(.denied)
            show(requirement)
        } else {
            model.audio.play(.denied)
            show("Need more points")
        }
    }

    private func show(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) { flash = message }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            if flash == message {
                withAnimation(.easeIn(duration: 0.16)) { flash = nil }
            }
        }
    }

    private func color(_ rgb: RGB) -> Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    private func color(_ tint: (r: Double, g: Double, b: Double)) -> Color {
        Color(red: tint.r, green: tint.g, blue: tint.b)
    }
}

private enum LabSection: String, CaseIterable {
    case loadout = "SKILLS"
    case research = "UPGRADES"

    var icon: String {
        switch self {
        case .loadout: "square.grid.2x2"
        case .research: "point.3.connected.trianglepath.dotted"
        }
    }
}

struct ResearchIconView: View {
    let kind: UpgradeKind
    let size: CGFloat

    var body: some View {
        Group {
            if let icon = ResearchIconAtlas.icons[kind] {
                Image(uiImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: kind.icon)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private enum ResearchIconAtlas {
    static let icons: [UpgradeKind: UIImage] = {
        let groups: [(String, [UpgradeKind])] = [
            ("ResearchMotionAtlas", [
                .velocity, .sparkSense, .dashCapacitor, .magnetism,
                .repulseResearch, .blinkResearch, .surgeMastery, .dashImpulse,
            ]),
            ("ResearchLoadoutAtlas", [
                .slots, .reserves, .aegis, .phaseResearch,
                .prismResearch, .fabricator, .shieldLattice, .fieldAmplifier,
            ]),
            ("ResearchTimeAtlas", [
                .recharge, .beamForecast, .cryostasis, .anchorResearch,
                .chronoResearch, .rewind, .echoForecast, .crystalMemory,
            ]),
        ]
        var output: [UpgradeKind: UIImage] = [:]
        for (assetName, kinds) in groups {
            guard let image = UIImage(named: assetName)?.cgImage else { continue }
            let cellWidth = image.width / 4
            let cellHeight = image.height / 2
            for (index, kind) in kinds.enumerated() {
                let rect = CGRect(
                    x: (index % 4) * cellWidth,
                    y: (index / 4) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                guard let cropped = image.cropping(to: rect) else { continue }
                output[kind] = UIImage(cgImage: cropped)
            }
        }
        return output
    }()
}
