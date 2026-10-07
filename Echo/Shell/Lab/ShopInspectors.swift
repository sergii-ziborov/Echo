import SwiftUI
import UIKit

extension ShopView {
    func researchInspector(_ kind: UpgradeKind) -> some View {
        let level = model.progress.upgradeLevel(kind)
        let current = kind.effect(atRank: level, progress: model.progress)
        let next = level == kind.maxLevel ? Copy.text("lab.maxed") : kind.effect(atRank: level + 1, progress: model.progress)
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
        if model.progress.buy(kind, equipIfPossible: false) {
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

    func effectiveCooldown(_ kind: BonusKind) -> TimeInterval {
        model.progress.skillCooldown(kind)
    }

    func effectiveDuration(_ kind: BonusKind) -> TimeInterval? {
        model.progress.skillDuration(kind)
    }

    func abilityEffect(_ kind: BonusKind) -> String {
        let tuning = model.progress.playerTuning
        if kind == .magnet, let duration = effectiveDuration(kind) {
            return Copy.format("lab.metric.duration", Copy.seconds(duration)) + " · "
                + Copy.format("lab.metric.radius", Copy.number(SimConfig().magnetRadius * tuning.magnetRadiusMultiplier))
        }
        if kind == .anchor, let duration = effectiveDuration(kind) {
            return Copy.format("lab.metric.duration", Copy.seconds(duration)) + " · "
                + Copy.format("lab.metric.timeScale", Copy.percent(tuning.anchorTimeScale))
        }
        if let duration = effectiveDuration(kind) {
            return Copy.format("lab.metric.duration", Copy.seconds(duration))
        }
        switch kind {
        case .shield:
            return Copy.format("lab.metric.layers", tuning.shieldChargesPerUse) + " · "
                + Copy.format("lab.metric.grace", Copy.seconds(0.55 + tuning.shieldGraceBonus))
        case .pulse:
            return Copy.format("lab.metric.echoDelay", Copy.seconds(WorldSimulation.pulseEchoDelay + tuning.pulseDelayBonus))
        case .chrono:
            return Copy.format("lab.metric.echoDelay", Copy.seconds(WorldSimulation.shiftEchoDelay + tuning.chronoDelayBonus))
        case .repulse:
            return Copy.format("lab.metric.radius", Copy.number(tuning.repulseRadius))
        case .blink:
            return Copy.format("lab.metric.distance", Copy.number(tuning.blinkDistance))
        case .ward:
            return Copy.format("lab.metric.layers", tuning.shieldChargesPerUse)
        default:
            return kind.detail
        }
    }

    func loadoutSlot(_ index: Int) -> some View {
        let equipped = model.progress.equippedSkills
        let kind = equipped.indices.contains(index) ? equipped[index] : nil
        let tint = kind.map { color($0.tint) } ?? EchoTheme.cyan
        return Button {
            editingSlot = index
            slotPickerOpen = true
            model.audio.play(.select)
        } label: {
            VStack(spacing: 6) {
                if let kind {
                    AbilityIconView(kind: kind, size: 72)
                        .shadow(color: tint.opacity(0.5), radius: 10)
                    Text(kind.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(Copy.format("lab.charges", model.progress.count(kind)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(EchoTheme.cyan)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 54, weight: .ultraLight))
                        .foregroundStyle(EchoTheme.muted)
                    Text(Copy.text("lab.slot.empty"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(EchoTheme.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 155)
            .background(tint.opacity(kind == nil ? 0.04 : 0.10), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(tint.opacity(kind == nil ? 0.14 : 0.42), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Copy.text("lab.tapReplace"))
    }

    func skillRow(_ kind: BonusKind) -> some View {
        let tint = color(kind.tint)
        return Button {
            inspectedSkill = kind
            model.audio.play(.select)
        } label: {
            VStack(spacing: 4) {
                AbilityIconView(kind: kind, size: 59)
                Text(kind.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(model.progress.count(kind) > 0 ? Copy.format("lab.charges", model.progress.count(kind)) : Copy.text("lab.noCharges"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(model.progress.count(kind) > 0 ? EchoTheme.cyan : EchoTheme.muted)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .background(EchoTheme.panel.opacity(0.83), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(tint.opacity(0.26), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    var rechargeButton: some View {
        Button {
            rechargeOpen = true
            model.audio.play(.select)
        } label: {
            Label(Copy.text("lab.recharge.title"), systemImage: "bolt.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(EchoTheme.cyan)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(EchoTheme.cyan.opacity(0.11), in: Capsule())
                .overlay(Capsule().stroke(EchoTheme.cyan, lineWidth: 1.5))
        }
        .buttonStyle(PressStyle())
    }

    var slotPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.text("lab.chooseSkill"))
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 20)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(BonusKind.allCases.filter { $0.canBuy && model.progress.isSkillUnlocked($0) }) { kind in
                        Button {
                            if model.progress.setEquipped(kind, at: editingSlot) {
                                slotPickerOpen = false
                                model.audio.play(.confirm)
                                model.audio.haptic(.medium)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                AbilityIconView(kind: kind, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(kind.title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                                    Text(abilityEffect(kind)).font(.system(size: 11)).foregroundStyle(EchoTheme.muted)
                                }
                                Spacer()
                                Text(Copy.format("lab.charges", model.progress.count(kind)))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(EchoTheme.cyan)
                            }
                            .padding(10)
                            .background(EchoTheme.panel, in: RoundedRectangle(cornerRadius: 15))
                        }
                        .buttonStyle(.plain)
                    }
                    if model.progress.equippedSkills.indices.contains(editingSlot) {
                        Button(Copy.text("lab.removeSkill")) {
                            toggle(model.progress.equippedSkills[editingSlot])
                            slotPickerOpen = false
                        }
                        .foregroundStyle(EchoTheme.muted)
                        .padding(10)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    var rechargePanel: some View {
        rechargeContent(compact: true)
            .background(EchoTheme.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(EchoTheme.cyan.opacity(0.25), lineWidth: 1))
    }

    var rechargeSheet: some View {
        rechargeContent(compact: false)
    }

    func rechargeContent(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.text("lab.recharge.title"))
                .font(.system(size: compact ? 19 : 23, weight: .bold))
                .padding(.top, 20)
            Label("\(model.progress.points)", systemImage: "diamond.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(EchoTheme.magenta)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(BonusKind.allCases.filter { $0.canBuy && model.progress.isSkillUnlocked($0) }) { kind in
                        let owned = model.progress.count(kind)
                        let full = owned >= model.progress.inventoryCapacity
                        HStack(spacing: compact ? 7 : 12) {
                            AbilityIconView(kind: kind, size: compact ? 36 : 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(kind.title)
                                    .font(.system(size: compact ? 11 : 14, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                Text(Copy.format("lab.skill.reserve", owned, model.progress.inventoryCapacity))
                                    .font(.system(size: compact ? 9 : 11))
                                    .foregroundStyle(EchoTheme.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            Spacer(minLength: 0)
                            Button { buy(kind) } label: {
                                Text(full ? Copy.text("lab.skill.full") : Copy.format("lab.recharge.price", model.progress.skillPrice(kind)))
                                    .font(.system(size: compact ? 10 : 12, weight: .bold))
                                    .foregroundStyle(model.progress.canBuy(kind) ? .white : EchoTheme.muted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: compact ? 83 : 105, height: compact ? 34 : 39)
                                    .background(model.progress.canBuy(kind) ? EchoTheme.primaryBlue : Color.white.opacity(0.07), in: Capsule())
                            }
                            .buttonStyle(PressStyle())
                            .disabled(!model.progress.canBuy(kind))
                        }
                        .padding(.vertical, 9)
                        Divider().overlay(Color.white.opacity(0.07))
                    }
                }
            }
            Text(Copy.text("lab.recharge.note"))
                .font(.system(size: 10))
                .foregroundStyle(EchoTheme.muted)
                .padding(.bottom, 15)
        }
        .padding(.horizontal, 18)
    }
}
