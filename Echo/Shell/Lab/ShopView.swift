import SwiftUI
import UIKit

struct ShopView: View {
    static var screenshotUpgrade: UpgradeKind {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-shot-tech-surge") { return .surgeMastery }
        if arguments.contains("-shot-tech-magnet") { return .magnetism }
        if arguments.contains("-shot-tech-loadout") { return .shieldLattice }
        if arguments.contains("-shot-tech-temporal") { return .beamForecast }
        return .velocity
    }

    @Environment(AppModel.self) var model
    var onBack: (() -> Void)? = nil
    var hostTopInset: CGFloat = 0

    @State var section: LabSection = ProcessInfo.processInfo.arguments.contains("-shot-research")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-loadout")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-time")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-detail")
        ? .research
        : .loadout
    @State var flash: String?
    @State var researchBranch: UpgradeBranch = ProcessInfo.processInfo.arguments.contains("-shot-research-loadout")
        ? .loadout
        : (ProcessInfo.processInfo.arguments.contains("-shot-research-time") ? .temporal : .motion)
    @State var inspectedUpgrade: UpgradeKind? = ProcessInfo.processInfo.arguments.contains("-shot-research-detail")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-surge")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-magnet")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-loadout")
        || ProcessInfo.processInfo.arguments.contains("-shot-tech-temporal")
        ? ShopView.screenshotUpgrade
        : nil
    @State var inspectedSkill: BonusKind? = ProcessInfo.processInfo.arguments.contains("-shot-ability")
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

    var header: some View {
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

    var balanceCard: some View {
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

    var sectionPicker: some View {
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

    var loadoutSection: some View {
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

enum LabSection: String, CaseIterable {
    case loadout = "SKILLS"
    case research = "UPGRADES"

    var icon: String {
        switch self {
        case .loadout: "square.grid.2x2"
        case .research: "point.3.connected.trianglepath.dotted"
        }
    }
}
