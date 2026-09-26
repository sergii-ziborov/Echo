import SwiftUI

struct HUDChip<Content: View>: View {
    var icon: String
    var tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            content
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.35), lineWidth: 1))
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct HUDEffectBadge: View {
    var title: String? = nil
    let icon: String
    let value: String
    let tint: Color
    var progress: Double? = nil
    let accessibilityText: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tint)
            if let title {
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.4)
                    .foregroundStyle(.white.opacity(0.88))
            }
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(tint.opacity(0.10), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
        .overlay(alignment: .bottomLeading) {
            if let progress {
                GeometryReader { geometry in
                    Capsule()
                        .fill(tint)
                        .frame(width: geometry.size.width * progress, height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .padding(.horizontal, 4)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel(accessibilityText)
    }
}

struct InventoryBar: View {
    @Environment(AppModel.self) private var model
    var session: GameSession
    var onUse: (BonusKind) -> Void

    var body: some View {
        let equipped = model.progress.equippedSkills
        if session.phase == .playing || session.phase == .paused {
            HStack(spacing: 6) {
                ForEach(0..<model.progress.skillSlotCount, id: \.self) { index in
                    if equipped.indices.contains(index) {
                        let kind = equipped[index]
                        let tint = Color(red: kind.tint.r, green: kind.tint.g, blue: kind.tint.b)
                        let cooldown = session.cooldownRemaining(for: kind)
                        let stock = model.progress.count(kind)
                        Button {
                            onUse(kind)
                        } label: {
                            ZStack {
                                VStack(spacing: 0) {
                                    AbilityIconView(kind: kind, size: 26)
                                    Text("×\(stock)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundStyle(stock > 0 ? .white : EchoTheme.muted)
                                }
                                if cooldown > 0 {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.black.opacity(0.66))
                                    Text(Copy.seconds(cooldown))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(tint.opacity(stock > 0 ? 0.65 : 0.20), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(session.phase != .playing || stock == 0 || cooldown > 0)
                        .accessibilityLabel(Copy.format("hud.a11y.use", kind.title, stock))
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(EchoTheme.muted.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            )
                    }
                }
            }
            .frame(maxWidth: 360, alignment: .leading)
        }
    }
}
