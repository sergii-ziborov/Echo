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
            let progress = rawTime.truncatingRemainder(dividingBy: 5.4) / 5.4
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
                            Text("ANIMATED EFFECT DEMO · 5.4S LOOP")
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
                        .accessibilityLabel("Replay technology demonstration")
                    }
                    .foregroundStyle(.white.opacity(0.90))

                    HStack(spacing: 8) {
                        previewValue("NOW", value: currentValue, tint: EchoTheme.muted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(tint)
                        previewValue(level >= kind.maxLevel ? "STATUS" : "NEXT", value: nextValue, tint: tint)
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
                        stagePill("1 · WITHOUT", active: phase == 0)
                        stagePill("2 · UPGRADE", active: phase == 1)
                        stagePill("3 · WITH", active: phase == 2)
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
        .accessibilityLabel("Animated comparison for \(kind.title). \(kind.detail)")
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
        if phase == 1 { return "UPGRADE APPLIED · WATCH THE SAME SCENE CHANGE" }
        return resultCopy
    }

    var baselineCopy: String {
        switch kind {
        case .velocity: "BEFORE · THE CRYSTAL IS JUST OUT OF REACH"
        case .sparkSense: "BEFORE · YOU MUST TOUCH EVERY SPARK"
        case .dashCapacitor: "BEFORE · DASH IS STILL RECHARGING"
        case .surgeMastery: "BEFORE · THE SPEED BOOST ENDS EARLY"
        case .dashImpulse: "BEFORE · ONE DASH STOPS INSIDE DANGER"
        case .slots: "BEFORE · ONLY CURRENT ABILITY BUTTONS FIT"
        case .reserves: "BEFORE · CHARGES RUN OUT SOONER"
        case .fabricator: "BEFORE · EACH CHARGE COSTS MORE"
        case .aegis: "BEFORE · SHIELD RECOVERY ENDS SOONER"
        case .shieldLattice:
            level + 1 >= kind.maxLevel
                ? "BEFORE · ONE IMPACT BREAKS THE SHIELD"
                : "BEFORE · THE SAFE WINDOW FADES SOONER"
        case .fieldAmplifier: "BEFORE · TIMED EFFECTS EXPIRE SOONER"
        case .recharge: "BEFORE · ABILITIES STAY LOCKED LONGER"
        case .beamForecast: "BEFORE · THE LASER WARNING COMES LATE"
        case .cryostasis: "BEFORE · HAZARDS START MOVING SOONER"
        case .echoForecast: "BEFORE · YOUR ECHO FOLLOWS CLOSER"
        case .crystalMemory: "BEFORE · THE CRYSTAL FREEZES A SMALL WINDOW"
        case .magnetism: "BEFORE · DISTANT SPARKS STAY PUT"
        case .phaseResearch: "BEFORE · SOLID HAZARDS BLOCK THE ROUTE"
        case .chronoResearch: "BEFORE · THE NEXT EVENT ARRIVES SOONER"
        case .rewind: "BEFORE · ONLY A SHORT ROUTE CAN BE UNDONE"
        case .anchorResearch: "BEFORE · THE WHOLE WORLD MOVES AT FULL SPEED"
        case .repulseResearch: "BEFORE · NEARBY HAZARDS KEEP CLOSING IN"
        case .prismResearch: "BEFORE · LASERS CROSS YOUR POSITION"
        case .blinkResearch: "BEFORE · THE JUMP ENDS BEFORE SAFETY"
        }
    }

    var resultCopy: String {
        switch kind {
        case .velocity: "AFTER · YOU REACH THE CRYSTAL SOONER"
        case .sparkSense: "AFTER · THE WIDER RING COLLECTS IT FOR YOU"
        case .dashCapacitor: "AFTER · DASH BECOMES READY SOONER"
        case .surgeMastery: "AFTER · THE SPEED BOOST LASTS LONGER"
        case .dashImpulse: "AFTER · ONE DASH CLEARS THE ENTIRE HAZARD"
        case .slots: "AFTER · ONE MORE ABILITY CAN BE EQUIPPED"
        case .reserves: "AFTER · EVERY ABILITY GAINS TWO CHARGES"
        case .fabricator: "AFTER · FUTURE CHARGES COST FEWER POINTS"
        case .aegis: "AFTER · THE SAFE RECOVERY WINDOW IS LONGER"
        case .shieldLattice:
            level + 1 >= kind.maxLevel
                ? "AFTER · TWO LAYERS CAN ABSORB TWO HITS"
                : "AFTER · THE SAFE WINDOW HOLDS LONGER"
        case .fieldAmplifier: "AFTER · EVERY TIMED FIELD LASTS LONGER"
        case .recharge: "AFTER · THE NEXT ACTIVATION ARRIVES SOONER"
        case .beamForecast: "AFTER · THE WARNING APPEARS EARLIER"
        case .cryostasis: "AFTER · FROZEN HAZARDS WAIT LONGER"
        case .echoForecast: "AFTER · MORE SPACE OPENS BEHIND YOU"
        case .crystalMemory: "AFTER · THE CRYSTAL FREEZES FOR LONGER"
        case .magnetism: "AFTER · THE FIELD PULLS DISTANT SPARKS IN"
        case .phaseResearch: "AFTER · YOU PASS THROUGH THE HAZARD"
        case .chronoResearch: "AFTER · THE TIMELINE IS PUSHED BACK"
        case .rewind: "AFTER · MORE OF YOUR ROUTE RETURNS"
        case .anchorResearch: "AFTER · HAZARDS SLOW WHILE YOU STAY FAST"
        case .repulseResearch: "AFTER · THE WIDER BLAST CLEARS THE ROOM"
        case .prismResearch: "AFTER · THE PRISM BENDS THE BEAM AWAY"
        case .blinkResearch: "AFTER · THE LONGER JUMP REACHES SAFETY"
        }
    }
}
