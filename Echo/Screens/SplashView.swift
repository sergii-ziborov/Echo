import SwiftUI

struct SplashView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 28) {
                Spacer()
                EchoMark(size: 260)
                Wordmark()
                Spacer()
                Text("TAP TO BEGIN")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(3)
                    .foregroundStyle(EchoTheme.muted)
                    .padding(.bottom, 36)
            }
            .padding()
        }
        .contentShape(Rectangle())
        .onTapGesture { model.tapSplash() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Tap to begin")
    }
}
