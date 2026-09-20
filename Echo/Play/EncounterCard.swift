import SwiftUI

struct EncounterCard: View {
    var hint: EncounterHint
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Label("FIRST CONTACT", systemImage: "play.rectangle.fill")
                    Spacer()
                    Text("WATCH THE LOOP")
                }
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(EchoTheme.muted)
                Text(hint.title)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .tracking(1)
                MechanicDemoView(scenario: MechanicDemoScenario(hint: hint), height: 162)
                Text(hint.action)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(EchoTheme.cyan)
                Text(hint.detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Try it", systemImage: "play.fill", action: onDismiss)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(EchoTheme.navy.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            )
            .padding(.horizontal, 22)
        }
    }
}

enum InRunOverlay {
    case none
    case shop
    case settings
}
