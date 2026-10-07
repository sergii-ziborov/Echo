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
                        if !model.progress.isSkillUnlocked(kind) {
                            Label(model.progress.skillUnlockHint(kind), systemImage: "lock.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(EchoTheme.gold)
                        }
                        Text(abilityEffect(kind))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(tint)
                        Label(kind.bestUse, systemImage: "lightbulb.fill")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            abilityStat(icon: "timer", value: effectiveDuration(kind).map { Copy.format("unit.seconds", Copy.seconds($0)) } ?? Copy.text("lab.ability.instant"), title: Copy.text("lab.ability.effect"), tint: tint)
                            abilityStat(icon: "arrow.clockwise", value: Copy.format("unit.seconds", Copy.seconds(effectiveCooldown(kind))), title: Copy.text("lab.ability.cooldown"), tint: EchoTheme.cyan)
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
        VStack(spacing: 14) {
            researchBranchPicker
            researchRoute
        }
        .padding(.top, 2)
    }

    var researchBranchPicker: some View {
        HStack(spacing: 7) {
            ForEach(UpgradeBranch.allCases, id: \.rawValue) { branch in
                let tint = color(branch.tint)
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        researchBranch = branch
                        selectedResearch = researchOrder(for: branch)[0]
                    }
                } label: {
                    Text(branch.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(researchBranch == branch ? EchoTheme.cyan : EchoTheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(researchBranch == branch ? tint.opacity(0.14) : EchoTheme.panel.opacity(0.55), in: Capsule())
                        .overlay(Capsule().stroke(researchBranch == branch ? EchoTheme.cyan : Color.white.opacity(0.08), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
