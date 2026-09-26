import SwiftUI

/// The Research page: every node of the Signal Matrix with its rank count
/// and prerequisites. Current and next values live in the Lab, computed
/// from the same formulas the run uses.
struct WikiResearchContent: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .foregroundStyle(EchoTheme.violet)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.format("wiki.research.header", UpgradeKind.allCases.count, UpgradeBranch.allCases.count))
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(Copy.text("wiki.research.note"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button {
                    model.openShop()
                } label: {
                    Text(Copy.text("wiki.research.lab"))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(EchoTheme.violet, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(13)
            .background(EchoTheme.violet.opacity(0.12), in: RoundedRectangle(cornerRadius: 17, style: .continuous))

            ForEach(UpgradeBranch.allCases, id: \.self) { branch in
                branchCard(branch)
            }
        }
    }

    private func branchCard(_ branch: UpgradeBranch) -> some View {
        let upgrades = UpgradeKind.allCases.filter { $0.branch == branch }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ResearchIconView(kind: upgrades[0], size: 29)
                    .frame(width: 34, height: 34)
                    .background(branch.wikiColor.opacity(0.13), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(branch.title)
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1)
                    Text(branch.summary)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
            }

            ForEach(upgrades) { upgrade in
                HStack(alignment: .top, spacing: 11) {
                    ZStack {
                        Circle()
                            .fill(branch.wikiColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                        ResearchIconView(kind: upgrade, size: 29)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(upgrade.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Spacer()
                            Text(Copy.format("wiki.research.ranks", upgrade.maxLevel))
                                .font(.system(size: 8, weight: .black, design: .rounded))
                                .tracking(0.7)
                                .foregroundStyle(branch.wikiColor)
                        }
                        Text(upgrade.detail)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                        if !upgrade.prerequisites.isEmpty {
                            Text(Copy.format("wiki.research.requires", upgrade.prerequisites.map { "\($0.kind.title) \($0.level)" }.joined(separator: " + ")))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(branch.wikiColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(15)
        .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(branch.wikiColor.opacity(0.16), lineWidth: 1))
    }
}
