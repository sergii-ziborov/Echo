import SwiftUI

struct TechnologyPreviewView: View {
    let kind: UpgradeKind
    let level: Int
    let currentValue: String
    let nextValue: String
    var height: CGFloat = 232

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var loopStartedAt = Date()

    var tint: Color {
        Color(red: kind.branch.tint.r, green: kind.branch.tint.g, blue: kind.branch.tint.b)
    }

    var plateName: String {
        switch kind.branch {
        case .motion: "TechMotionPlate"
        case .loadout: "TechLoadoutPlate"
        case .temporal: "TechTemporalPlate"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let rawTime = reduceMotion ? 3.8 : max(0, timeline.date.timeIntervalSince(loopStartedAt))
            let progress = rawTime.truncatingRemainder(dividingBy: Self.loop) / Self.loop
            let phase = min(2, Int(progress * 3))

            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.12), EchoTheme.navyDeep.opacity(0.42), EchoTheme.navyDeep.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Canvas { context, size in
                    drawComparison(context: &context, size: size, progress: progress)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 7) {
                        ResearchIconView(kind: kind, size: 33)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kind.title.uppercased())
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .tracking(0.7)
                            Text(Copy.format("tech.loop", Copy.seconds(Self.loop)))
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .tracking(0.4)
                                .foregroundStyle(tint)
                        }
                        Spacer()
                        Button {
                            loopStartedAt = Date()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 31, height: 31)
                                .foregroundStyle(.white)
                                .background(tint.opacity(0.20), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Copy.text("tech.replay"))
                    }
                    .foregroundStyle(.white.opacity(0.90))

                    HStack(spacing: 8) {
                        previewValue(Copy.text("tech.now"), value: currentValue, tint: EchoTheme.muted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(tint)
                        previewValue(Copy.text(level >= kind.maxLevel ? "lab.card.status" : "tech.next"), value: nextValue, tint: tint)
                    }
                    .padding(.top, 9)

                    Spacer()

                    Text(stageCopy(phase))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 33)
                        .background(EchoTheme.navyDeep.opacity(0.88), in: RoundedRectangle(cornerRadius: 11))

                    HStack(spacing: 5) {
                        stagePill(Copy.text("tech.stage.without"), active: phase == 0)
                        stagePill(Copy.text("tech.stage.upgrade"), active: phase == 1)
                        stagePill(Copy.text("tech.stage.with"), active: phase == 2)
                    }
                    .padding(.top, 7)
                }
                .padding(11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                GeometryReader { geometry in
                    Image(plateName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(0.32)
                }
            }
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.42), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.14), radius: 16, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Copy.format("tech.a11y", kind.title, kind.detail))
    }

    func previewValue(_ eyebrow: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(eyebrow)
                .font(.system(size: 7, weight: .black, design: .rounded))
                .tracking(1)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
        .padding(.horizontal, 9)
        .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    func stagePill(_ title: String, active: Bool) -> some View {
        Text(title)
            .font(.system(size: 7, weight: .black, design: .rounded))
            .tracking(0.45)
            .foregroundStyle(active ? .white : EchoTheme.muted.opacity(0.7))
            .frame(maxWidth: .infinity)
            .frame(height: 20)
            .background(active ? tint.opacity(0.48) : Color.black.opacity(0.28), in: Capsule())
            .overlay(Capsule().stroke(active ? tint.opacity(0.8) : Color.white.opacity(0.05), lineWidth: 1))
    }

    func stageCopy(_ phase: Int) -> String {
        if phase == 0 { return baselineCopy }
        if phase == 1 { return Copy.text("tech.applied") }
        return resultCopy
    }

    var baselineCopy: String { Copy.text(sceneKey("before")) }

    var resultCopy: String { Copy.text(sceneKey("after")) }

    /// Shield Lattice's last rank adds a second layer, so its scene changes there.
    func sceneKey(_ side: String) -> String {
        let key = "tech.\(kind.rawValue).\(side)"
        return kind == .shieldLattice && level + 1 >= kind.maxLevel ? key + ".final" : key
    }

    static let loop: TimeInterval = 5.4
}
