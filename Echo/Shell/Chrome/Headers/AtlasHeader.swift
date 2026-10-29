import SwiftUI

struct AtlasHeader: View {
    @Environment(AppModel.self) private var model
    let tablet: Bool
    let onBack: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 11) {
                back
                title
                Spacer(minLength: 4)
                progress
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 11) {
                    back
                    title
                    Spacer(minLength: 0)
                }
                progress.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var back: some View {
        IconCircle(system: "chevron.left", action: onBack)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Copy.text("atlas.title"))
                .font(.system(size: tablet ? 19 : 14, weight: .black, design: .rounded))
                .tracking(tablet ? 2.2 : 1.5)
                .lineLimit(1)
            Text(Copy.text("atlas.subtitle"))
                .font(.system(size: tablet ? 10 : 8, weight: .bold, design: .rounded))
                .tracking(1.1)
                .lineLimit(1)
                .foregroundStyle(EchoTheme.muted)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var progress: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Label("\(model.progress.totalStars)/\(LevelCatalog.playable.count * 3)", systemImage: "checkmark.seal.fill")
                .foregroundStyle(EchoTheme.gold)
            Text(model.progress.difficulty.shortTitle)
                .foregroundStyle(EchoTheme.magenta)
                .accessibilityIdentifier("atlas.recoveryPass")
        }
        .font(.system(size: tablet ? 11 : 9, weight: .bold, design: .rounded))
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(EchoTheme.gold.opacity(0.08), in: Capsule())
        .overlay(Capsule().stroke(EchoTheme.gold.opacity(0.20), lineWidth: 1))
    }
}
