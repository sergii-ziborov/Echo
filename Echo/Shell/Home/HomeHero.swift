import SwiftUI

struct HomeHero: View {
    let act: Act
    let cleared: Int
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack(alignment: .top) {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: 63)
                    for index in 0..<3 {
                        let expansion = CGFloat(index) * 18
                        let rect = CGRect(
                            x: center.x - 86 - expansion,
                            y: center.y - 43 - expansion * 0.36,
                            width: 172 + expansion * 2,
                            height: 86 + expansion * 0.72
                        )
                        context.stroke(
                            Path(ellipseIn: rect),
                            with: .color((index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta).opacity(0.10 - Double(index) * 0.02)),
                            style: StrokeStyle(lineWidth: 1, dash: [4 + CGFloat(index) * 2, 9])
                        )
                    }

                    for index in 0..<4 {
                        let angle = time * (0.17 + Double(index) * 0.025) + Double(index) * .pi / 2
                        let rx = 92.0 + Double(index % 2) * 21
                        let ry = 46.0 + Double(index % 2) * 8
                        let point = CGPoint(
                            x: center.x + CGFloat(cos(angle) * rx),
                            y: center.y + CGFloat(sin(angle) * ry)
                        )
                        let diameter = CGFloat(index == 0 ? 6 : 3.5)
                        let color = index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta
                        context.fill(
                            Path(ellipseIn: CGRect(x: point.x - diameter / 2, y: point.y - diameter / 2, width: diameter, height: diameter)),
                            with: .color(color.opacity(index == 0 ? 0.9 : 0.55))
                        )
                    }
                }

                VStack(spacing: 1) {
                    EchoMark(size: 126, spinning: !reduceMotion)
                        .scaleEffect(reduceMotion ? 1 : 1 + 0.018 * sin(time * 1.1))

                    Wordmark(titleSize: 43, subtitleSize: 9)

                    HStack(spacing: 7) {
                        HomeHeroPill(
                            text: "ACT \(String(format: "%02d", act.rawValue)) · \(act.title)",
                            tint: act.homeTint
                        )
                        HomeHeroPill(
                            text: cleared == LevelCatalog.playable.count
                                ? "ARCHIVE COMPLETE"
                                : "\(LevelCatalog.playable.count - cleared) TIMELINES REMAIN",
                            tint: EchoTheme.magenta
                        )
                    }
                    .padding(.top, 8)
                }
                .offset(y: reduceMotion ? 0 : CGFloat(sin(time * 0.62) * 1.7))
            }
        }
        .frame(height: 240)
        .accessibilityElement(children: .combine)
    }
}

struct HomeHeroPill: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 4, height: 4)
            Text(text)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .tracking(0.8)
                .lineLimit(1)
        }
        .foregroundStyle(Color.white.opacity(0.7))
        .padding(.horizontal, 9)
        .frame(height: 25)
        .background(Color.white.opacity(0.055), in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.18), lineWidth: 1))
    }
}
