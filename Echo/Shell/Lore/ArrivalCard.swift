import SwiftUI

/// Shown the first time the Signal reaches a region of the Fold Road: where
/// it has landed, and why this part of space is not like the last one.
struct ArrivalCard: View {
    struct Arrival: Equatable {
        let key: String
        let eyebrow: String
        let title: String
        let story: String
        let tint: Color
    }

    let arrival: Arrival
    var onEnter: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 14) {
                HStack {
                    Label(arrival.eyebrow, systemImage: "location.north.circle.fill")
                    Spacer()
                    Text(Copy.text("arrival.road"))
                }
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundStyle(arrival.tint)

                Text(arrival.title)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Capsule()
                    .fill(arrival.tint.opacity(0.6))
                    .frame(width: 44, height: 2)

                Text(arrival.story)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.84))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                PrimaryButton(title: Copy.text("arrival.continue"), systemImage: "arrow.right", action: onEnter)
            }
            .foregroundStyle(.white)
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(arrival.tint.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 22)
        }
    }
}

extension ArrivalCard.Arrival {
    /// The arrival for a run, if it opens a region the Signal has not seen:
    /// each campaign region once, and Deep Time once.
    static func first(for request: PlayRequest, level: LevelDefinition, seen: Set<String>) -> Self? {
        let arrival: Self
        if request.endless != nil {
            arrival = Self(key: "region.deep", eyebrow: Copy.text("arrival.deepEyebrow"), title: Copy.text("mode.deepTime.title").uppercased(), story: Copy.text("mode.deepTime.description"), tint: EchoTheme.magenta)
        } else if request.daily {
            return nil
        } else {
            let act = level.region
            arrival = Self(
                key: "region.\(act.rawValue)",
                eyebrow: Copy.format("arrival.eyebrow", String(format: "%02d", act.rawValue)),
                title: act.region.uppercased(),
                story: act.intro,
                tint: act.atlasTint
            )
        }
        return seen.contains(arrival.key) ? nil : arrival
    }

    static let allKeys = Act.allCases.map { "region.\($0.rawValue)" } + ["region.deep"]
}
