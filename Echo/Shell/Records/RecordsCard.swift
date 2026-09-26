import SwiftUI

/// The Home entry to the ratings: both numbers at a glance.
struct RecordsCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let phone = Ratings.total(Ratings.phone(model.progress)).formatted()
        let watch = Ratings.total(Ratings.watch(model.progress.wrist)).formatted()
        Button {
            model.openRecords()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(EchoTheme.gold)
                    .frame(width: 46, height: 46)
                    .background(EchoTheme.gold.opacity(0.12), in: Circle())
                    .overlay(Circle().stroke(EchoTheme.gold.opacity(0.22), lineWidth: 1))
                VStack(alignment: .leading, spacing: 5) {
                    Text(Copy.text("records.card.title"))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(EchoTheme.gold)
                    HStack(spacing: 16) {
                        stat(icon: "iphone", value: phone, tint: EchoTheme.cyan)
                        stat(icon: "applewatch", value: watch, tint: EchoTheme.gold)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(EchoTheme.muted)
            }
            .padding(15)
            .background(
                LinearGradient(
                    colors: [EchoTheme.panel.opacity(0.97), EchoTheme.gold.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(EchoTheme.gold.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(Copy.format("records.card.a11y", phone, watch))
    }

    private func stat(icon: String, value: String, tint: Color) -> some View {
        Label(value, systemImage: icon)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .labelStyle(RecordsStatLabel(tint: tint))
    }
}

private struct RecordsStatLabel: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            configuration.title
        }
    }
}
