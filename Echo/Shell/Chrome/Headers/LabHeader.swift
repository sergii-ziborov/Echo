import SwiftUI

struct LabHeader: View {
    @Environment(AppModel.self) private var model
    let flash: String?
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                IconCircle(system: "chevron.left", action: onBack)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.text("lab.title"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Copy.text("lab.subtitle"))
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Label("\(model.progress.points)", systemImage: "diamond.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(EchoTheme.magenta.opacity(0.15), in: Capsule())
                    .overlay(Capsule().stroke(EchoTheme.magenta.opacity(0.25), lineWidth: 1))
                    .fixedSize(horizontal: true, vertical: false)
            }
            if let flash {
                Text(flash)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(EchoTheme.gold)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
    }
}
