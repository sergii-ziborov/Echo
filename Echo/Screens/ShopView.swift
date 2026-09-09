import SwiftUI

struct ShopView: View {
    @Environment(AppModel.self) private var model
    var onBack: (() -> Void)? = nil
    @State private var flash: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 16) {
                HStack {
                    IconCircle(system: "chevron.left") { goBack() }
                    Spacer()
                    Text("SHOP")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(EchoTheme.muted)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }

                HStack {
                    Image(systemName: "diamond.fill")
                        .foregroundStyle(EchoTheme.magenta)
                    Text("\(model.progress.points)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                    Text("points")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(EchoTheme.muted)
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundStyle(EchoTheme.danger)
                    Text("\(model.progress.lives)")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    if let flash {
                        Text(flash)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(EchoTheme.gold)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )

                Text("Stock Freeze, Shield, Phase, Chrono. Pulse and Magnet only drop in the arena.")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        extraLifeRow
                        ForEach(BonusKind.allCases.filter(\.canBuy), id: \.self) { kind in
                            shopRow(kind)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding(22)
        }
    }

    private var extraLifeRow: some View {
        let affordable = model.progress.canBuyLife
        let full = model.progress.lives >= ProgressStore.maxLives
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(EchoTheme.danger.opacity(0.18))
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(EchoTheme.danger)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("Extra Life")
                    .font(.system(size: 17, weight: .semibold))
                Text("Continue after a collision")
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)
                Text("\(model.progress.lives)/\(ProgressStore.maxLives)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(EchoTheme.cyan)
            }

            Spacer()

            Button {
                buyLife()
            } label: {
                VStack(spacing: 2) {
                    Text("\(ProgressStore.lifePrice)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text(full ? "FULL" : "BUY")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(affordable ? .white : EchoTheme.muted)
                .frame(width: 64, height: 52)
                .background(
                    Capsule().fill(affordable ? EchoTheme.primaryBlue : Color.white.opacity(0.08))
                )
            }
            .buttonStyle(PressStyle())
            .disabled(!affordable)
            .accessibilityLabel("Buy extra life for \(ProgressStore.lifePrice) points")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EchoTheme.panel.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EchoTheme.panelStroke, lineWidth: 1)
        )
    }

    private func shopRow(_ kind: BonusKind) -> some View {
        let owned = model.progress.count(kind)
        let affordable = model.progress.canBuy(kind)
        let tint = Color(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b)
        return HStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.18))
                Image(kind.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(kind.title)
                    .font(.system(size: 17, weight: .semibold))
                Text(kind.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(EchoTheme.muted)
                Text(owned == 0 ? "Not owned" : "Owned ×\(owned)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(owned == 0 ? EchoTheme.muted : EchoTheme.cyan)
            }

            Spacer()

            Button {
                buy(kind)
            } label: {
                VStack(spacing: 2) {
                    Text("\(kind.price)")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Text("BUY")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                }
                .foregroundStyle(affordable ? .white : EchoTheme.muted)
                .frame(width: 64, height: 52)
                .background(
                    Capsule().fill(affordable ? EchoTheme.primaryBlue : Color.white.opacity(0.08))
                )
            }
            .buttonStyle(PressStyle())
            .disabled(!affordable)
            .accessibilityLabel("Buy \(kind.title) for \(kind.price) points")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(EchoTheme.panel.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(EchoTheme.panelStroke, lineWidth: 1)
        )
    }

    private func goBack() {
        if let onBack {
            onBack()
        } else {
            model.goHome()
        }
    }

    private func buyLife() {
        if model.progress.buyLife() {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            flash = "+Life"
        } else {
            model.audio.play(.tap)
            flash = model.progress.lives >= ProgressStore.maxLives ? "Full" : "Need \(ProgressStore.lifePrice) pts"
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            if flash == "+Life" || flash?.hasPrefix("Need") == true || flash == "Full" {
                flash = nil
            }
        }
    }

    private func buy(_ kind: BonusKind) {
        if model.progress.buy(kind) {
            model.audio.play(.collect)
            model.audio.haptic(.medium)
            flash = "+\(kind.title)"
        } else {
            model.audio.play(.tap)
            flash = "Need \(kind.price) pts"
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            if flash == "+\(kind.title)" || flash == "Need \(kind.price) pts" {
                flash = nil
            }
        }
    }
}
