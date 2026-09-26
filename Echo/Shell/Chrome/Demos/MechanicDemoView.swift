import SwiftUI

/// A compact real-time teaching loop. It replaces paragraph-only tutorials and
/// behaves like an embedded four-second clip without shipping large video files.
struct MechanicDemoView: View {
    let scenario: MechanicDemoScenario
    var height: CGFloat = 156
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let loop: TimeInterval = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let rawTime = reduceMotion ? 1.9 : timeline.date.timeIntervalSinceReferenceDate
            let progress = rawTime.truncatingRemainder(dividingBy: Self.loop) / Self.loop

            Canvas { context, size in
                drawGrid(context: &context, size: size)
                drawScenario(context: &context, size: size, progress: progress)
            }
            .overlay(alignment: .topLeading) {
                Label(Copy.format("demo.loop", Copy.seconds(Self.loop)), systemImage: "play.fill")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.86))
                    .padding(.horizontal, 8)
                    .frame(height: 23)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(9)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 5) {
                    Text(scenario.caption)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white)
                    GeometryReader { geometry in
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(scenario.tint)
                                    .frame(width: geometry.size.width * progress)
                            }
                    }
                    .frame(height: 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 9)
            }
        }
        .frame(height: height)
        .background(
            RadialGradient(
                colors: [scenario.tint.opacity(0.17), EchoTheme.navyDeep.opacity(0.98)],
                center: .center,
                startRadius: 2,
                endRadius: 190
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(scenario.tint.opacity(0.28), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel(scenario.caption)
    }

}
