import SwiftUI
import UIKit

extension ShopView {
    func researchInspector(_ kind: UpgradeKind) -> some View {
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

    func researchEffect(_ kind: UpgradeKind, level: Int) -> String {
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
            show("+1 \(kind.title)")
        } else {
            model.audio.play(.denied)
            show(model.progress.isSkillUnlocked(kind) ? "Need points" : model.progress.skillUnlockHint(kind))
        }
    }

    func toggle(_ kind: BonusKind) {
        let wasEquipped = model.progress.equippedSkills.contains(kind)
        if model.progress.toggleEquipped(kind) {
            model.audio.play(.select)
            show(wasEquipped ? "\(kind.title) removed" : "\(kind.title) equipped")
        } else {
            model.audio.play(.denied)
            show("All skill slots are full")
        }
    }

    func upgrade(_ kind: UpgradeKind) {
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
}
