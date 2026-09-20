import SwiftUI

struct ResearchIconView: View {
    let kind: UpgradeKind
    let size: CGFloat

    var body: some View {
        Group {
            if let icon = ResearchIconAtlas.icons[kind] {
                Image(uiImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: kind.icon)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.18)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

enum ResearchIconAtlas {
    static let icons: [UpgradeKind: UIImage] = {
        let groups: [(String, [UpgradeKind])] = [
            ("ResearchMotionAtlas", [
                .velocity, .sparkSense, .dashCapacitor, .magnetism,
                .repulseResearch, .blinkResearch, .surgeMastery, .dashImpulse,
            ]),
            ("ResearchLoadoutAtlas", [
                .slots, .reserves, .aegis, .phaseResearch,
                .prismResearch, .fabricator, .shieldLattice, .fieldAmplifier,
            ]),
            ("ResearchTimeAtlas", [
                .recharge, .beamForecast, .cryostasis, .anchorResearch,
                .chronoResearch, .rewind, .echoForecast, .crystalMemory,
            ]),
        ]
        var output: [UpgradeKind: UIImage] = [:]
        for (assetName, kinds) in groups {
            guard let image = UIImage(named: assetName)?.cgImage else { continue }
            let cellWidth = image.width / 4
            let cellHeight = image.height / 2
            for (index, kind) in kinds.enumerated() {
                let rect = CGRect(
                    x: (index % 4) * cellWidth,
                    y: (index / 4) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                )
                guard let cropped = image.cropping(to: rect) else { continue }
                output[kind] = UIImage(cgImage: cropped)
            }
        }
        return output
    }()
}
