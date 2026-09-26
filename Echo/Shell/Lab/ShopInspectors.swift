import SwiftUI
import UIKit

extension ShopView {
    func researchInspector(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let current = kind.effect(atRank: level)
        let next = level == kind.maxLevel ? Copy.text("lab.maxed") : kind.effect(atRank: level + 1)
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
                            Text(Copy.text("lab.inspector.title"))
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(1.8)
                            Text(Copy.text("lab.inspector.subtitle"))
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
                        .accessibilityLabel(Copy.text("lab.inspector.close"))
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
                            eyebrow: Copy.text("lab.inspector.changes"),
                            text: kind.detail,
                            tint: tint
                        )
                        Divider()
                            .overlay(Color.white.opacity(0.08))
                        explanationRow(
                            icon: "scope",
                            eyebrow: Copy.text("lab.inspector.when"),
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

    func explanationRow(icon: String, eyebrow: String, text: String, tint: Color) -> some View {
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

    func researchEffectCard(eyebrow: String, value: String, tint: Color) -> some View {
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

    func goBack() {
        model.audio.play(.tap)
        if let onBack {
            onBack()
        } else {
            model.goHome()
        }
    }

    func buy(_ kind: BonusKind) {
        if model.progress.buy(kind) {
            model.audio.play(.confirm)
            model.audio.haptic(.medium)
            show(Copy.format("lab.toast.bought", kind.title))
        } else {
            model.audio.play(.denied)
            show(model.progress.isSkillUnlocked(kind) ? Copy.text("lab.toast.needPoints") : model.progress.skillUnlockHint(kind))
        }
    }

    func toggle(_ kind: BonusKind) {
        let wasEquipped = model.progress.equippedSkills.contains(kind)
        if model.progress.toggleEquipped(kind) {
            model.audio.play(.select)
            show(Copy.format(wasEquipped ? "lab.toast.removed" : "lab.toast.equipped", kind.title))
        } else {
            model.audio.play(.denied)
            show(Copy.text("lab.toast.slotsFull"))
        }
    }

    func upgrade(_ kind: UpgradeKind) {
        if model.progress.buyUpgrade(kind) {
            model.audio.play(.confirm)
            model.audio.haptic(.medium)
            show(Copy.format("lab.toast.upgraded", kind.title))
        } else if let requirement = model.progress.upgradeRequirement(kind) {
            model.audio.play(.denied)
            show(requirement)
        } else {
            model.audio.play(.denied)
            show(Copy.text("lab.toast.needMore"))
        }
    }

    func show(_ message: String) {
        withAnimation(.easeOut(duration: 0.16)) { flash = message }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1500))
            if flash == message {
                withAnimation(.easeIn(duration: 0.16)) { flash = nil }
            }
        }
    }

    func color(_ rgb: RGB) -> Color {
        Color(red: rgb.r, green: rgb.g, blue: rgb.b)
    }

    func color(_ tint: (r: Double, g: Double, b: Double)) -> Color {
        Color(red: tint.r, green: tint.g, blue: tint.b)
    }

    @ViewBuilder
    func loadoutSlot(_ index: Int) -> some View {
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
                Text(Copy.text("lab.slot.empty"))
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

    func skillRow(_ kind: BonusKind) -> some View {
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
                        Text(Copy.format("lab.skill.cooldown", Copy.seconds(kind.cooldown)))
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
                    Text(unlocked ? Copy.format("lab.skill.reserve", owned, model.progress.inventoryCapacity) : Copy.text("lab.locked"))
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
                Label(Copy.text(unlocked ? "lab.skill.demo" : "lab.skill.demoLocked"), systemImage: unlocked ? "play.rectangle.fill" : "lock.fill")
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
                    Label(Copy.text(equipped ? "lab.skill.equipped" : "lab.skill.equip"), systemImage: equipped ? "checkmark.circle.fill" : "circle")
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
                        Text(full ? Copy.text("lab.skill.full") : "\(model.progress.skillPrice(kind))")
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
}
