import SwiftUI

struct TutorialView: View {
    var onDone: () -> Void

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("HOW ECHOES WORK")
                        .font(.system(size: 18, weight: .semibold))
                        .tracking(1.2)
                    Spacer()
                    Button(action: onDone) {
                        Image(systemName: "xmark")
                            .foregroundStyle(EchoTheme.muted)
                            .frame(width: 32, height: 32)
                    }
                }

                TutorialRow(
                    index: 1,
                    title: "You move",
                    detail: "Your orb leaves a trail as you move. Drag anywhere on the arena."
                ) {
                    HexGlyph()
                }

                TutorialRow(
                    index: 2,
                    title: "Echoes appear",
                    detail: "After a short delay, your past movement replays as a ghost."
                ) {
                    EchoGlyph()
                }

                TutorialRow(
                    index: 3,
                    title: "Avoid your echoes",
                    detail: "Echoes are real hazards. Plan ahead — a pretty loop today is a wall tomorrow."
                ) {
                    DangerGlyph()
                }

                Spacer()
                PrimaryButton(title: "Got It", systemImage: "checkmark") { onDone() }
            }
            .padding(24)
        }
    }
}

private struct TutorialRow<Glyph: View>: View {
    var index: Int
    var title: String
    var detail: String
    @ViewBuilder var glyph: Glyph

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            glyph
                .frame(width: 72, height: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(index)  \(title)")
                    .font(.system(size: 17, weight: .semibold))
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(EchoTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

private struct HexGlyph: View {
    var body: some View {
        ZStack {
            Circle().fill(EchoTheme.cyan.opacity(0.15))
            Image(systemName: "hexagon.fill")
                .foregroundStyle(EchoTheme.cyan)
                .font(.system(size: 28))
        }
    }
}

private struct EchoGlyph: View {
    var body: some View {
        ZStack {
            Circle().stroke(EchoTheme.magenta.opacity(0.4), lineWidth: 8).padding(10)
            Circle().fill(EchoTheme.magenta.opacity(0.85)).frame(width: 18, height: 18)
        }
    }
}

private struct DangerGlyph: View {
    var body: some View {
        ZStack {
            Circle().fill(EchoTheme.danger.opacity(0.15))
            Image(systemName: "xmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(EchoTheme.danger)
        }
    }
}
