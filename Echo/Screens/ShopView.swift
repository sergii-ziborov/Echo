import SwiftUI

struct ShopView: View {
    @Environment(AppModel.self) private var model
    var onBack: (() -> Void)? = nil

    @State private var section: LabSection = ProcessInfo.processInfo.arguments.contains("-shot-research")
        ? .research
        : .loadout
    @State private var flash: String?
    @State private var selectedUpgrade: UpgradeKind = .velocity
    @State private var inspectedUpgrade: UpgradeKind? = ProcessInfo.processInfo.arguments.contains("-shot-research-detail")
        ? .velocity
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
            .padding(.top, 8)
        }
        .sheet(item: $inspectedUpgrade) { kind in
            researchInspector(kind)
                .presentationDetents([.height(410)])
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

                HStack(spacing: 8) {
                    ForEach(0..<model.progress.skillSlotCount, id: \.self) { index in
                        loadoutSlot(index)
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
                Image(kind.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 29, height: 29)
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
                    Image(kind.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
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
                        Text(full ? "FULL" : "\(kind.price)")
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

    private var researchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            researchSummary
            researchGuide
            researchMatrix
            researchLegend
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
                Text("Permanent research · \(earned) of \(total) ranks synchronized")
                    .font(.system(size: 11))
                    .foregroundStyle(EchoTheme.muted)
                Text("Glowing nodes are ready to upgrade now.")
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
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("HOW TO UPGRADE", systemImage: "hand.tap.fill")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                Spacer()
                Label("\(model.progress.points) AVAILABLE", systemImage: "diamond.fill")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(EchoTheme.magenta)
            }

            HStack(spacing: 6) {
                researchStep(number: 1, icon: "circle.dotted", title: "TAP A\nNODE", tint: EchoTheme.cyan)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(EchoTheme.muted.opacity(0.55))
                researchStep(number: 2, icon: "text.magnifyingglass", title: "CHECK THE\nNEXT RANK", tint: EchoTheme.magenta)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(EchoTheme.muted.opacity(0.55))
                researchStep(number: 3, icon: "arrow.up.circle.fill", title: "PRESS\nUPGRADE", tint: EchoTheme.gold)
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

    private func researchStep(number: Int, icon: String, title: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("STEP \(number)")
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.76))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var researchMatrix: some View {
        GeometryReader { proxy in
            let layout = ResearchTreeLayout(size: proxy.size)
            ZStack {
                Canvas { context, _ in
                    let orbitTint = EchoTheme.violet.opacity(0.08)
                    for radius in [CGFloat(58), 94, 132] {
                        let rect = CGRect(
                            x: layout.core.x - radius,
                            y: layout.core.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.stroke(
                            Circle().path(in: rect),
                            with: .color(orbitTint),
                            style: StrokeStyle(lineWidth: 1, dash: [3, 7])
                        )
                    }

                    drawResearchConnection(
                        context: &context,
                        from: layout.core,
                        to: layout.point(for: .velocity),
                        tint: color(UpgradeBranch.motion.tint),
                        active: true
                    )

                    for child in UpgradeKind.allCases {
                        for requirement in child.prerequisites {
                            drawResearchConnection(
                                context: &context,
                                from: layout.point(for: requirement.kind),
                                to: layout.point(for: child),
                                tint: color(child.branch.tint),
                                active: model.progress.upgradeLevel(requirement.kind) >= requirement.level
                            )
                        }
                    }
                }
                .allowsHitTesting(false)

                researchCore
                    .position(layout.core)

                ForEach(UpgradeBranch.allCases, id: \.rawValue) { branch in
                    Label(branch.title, systemImage: branchIcon(branch))
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(color(branch.tint).opacity(0.86))
                        .position(layout.labelPoint(for: branch))
                }

                ForEach(UpgradeKind.allCases) { kind in
                    researchNode(kind)
                        .position(layout.point(for: kind))
                }
            }
        }
        .frame(height: 730)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(EchoTheme.navyDeep.opacity(0.72))
                RadialGradient(
                    colors: [EchoTheme.violet.opacity(0.12), Color.clear],
                    center: UnitPoint(x: 0.5, y: 0.12),
                    startRadius: 8,
                    endRadius: 230
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.075), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var researchCore: some View {
        ZStack {
            Circle()
                .fill(EchoTheme.violet.opacity(0.16))
                .frame(width: 86, height: 86)
                .blur(radius: 8)
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [EchoTheme.cyan, EchoTheme.violet, EchoTheme.gold, EchoTheme.cyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, dash: [3, 5])
                )
                .frame(width: 75, height: 75)
                .rotationEffect(.degrees(-18))
            Image("TemporalCore")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .shadow(color: EchoTheme.cyan.opacity(0.35), radius: 7)
                .shadow(color: EchoTheme.violet.opacity(0.45), radius: 13)
        }
        .accessibilityLabel("Timeline Matrix research core")
    }

    private func researchNode(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let affordable = model.progress.canUpgrade(kind)
        let tint = color(kind.branch.tint)
        let selected = selectedUpgrade == kind

        return Button {
            guard available else {
                model.audio.play(.tap)
                show(model.progress.upgradeRequirement(kind) ?? "Complete the previous node first")
                return
            }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                selectedUpgrade = kind
            }
            model.audio.play(.tap)
            inspectedUpgrade = kind
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        Circle()
                            .fill(tint.opacity(0.14))
                            .frame(width: 68, height: 68)
                            .blur(radius: 2)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(level > 0 ? 0.60 : available ? 0.20 : 0.06),
                                    EchoTheme.navyDeep,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Circle()
                        .stroke(
                            selected ? tint : tint.opacity(level > 0 ? 0.72 : available ? 0.36 : 0.12),
                            lineWidth: selected ? 2.4 : 1.3
                        )
                        .frame(width: 52, height: 52)
                        .shadow(color: selected || affordable ? tint.opacity(0.65) : .clear, radius: selected ? 9 : 4)

                    Circle()
                        .trim(from: 0, to: kind.maxLevel == 0 ? 0 : CGFloat(level) / CGFloat(kind.maxLevel))
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Image(systemName: available ? kind.icon : "lock.fill")
                        .font(.system(size: available ? 17 : 13, weight: .semibold))
                        .foregroundStyle(available ? (level > 0 ? .white : tint) : EchoTheme.muted.opacity(0.55))

                    Text(level == kind.maxLevel ? "MAX" : "\(level)/\(kind.maxLevel)")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .foregroundStyle(level > 0 ? EchoTheme.navyDeep : .white)
                        .padding(.horizontal, 5)
                        .frame(height: 15)
                        .background(level > 0 ? tint : EchoTheme.panel, in: Capsule())
                        .overlay(Capsule().stroke(tint.opacity(0.45), lineWidth: 0.7))
                        .offset(x: 21, y: 20)
                }
                Text(nodeTitle(kind))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(selected || level > 0 ? .white : EchoTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .frame(width: 82, height: 20, alignment: .top)

                if level == kind.maxLevel {
                    Text("COMPLETE")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(tint)
                } else if available, let cost = model.progress.upgradeCost(kind) {
                    Label("\(cost)", systemImage: "diamond.fill")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(affordable ? EchoTheme.gold : EchoTheme.muted)
                } else {
                    Text("LOCKED")
                        .font(.system(size: 7, weight: .black, design: .rounded))
                        .foregroundStyle(EchoTheme.muted.opacity(0.58))
                }
            }
            .frame(width: 88, height: 98)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(kind.title), rank \(level) of \(kind.maxLevel)")
        .accessibilityHint(available ? "Tap to open upgrade options" : model.progress.upgradeRequirement(kind) ?? "Locked")
    }

    private var researchLegend: some View {
        HStack(spacing: 14) {
            researchLegendItem("UPGRADED", color: EchoTheme.cyan, filled: true)
            researchLegendItem("AVAILABLE", color: EchoTheme.gold, filled: false)
            researchLegendItem("LOCKED", color: EchoTheme.muted, filled: false)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private func researchLegendItem(_ title: String, color: Color, filled: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(filled ? color : Color.clear)
                .overlay(Circle().stroke(color.opacity(0.8), lineWidth: 1))
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 7, weight: .bold))
                .tracking(0.7)
                .foregroundStyle(EchoTheme.muted)
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
                    Image(systemName: kind.icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(tint)
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
                HStack(spacing: 4) {
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
        ZStack {
            LinearGradient.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 13) {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 38, height: 4)
                    .padding(.top, 10)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("UPGRADE NODE")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.8)
                        Text("Changes apply permanently and immediately")
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
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close upgrade details")
                }

                selectedResearchCard(kind)

                Spacer(minLength: 4)
            }
            .padding(.horizontal, 18)
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

    private func drawResearchConnection(
        context: inout GraphicsContext,
        from start: CGPoint,
        to end: CGPoint,
        tint: Color,
        active: Bool
    ) {
        let bend = max(22, abs(end.y - start.y) * 0.42)
        var path = Path()
        path.move(to: start)
        path.addCurve(
            to: end,
            control1: CGPoint(x: start.x, y: start.y + bend),
            control2: CGPoint(x: end.x, y: end.y - bend)
        )
        if active {
            context.stroke(path, with: .color(tint.opacity(0.13)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
            context.stroke(path, with: .color(tint.opacity(0.72)), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
        } else {
            context.stroke(
                path,
                with: .color(Color.white.opacity(0.085)),
                style: StrokeStyle(lineWidth: 1.1, dash: [4, 5])
            )
        }
    }

    private func researchEffect(_ kind: UpgradeKind, level: Int) -> String {
        switch kind {
        case .velocity:
            return level == 0 ? "Base movement speed" : "+\(level * 5)% movement speed"
        case .dashCapacitor:
            return level == 0 ? "2.6s dash cooldown" : "−\(level * 12)% dash cooldown"
        case .slots:
            return "\(2 + level) active skill slots"
        case .reserves:
            return "\(min(ProgressStore.maxOwned, 3 + level * 2)) charges per skill"
        case .aegis:
            if level == 0 { return "Base shield recovery" }
            if level >= 3 { return "+0.7s grace · starts shielded" }
            return String(format: "+%.1fs shield grace", Double(level) * 0.22)
        case .recharge:
            return level == 0 ? "Base cooldown" : "−\(level * 9)% skill cooldown"
        case .beamForecast:
            return level == 0 ? "Base beam warning" : String(format: "+%.2fs beam warning", Double(level) * 0.22)
        case .cryostasis:
            return String(format: "%.1fs Freeze duration", BonusKind.freeze.duration + Double(level) * 0.7)
        case .magnetism:
            return level == 0 ? "Magnet locked" : "Magnet · +\(level * 18)% radius"
        case .phaseResearch:
            return level == 0 ? "Phase locked" : "Phase skill unlocked"
        case .chronoResearch:
            return level == 0 ? "Shift & Pulse locked" : "Shift & Pulse unlocked"
        case .rewind:
            let seconds = 3 + Double(level) * 0.5
            return String(format: "%.1fs rewind%@", seconds, level >= 2 ? " · 2 charges" : "")
        }
    }

    private func nodeTitle(_ kind: UpgradeKind) -> String {
        switch kind {
        case .velocity: "VECTOR DRIVE"
        case .dashCapacitor: "DASH CAPACITOR"
        case .slots: "SLOT MATRIX"
        case .reserves: "RESERVES"
        case .aegis: "AEGIS PROTOCOL"
        case .recharge: "FAST CYCLE"
        case .beamForecast: "BEAM FORECAST"
        case .cryostasis: "CRYOSTASIS"
        case .magnetism: "MAGNETIC FIELD"
        case .phaseResearch: "PHASE THEORY"
        case .chronoResearch: "CHRONO THEORY"
        case .rewind: "LONG REWIND"
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
        if let onBack {
            onBack()
        } else {
            model.goHome()
        }
    }

    private func buy(_ kind: BonusKind) {
        if model.progress.buy(kind) {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            show("+1 \(kind.title)")
        } else {
            model.audio.play(.tap)
            show(model.progress.isSkillUnlocked(kind) ? "Need points" : model.progress.skillUnlockHint(kind))
        }
    }

    private func toggle(_ kind: BonusKind) {
        let wasEquipped = model.progress.equippedSkills.contains(kind)
        if model.progress.toggleEquipped(kind) {
            model.audio.play(.tap)
            show(wasEquipped ? "\(kind.title) removed" : "\(kind.title) equipped")
        } else {
            show("All skill slots are full")
        }
    }

    private func upgrade(_ kind: UpgradeKind) {
        if model.progress.buyUpgrade(kind) {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            show("\(kind.title) upgraded")
        } else if let requirement = model.progress.upgradeRequirement(kind) {
            show(requirement)
        } else {
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

private struct ResearchTreeLayout {
    var size: CGSize

    var core: CGPoint {
        CGPoint(x: size.width * 0.5, y: 47)
    }

    func labelPoint(for branch: UpgradeBranch) -> CGPoint {
        let x: CGFloat = switch branch {
        case .motion: size.width * 0.16
        case .loadout: size.width * 0.50
        case .temporal: size.width * 0.84
        }
        return CGPoint(x: x, y: 105)
    }

    func point(for kind: UpgradeKind) -> CGPoint {
        switch kind {
        case .velocity:
            CGPoint(x: size.width * 0.16, y: 158)
        case .slots:
            CGPoint(x: size.width * 0.50, y: 252)
        case .recharge:
            CGPoint(x: size.width * 0.84, y: 252)
        case .dashCapacitor:
            CGPoint(x: size.width * 0.16, y: 356)
        case .reserves:
            CGPoint(x: size.width * 0.50, y: 356)
        case .beamForecast:
            CGPoint(x: size.width * 0.84, y: 356)
        case .magnetism:
            CGPoint(x: size.width * 0.16, y: 460)
        case .aegis:
            CGPoint(x: size.width * 0.50, y: 460)
        case .cryostasis:
            CGPoint(x: size.width * 0.84, y: 460)
        case .phaseResearch:
            CGPoint(x: size.width * 0.50, y: 564)
        case .chronoResearch:
            CGPoint(x: size.width * 0.84, y: 564)
        case .rewind:
            CGPoint(x: size.width * 0.84, y: 674)
        }
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
