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

    @State var section: LabSection = .research
    @State var flash: String?
    @State var researchBranch: UpgradeBranch = ProcessInfo.processInfo.arguments.contains("-shot-research-loadout")
        || ProcessInfo.processInfo.arguments.contains("-shot-research-time")
        ? .passives
        : .traits
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
        _section = State(initialValue: section ?? .research)
        _flash = State(initialValue: flash)
        _researchBranch = State(initialValue: researchBranch ?? (
            arguments.contains("-shot-research-loadout")
                || arguments.contains("-shot-research-time")
                ? .passives
                : .traits
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
        let initialBranch = researchBranch ?? (
            arguments.contains("-shot-research-loadout") || arguments.contains("-shot-research-time")
                ? .passives : .traits
        )
        _selectedResearch = State(initialValue: initialBranch == .passives ? .aegis : .velocity)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScreenBackground()
                VStack(spacing: 12) {
                    header
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
        HStack(alignment: .top, spacing: 14) {
            researchScroll(rowSpacing: min(170, max(126, (height - 240) / 4)))
            ScrollView(showsIndicators: false) {
                selectedResearchCard(selectedResearch)
                    .padding(.bottom, 12)
            }
            .frame(width: min(320, width * 0.44))
        }
    }

    var compactContent: some View {
        VStack(spacing: 12) {
            researchScroll()
            selectedResearchCard(selectedResearch)
        }
    }

    func researchScroll(rowSpacing: CGFloat = 126) -> some View {
        ScrollViewReader { scroll in
            ScrollView(showsIndicators: false) {
                researchSection(rowSpacing: rowSpacing)
            }
            .onChange(of: selectedResearch) { _, kind in
                withAnimation(.easeInOut(duration: 0.24)) {
                    scroll.scrollTo(kind, anchor: .center)
                }
            }
        }
    }

    var header: some View {
        LabHeader(flash: flash) { goBack() }
    }

}

enum LabSection: String, CaseIterable {
    case research = "UPGRADES"

    var title: String { Copy.text("lab.section.research") }

    var icon: String { "point.3.connected.trianglepath.dotted" }
}

enum LabLayout {
    static func usesSidePanels(width: CGFloat) -> Bool { width >= 620 }
}
