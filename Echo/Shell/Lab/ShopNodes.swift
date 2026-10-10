import SwiftUI

/// Lays out the eight nodes of one branch by their real same-branch dependencies.
/// Cross-branch requirements stay visible as links in the selected-node card.
struct ResearchTreeLayout {
    let kinds: [UpgradeKind]
    let depths: [UpgradeKind: Int]
    let rowSpacing: CGFloat

    init(kinds: [UpgradeKind], rowSpacing: CGFloat = 126) {
        self.kinds = kinds
        self.rowSpacing = rowSpacing
        var computed: [UpgradeKind: Int] = [:]
        var rowCounts: [Int: Int] = [:]
        let branchKinds = Set(kinds)
        var remaining = kinds
        while !remaining.isEmpty {
            let ready = remaining.filter { kind in
                kind.prerequisites
                    .map(\.kind)
                    .filter { branchKinds.contains($0) }
                    .allSatisfy { computed[$0] != nil }
            }
            precondition(!ready.isEmpty, "Research tree contains a cycle")
            for kind in ready {
                let parents = kind.prerequisites.map(\.kind).filter { branchKinds.contains($0) }
                var row = parents.compactMap { computed[$0].map { $0 + 1 } }.max() ?? 0
                while rowCounts[row, default: 0] >= 3 { row += 1 }
                computed[kind] = row
                rowCounts[row, default: 0] += 1
            }
            let placed = Set(ready)
            remaining.removeAll { placed.contains($0) }
        }
        depths = computed
    }

    var height: CGFloat { CGFloat(depths.values.max() ?? 0) * rowSpacing + 150 }

    func point(for kind: UpgradeKind, width: CGFloat) -> CGPoint {
        let row = depths[kind] ?? 0
        let rowKinds = kinds.filter { depths[$0] == row }
        let index = rowKinds.firstIndex(of: kind) ?? 0
        return CGPoint(
            x: width * CGFloat(index + 1) / CGFloat(rowKinds.count + 1),
            y: CGFloat(row) * rowSpacing + 60
        )
    }

    /// A long dependency takes an outer lane so it does not run through
    /// the cards on the intervening row.
    func path(from parent: UpgradeKind, to child: UpgradeKind, width: CGFloat) -> Path {
        let source = point(for: parent, width: width)
        let destination = point(for: child, width: width)
        let start = CGPoint(x: source.x, y: source.y + 47)
        let end = CGPoint(x: destination.x, y: destination.y - 47)
        var path = Path()
        path.move(to: start)

        if (depths[child] ?? 0) - (depths[parent] ?? 0) > 1 {
            let lane = destination.x >= width / 2 ? width - 20 : 20.0
            let entry = CGPoint(x: lane, y: source.y + 65)
            let exit = CGPoint(x: lane, y: destination.y - 65)
            path.addCurve(to: entry,
                control1: CGPoint(x: source.x, y: entry.y),
                control2: CGPoint(x: lane, y: entry.y))
            path.addLine(to: exit)
            path.addCurve(to: end,
                control1: CGPoint(x: lane, y: exit.y),
                control2: CGPoint(x: destination.x, y: exit.y))
        } else {
            let middle = (source.y + destination.y) / 2
            path.addCurve(to: end,
                control1: CGPoint(x: source.x, y: middle),
                control2: CGPoint(x: destination.x, y: middle))
        }
        return path
    }
}

extension ShopView {
    func researchOrder(for branch: UpgradeBranch) -> [UpgradeKind] {
        switch branch {
        case .motion:
            [.velocity, .sparkSense, .dashCapacitor, .surgeMastery, .dashImpulse, .magnetism, .repulseResearch, .blinkResearch]
        case .loadout:
            [.slots, .reserves, .aegis, .fabricator, .shieldLattice, .phaseResearch, .prismResearch, .fieldAmplifier]
        case .temporal:
            [.recharge, .beamForecast, .cryostasis, .echoForecast, .crystalMemory, .anchorResearch, .chronoResearch, .rewind]
        }
    }

