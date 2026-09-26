import SwiftUI
import UIKit

extension ShopView {
    func researchRouteNode(_ kind: UpgradeKind, index: Int) -> some View {
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
                show(model.progress.upgradeRequirement(kind) ?? Copy.text("lab.node.prerequisites"))
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
                        Text(Copy.format("lab.node.index", String(format: "%02d", index + 1), kind.branch.title))
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(tint)
                        Text(revealed ? kind.title : Copy.text("lab.node.hidden"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(revealed ? .white : EchoTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(revealed ? Copy.format("lab.node.rank", level, kind.maxLevel) : Copy.text("lab.node.reveal"))
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
                    Text(Copy.text("lab.node.requiresAll"))
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
                                Text(Copy.format("lab.node.requirement", requirement.kind.branch.title.uppercased(), requirement.kind.title, requirement.level))
                                    .foregroundStyle(met ? .white.opacity(0.82) : EchoTheme.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.78)
                                Spacer(minLength: 0)
                                Text(Copy.text(met ? "lab.node.done" : "lab.node.missing"))
                                    .foregroundStyle(met ? .green : EchoTheme.gold)
                            }
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                    }
                } else {
                    Label(Copy.text("lab.node.start"), systemImage: "sparkle")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(tint)
                }

                HStack {
                    Text(Copy.text(complete ? "lab.node.complete" : revealed ? affordable ? "lab.node.watchUpgrade" : "lab.node.watch" : "lab.locked"))
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
        .accessibilityLabel(revealed ? Copy.format("lab.node.a11y", kind.title, level, kind.maxLevel) : Copy.text("lab.node.hidden"))
        .accessibilityHint(revealed ? Copy.text("lab.node.a11yHint") : model.progress.upgradeRequirement(kind) ?? Copy.text("lab.locked"))
    }

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

    func selectedResearchCard(_ kind: UpgradeKind) -> some View {
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
                    Text(Copy.format("lab.card.rank", level, kind.maxLevel))
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
                    eyebrow: Copy.text("lab.card.current"),
                    value: kind.effect(atRank: level),
                    tint: tint.opacity(0.72)
                )
                researchEffectCard(
                    eyebrow: Copy.text(level == kind.maxLevel ? "lab.card.status" : "lab.card.next"),
                    value: level == kind.maxLevel ? Copy.text("lab.maxed") : kind.effect(atRank: level + 1),
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
                                ? Copy.text("lab.card.nodeLocked")
                                : affordable
                                    ? Copy.format("lab.card.upgrade", level + 1)
                                    : Copy.format("lab.card.needMore", missingPoints)
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
                    Text(Copy.text("lab.card.earn"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(EchoTheme.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                Label(Copy.text("lab.card.complete"), systemImage: "checkmark.seal.fill")
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

}
