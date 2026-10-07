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
    @State var selectedResearch: UpgradeKind = .velocity
    @State var slotPickerOpen = false
    @State var editingSlot = 0
    @State var rechargeOpen = ProcessInfo.processInfo.arguments.contains("-shot-recharge")
    @State var lockedSkillsExpanded = false

    init(
        onBack: (() -> Void)? = nil,
        hostTopInset: CGFloat = 0,
        section: LabSection? = nil,
        researchBranch: UpgradeBranch? = nil,
        inspectedUpgrade: UpgradeKind? = nil,
        inspectedSkill: BonusKind? = nil,
        flash: String? = nil
    ) {
        self.onBack = onBack
        self.hostTopInset = hostTopInset
        let arguments = ProcessInfo.processInfo.arguments
        _section = State(initialValue: section ?? (
            arguments.contains("-shot-research")
                || arguments.contains("-shot-research-loadout")
                || arguments.contains("-shot-research-time")
                || arguments.contains("-shot-research-detail")
                ? .research
                : .loadout
        ))
        _flash = State(initialValue: flash)
        _researchBranch = State(initialValue: researchBranch ?? (
            arguments.contains("-shot-research-loadout")
                ? .loadout
                : (arguments.contains("-shot-research-time") ? .temporal : .motion)
        ))
        _inspectedUpgrade = State(initialValue: inspectedUpgrade ?? (
            arguments.contains("-shot-research-detail")
                || arguments.contains("-shot-tech-surge")
                || arguments.contains("-shot-tech-magnet")
                || arguments.contains("-shot-tech-loadout")
                || arguments.contains("-shot-tech-temporal")
                ? ShopView.screenshotUpgrade
                : nil
        ))
        _inspectedSkill = State(initialValue: inspectedSkill ?? (
            arguments.contains("-shot-ability") ? .freeze : nil
        ))
        let initialBranch = researchBranch ?? (arguments.contains("-shot-research-loadout")
            ? .loadout : arguments.contains("-shot-research-time") ? .temporal : .motion)
        _selectedResearch = State(initialValue: initialBranch == .loadout ? .slots : initialBranch == .temporal ? .recharge : .velocity)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScreenBackground()
                VStack(spacing: 12) {
                    header
                    sectionPicker
                    if LabLayout.usesSidePanels(width: geometry.size.width) {
                        expandedContent(width: geometry.size.width - 36, height: geometry.size.height)
                    } else {
                        compactContent
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, hostTopInset + 8)
            }
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
        .sheet(isPresented: $slotPickerOpen) {
            slotPicker
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .presentationBackground(EchoTheme.navyDeep)
        }
        .sheet(isPresented: $rechargeOpen) {
            rechargeSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .presentationBackground(EchoTheme.navyDeep)
        }
    }

    /// The Duo's inner display has room to keep the next action beside the list.
    @ViewBuilder
    func expandedContent(width: CGFloat, height: CGFloat) -> some View {
        switch section {
        case .loadout:
            HStack(alignment: .top, spacing: 14) {
                ScrollView(showsIndicators: false) {
                    loadoutSection.padding(.bottom, 12)
                }
                rechargePanel
                    .frame(width: min(360, width * 0.42))
                    .frame(height: min(390, max(260, height - 160)))
            }
        case .research:
            HStack(alignment: .top, spacing: 14) {
                researchScroll
                ScrollView(showsIndicators: false) {
                    selectedResearchCard(selectedResearch)
                        .padding(.bottom, 12)
                }
                .frame(width: min(320, width * 0.44))
            }
        }
    }

    var compactContent: some View {
        VStack(spacing: 12) {
            researchScroll
            if section == .research {
                selectedResearchCard(selectedResearch)
            } else {
                rechargeButton
            }
        }
    }

    var researchScroll: some View {
        ScrollViewReader { scroll in
            ScrollView(showsIndicators: false) {
                Group {
                    switch section {
                    case .loadout: loadoutSection.padding(.bottom, 12)
                    case .research: researchSection
                    }
                }
            }
            .onChange(of: selectedResearch) { _, kind in
                guard section == .research else { return }
                withAnimation(.easeInOut(duration: 0.24)) {
                    scroll.scrollTo(kind, anchor: .center)
                }
            }
        }
    }

    var header: some View {
        HStack {
            IconCircle(system: "chevron.left") { goBack() }
            Text(Copy.text("lab.title"))
                .font(.system(size: 19, weight: .bold))
            Spacer()
            Label("\(model.progress.points)", systemImage: "diamond.fill")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(EchoTheme.magenta.opacity(0.15), in: Capsule())
                .overlay(Capsule().stroke(EchoTheme.magenta.opacity(0.25), lineWidth: 1))
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

    var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(LabSection.allCases, id: \.rawValue) { item in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeOut(duration: 0.18)) { section = item }
                } label: {
                    Text(item.title)
                        .font(.system(size: 13, weight: .semibold))
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
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(Copy.text("lab.inGame"))
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("\(model.progress.equippedSkills.count)/\(model.progress.skillSlotCount)")
                    .foregroundStyle(EchoTheme.cyan)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(0..<model.progress.skillSlotCount, id: \.self) { index in
                    loadoutSlot(index)
                }
            }
            Text(Copy.text("lab.tapReplace"))
                .font(.system(size: 11))
                .foregroundStyle(EchoTheme.muted)
                .frame(maxWidth: .infinity)

            Text(Copy.text("lab.otherSkills"))
                .font(.system(size: 18, weight: .bold))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                ForEach(BonusKind.allCases.filter { $0.canBuy && model.progress.isSkillUnlocked($0) && !model.progress.equippedSkills.contains($0) }) { kind in
                    skillRow(kind)
                }
            }
            Button {
                withAnimation { lockedSkillsExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                    Text(Copy.format("lab.lockedSkills", BonusKind.allCases.filter { $0.canBuy && !model.progress.isSkillUnlocked($0) }.count))
                    Spacer()
                    Image(systemName: lockedSkillsExpanded ? "chevron.down" : "chevron.right")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(EchoTheme.muted)
                .padding(15)
                .background(EchoTheme.panel, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            if lockedSkillsExpanded {
                ForEach(BonusKind.allCases.filter { $0.canBuy && !model.progress.isSkillUnlocked($0) }) { kind in
                    Button { inspectedSkill = kind } label: {
                        Label(kind.title, systemImage: kind.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(EchoTheme.panel, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 2)
    }
}

enum LabSection: String, CaseIterable {
    case loadout = "SKILLS"
    case research = "UPGRADES"

    var title: String {
        switch self {
        case .loadout: Copy.text("lab.section.loadout")
        case .research: Copy.text("lab.section.research")
        }
    }

    var icon: String {
        switch self {
        case .loadout: "square.grid.2x2"
        case .research: "point.3.connected.trianglepath.dotted"
        }
    }
}

enum LabLayout {
    static func usesSidePanels(width: CGFloat) -> Bool { width >= 620 }
}