    func researchRoute(rowSpacing: CGFloat) -> some View {
        let kinds = researchOrder(for: researchBranch)
        let layout = ResearchTreeLayout(kinds: kinds, rowSpacing: rowSpacing)
        let tint = color(researchBranch.tint)
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    for target in kinds {
                        for requirement in target.prerequisites where requirement.kind.branch == researchBranch {
                            let path = layout.path(from: requirement.kind, to: target, width: size.width)
                            let met = model.progress.upgradeLevel(requirement.kind) >= requirement.level
                            let focused = target == selectedResearch || requirement.kind == selectedResearch
                            let edgeColor = met ? tint : EchoTheme.muted
                            context.stroke(
                                path,
                                with: .color(edgeColor.opacity(focused ? 0.95 : met ? 0.43 : 0.28)),
                                style: StrokeStyle(
                                    lineWidth: focused ? 2.5 : met ? 1.5 : 1,
                                    lineCap: .round,
                                    lineJoin: .round,
                                    dash: met ? [] : [4, 5]
                                )
                            )
                            if focused {
                                let endpoint = layout.point(for: target, width: size.width)
                                context.fill(
                                    Path(ellipseIn: CGRect(x: endpoint.x - 3, y: endpoint.y - 50, width: 6, height: 6)),
                                    with: .color(edgeColor)
                                )
                            }
                        }
                    }
                }
                ForEach(kinds) { kind in
                    researchTreeNode(kind)
                        .frame(width: min(96, (geometry.size.width - 12) / 4))
                        .position(layout.point(for: kind, width: geometry.size.width))
                        .id(kind)
                }
            }
        }
        .frame(height: layout.height)
        .background(EchoTheme.navyDeep.opacity(0.55), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(tint.opacity(0.14), lineWidth: 1))
    }

    func researchTreeNode(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let selected = selectedResearch == kind
        let tint = color(kind.branch.tint)
        return Button {
            selectedResearch = kind
            model.audio.play(.select)
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    ResearchIconView(kind: kind, size: 43)
                        .shadow(color: available || level > 0 ? tint.opacity(0.65) : .clear, radius: 8)
                        .saturation(available || level > 0 ? 1 : 0.35)
                    Image(systemName: level > 0 ? "checkmark.circle.fill" : available ? "circle.fill" : "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(level > 0 ? EchoTheme.cyan : available ? tint : EchoTheme.muted)
                        .offset(x: 3, y: -2)
                }
                Text(kind.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 26)
                HStack(spacing: 3) {
                    if kind.prerequisites.contains(where: { $0.kind.branch != kind.branch }) {
                        Image(systemName: "link")
                            .font(.system(size: 8))
                    }
                    Text("\(level) / \(kind.maxLevel)")
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(level > 0 ? EchoTheme.cyan : EchoTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 94)
            .background(
                LinearGradient(
                    colors: [tint.opacity(selected ? 0.20 : level > 0 ? 0.10 : 0.04), EchoTheme.panel.opacity(0.86)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? EchoTheme.cyan : tint.opacity(available ? 0.28 : 0.10), lineWidth: selected ? 1.6 : 1))
            .shadow(color: selected ? tint.opacity(0.20) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Copy.format("lab.node.a11y", kind.title, level, kind.maxLevel))
        .accessibilityHint(available ? kind.detail : model.progress.upgradeRequirement(kind) ?? kind.detail)
    }

    func selectedResearchCard(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let cost = model.progress.upgradeCost(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let affordable = model.progress.canUpgrade(kind)
        let tint = color(kind.branch.tint)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ResearchIconView(kind: kind, size: 43)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.title).font(.system(size: 16, weight: .bold))
                    Text(Copy.format("lab.card.rank", level, kind.maxLevel))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer()
                Button { inspectedUpgrade = kind } label: {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Copy.text("lab.skill.demo"))
            }
            Text(kind.detail)
                .font(.system(size: 11))
                .foregroundStyle(EchoTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Text(Copy.text("lab.card.current"))
                        .foregroundStyle(EchoTheme.muted)
                        .frame(width: 68, alignment: .leading)
                    Text(kind.effect(atRank: level, progress: model.progress))
                        .foregroundStyle(.white.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                if level < kind.maxLevel {
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
                    HStack(alignment: .top, spacing: 8) {
                        Text(Copy.text("lab.card.next"))
                            .foregroundStyle(EchoTheme.muted)
                            .frame(width: 68, alignment: .leading)
                        Text(kind.effect(atRank: level + 1, progress: model.progress))
                            .foregroundStyle(EchoTheme.cyan)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !kind.prerequisites.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(kind.prerequisites, id: \.kind) { requirement in
                            let met = model.progress.upgradeLevel(requirement.kind) >= requirement.level
                            Button {
                                jumpToResearch(requirement.kind)
                            } label: {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(color(requirement.kind.branch.tint))
                                        .frame(width: 5, height: 5)
                                    Text("\(requirement.kind.title) \(requirement.level)")
                                    Image(systemName: met ? "checkmark" : "arrow.up.right")
                                }
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(met ? EchoTheme.cyan : EchoTheme.gold)
                                    .padding(.horizontal, 9)
                                    .frame(height: 25)
                                    .background(Color.white.opacity(0.05), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if let cost {
                Button { upgrade(kind) } label: {
                    Label(available ? Copy.format("lab.upgradePrice", cost) : Copy.text("lab.card.nodeLocked"), systemImage: available ? "arrow.up.circle.fill" : "lock.fill")
                        .font(.system(size: 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(affordable ? .white : EchoTheme.muted)
                        .background(affordable ? EchoTheme.primaryBlue : Color.white.opacity(0.08), in: Capsule())
                }
                .buttonStyle(PressStyle())
                .disabled(!affordable)
            }
        }
        .padding(12)
        .background(EchoTheme.panel.opacity(0.98), in: RoundedRectangle(cornerRadius: 19))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(tint.opacity(0.30), lineWidth: 1))
    }

    func jumpToResearch(_ kind: UpgradeKind) {
        model.audio.play(.select)
        withAnimation(.easeInOut(duration: 0.2)) {
            researchBranch = kind.branch
            selectedResearch = kind
        }
    }
}
