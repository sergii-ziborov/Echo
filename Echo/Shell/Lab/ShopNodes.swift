import SwiftUI
import UIKit

extension ShopView {
    func researchRouteNode(_ kind: UpgradeKind, index: Int) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let available = model.progress.prerequisitesMet(for: kind)
        let complete = level >= kind.maxLevel
        let cost = model.progress.upgradeCost(kind)
        let affordable = model.progress.canUpgrade(kind)
        let tint = color(kind.branch.tint)
        let line = available
            ? kind.effect(atRank: level)
            : (model.progress.upgradeRequirement(kind) ?? Copy.text("lab.locked"))

        return HStack(spacing: 10) {
            Button {
                guard available else {
                    model.audio.play(.denied)
                    show(line)
                    return
                }
                inspectedUpgrade = kind
                model.audio.play(.select)
            } label: {
                HStack(spacing: 10) {
                    ResearchIconView(kind: kind, size: 36)
                        .frame(width: 42, height: 42)
                        .background(tint.opacity(available ? 0.16 : 0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .opacity(available ? 1 : 0.45)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(kind.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(available ? .white : EchoTheme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(line)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(available ? .white.opacity(0.72) : EchoTheme.muted)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        HStack(spacing: 3) {
                            ForEach(0..<kind.maxLevel, id: \.self) { rank in
                                Capsule()
                                    .fill(rank < level ? tint : Color.white.opacity(0.12))
                                    .frame(width: 9, height: 4)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Copy.format("lab.node.a11y", kind.title, level, kind.maxLevel))

            Spacer(minLength: 4)

            if complete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityLabel(Copy.text("lab.node.complete"))
            } else if available, let cost {
                Button {
                    upgrade(kind)
                } label: {
                    Label("\(cost)", systemImage: "diamond.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(affordable ? .white : EchoTheme.muted)
                        .padding(.horizontal, 10)
                        .frame(height: 32)
                        .background(affordable ? tint.opacity(0.9) : Color.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Copy.format("lab.node.a11y", kind.title, level, kind.maxLevel))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(EchoTheme.muted)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(10)
        .background(tint.opacity(available ? 0.07 : 0.02), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(available ? tint.opacity(affordable ? 0.4 : 0.16) : Color.white.opacity(0.05), lineWidth: 1)
        )
        .accessibilityHint(available ? Copy.text("lab.node.a11yHint") : line)
        .id(index)
    }

    func researchOrder(for branch: UpgradeBranch) -> [UpgradeKind] {
        switch branch {
        case .traits:
            [.velocity, .sparkSense, .dashCapacitor, .dashImpulse, .beamForecast, .echoForecast, .crystalMemory, .rewind]
        case .passives:
            [.aegis, .shieldLattice, .fieldAmplifier, .surgeMastery, .cryostasis, .magnetism, .phaseResearch, .chronoResearch, .anchorResearch, .repulseResearch, .prismResearch, .blinkResearch]
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
