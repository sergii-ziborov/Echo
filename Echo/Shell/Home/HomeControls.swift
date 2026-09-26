import SwiftUI

struct HomePlayButton: View {
    let level: LevelDefinition
    let act: Act
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let phase = time.truncatingRemainder(dividingBy: 3.2) / 3.2

            Button(action: action) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 42, height: 42)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .black))
                            .offset(x: 1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Copy.text("home.play"))
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .tracking(0.8)
                        Text("\(act.title) \(String(format: "%02d", level.number)) · \(level.title)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .opacity(0.72)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .black))
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.12), in: Circle())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(
                    LinearGradient(
                        colors: [EchoTheme.cyan, EchoTheme.primaryBlueHi, EchoTheme.primaryBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule()
                )
                .overlay {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.30), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.28)
                        .rotationEffect(.degrees(16))
                        .offset(x: -geometry.size.width * 0.35 + geometry.size.width * 1.45 * phase)
                    }
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                }
                .overlay(Capsule().stroke(Color.white.opacity(0.24), lineWidth: 1))
                .shadow(
                    color: EchoTheme.primaryBlue.opacity(0.40),
                    radius: 15 + CGFloat(reduceMotion ? 0 : 2 * sin(time * 1.4)),
                    y: 7
                )
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel(Copy.format("home.a11y.play", level.number, level.title))
        }
    }
}

struct ResourcePill: View {
    let value: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        Label("\(value)", systemImage: systemImage)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .contentTransition(.numericText())
            .padding(.horizontal, 10)
            .frame(height: 37)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.11), Color.white.opacity(0.045)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
    }
}

struct HomeRouteButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 29, height: 29)
                    .background(tint.opacity(0.12), in: Circle())
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.075), tint.opacity(0.055)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(PressStyle())
        .accessibilityLabel(title)
    }
}

