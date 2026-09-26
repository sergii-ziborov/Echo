import SwiftUI
import UIKit

extension ShopView {
    func abilityInspector(_ kind: BonusKind) -> some View {
        let tint = color(kind.tint)
        return ZStack {
            LinearGradient.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 13) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 38, height: 4)
                        .padding(.top, 10)

                    HStack(spacing: 11) {
                        AbilityIconView(kind: kind, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Copy.text("lab.ability.eyebrow"))
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(1.6)
                                .foregroundStyle(tint)
                            Text(kind.title)
                                .font(.system(size: 24, weight: .black, design: .rounded))
                            Text(kind.command)
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(EchoTheme.cyan)
                        }
                        Spacer()
                        Button { inspectedSkill = nil } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    MechanicDemoView(scenario: MechanicDemoScenario(bonus: kind), height: 188)

                    HStack(spacing: 8) {
                        abilityStep("1", Copy.text("lab.ability.see"), icon: "eye.fill", tint: EchoTheme.cyan)
                        Image(systemName: "chevron.right").foregroundStyle(EchoTheme.muted.opacity(0.55))
                        abilityStep("2", Copy.text("lab.ability.tap"), icon: "hand.tap.fill", tint: tint)
                        Image(systemName: "chevron.right").foregroundStyle(EchoTheme.muted.opacity(0.55))
                        abilityStep("3", Copy.text("lab.ability.move"), icon: "location.fill", tint: EchoTheme.gold)
                    }

                    VStack(alignment: .leading, spacing: 7) {
                        Text(kind.detail)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Label(kind.bestUse, systemImage: "lightbulb.fill")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            abilityStat(icon: "timer", value: kind.duration > 0 ? Copy.format("unit.seconds", Copy.seconds(kind.duration)) : Copy.text("lab.ability.instant"), title: Copy.text("lab.ability.effect"), tint: tint)
                            abilityStat(icon: "arrow.clockwise", value: Copy.format("unit.seconds", Copy.seconds(kind.cooldown)), title: Copy.text("lab.ability.cooldown"), tint: EchoTheme.cyan)
                        }
                    }
                    .padding(13)
                    .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
    }

    func abilityStep(_ number: String, _ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(tint.opacity(0.13))
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 27, height: 27)
            VStack(alignment: .leading, spacing: 0) {
                Text(number).font(.system(size: 7, weight: .black, design: .rounded)).foregroundStyle(tint)
                Text(title).font(.system(size: 8, weight: .black, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func abilityStat(icon: String, value: String, title: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(size: 11, weight: .bold, design: .rounded))
                Text(title).font(.system(size: 7, weight: .bold, design: .rounded)).foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    var researchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            researchSummary
            researchGuide
            researchBranchPicker
            researchRoute
        }
        .padding(.top, 2)
    }

    var researchSummary: some View {
        let earned = UpgradeKind.allCases.reduce(0) { $0 + model.progress.upgradeLevel($1) }
        let total = UpgradeKind.allCases.reduce(0) { $0 + $1.maxLevel }
        let progress = total == 0 ? 0 : Double(earned) / Double(total)

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            colors: [EchoTheme.cyan, EchoTheme.magenta, EchoTheme.gold, EchoTheme.cyan],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: EchoTheme.cyan.opacity(0.45), radius: 5)
                Text("\(earned)")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.text("lab.matrix.title"))
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.8)
                Text(Copy.format("lab.matrix.progress", total, earned))
                    .font(.system(size: 11))
                    .foregroundStyle(EchoTheme.muted)
                Text(Copy.text("lab.matrix.hint"))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(EchoTheme.cyan.opacity(0.82))
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.96), EchoTheme.violet.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    var researchGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(Copy.text("lab.guide.title"), systemImage: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                Spacer()
                Label(Copy.text("lab.guide.all"), systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(EchoTheme.magenta)
            }

            Text(Copy.text("lab.guide.body"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.80))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                researchGuideBadge(Copy.text("lab.guide.met"), tint: .green)
                researchGuideBadge(Copy.text("lab.guide.cost"), tint: EchoTheme.gold)
            }
        }
        .padding(13)
        .background(
            LinearGradient(
                colors: [EchoTheme.primaryBlue.opacity(0.16), EchoTheme.magenta.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke(EchoTheme.cyan.opacity(0.16), lineWidth: 1)
        )
    }

    func researchGuideBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.system(size: 8, weight: .black, design: .rounded))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .frame(height: 24)
            .background(tint.opacity(0.10), in: Capsule())
    }

    var researchBranchPicker: some View {
        HStack(spacing: 7) {
            ForEach(UpgradeBranch.allCases, id: \.rawValue) { branch in
                let tint = color(branch.tint)
                let kinds = researchOrder(for: branch)
                let unlocked = kinds.filter {
                    model.progress.prerequisitesMet(for: $0) && model.progress.upgradeLevel($0) < $0.maxLevel
                }.count
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { researchBranch = branch }
                    model.audio.play(.select)
                } label: {
                    VStack(spacing: 5) {
                        ResearchIconView(kind: kinds[0], size: 34)
                            .opacity(researchBranch == branch ? 1 : 0.66)
                        Text(branch.title)
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .tracking(0.5)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(Copy.format("lab.branch.open", unlocked))
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(unlocked > 0 ? tint : EchoTheme.muted)
                    }
                    .foregroundStyle(researchBranch == branch ? .white : EchoTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 77)
                    .background(
                        researchBranch == branch ? tint.opacity(0.18) : Color.white.opacity(0.035),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(researchBranch == branch ? tint.opacity(0.62) : Color.white.opacity(0.07), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Copy.format("lab.branch.a11y", branch.title, unlocked))
            }
        }
    }

    var researchRoute: some View {
        let kinds = researchOrder(for: researchBranch)
        let tint = color(researchBranch.tint)
        let researched = kinds.filter { model.progress.upgradeLevel($0) > 0 }.count

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                ResearchIconView(kind: kinds[0], size: 34)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.format("lab.branch.header", researchBranch.title))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .tracking(1.1)
                    Text(Copy.format("lab.branch.progress", researched, kinds.count))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.bottom, 3)

            ForEach(Array(kinds.enumerated()), id: \.element) { index, kind in
                researchRouteNode(kind, index: index)
            }
        }
        .padding(12)
        .background(EchoTheme.navyDeep.opacity(0.76), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
    }
}
