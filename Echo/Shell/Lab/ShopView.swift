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
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 12) {
                header
                balanceCard

                ScrollView(showsIndicators: false) {
                    researchSection
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
    }

    var header: some View {
        HStack {
            IconCircle(system: "chevron.left") { goBack() }
            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.text("lab.title"))
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2.5)
                Text(Copy.text("lab.subtitle"))
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
                Text(Copy.text("lab.points"))
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.3)
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer()
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

}

enum LabSection: String, CaseIterable {
    case research = "UPGRADES"

    var title: String { Copy.text("lab.section.research") }

    var icon: String { "point.3.connected.trianglepath.dotted" }
}
