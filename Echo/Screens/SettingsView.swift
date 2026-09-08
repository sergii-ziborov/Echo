import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    IconCircle(system: "chevron.left") { model.goHome() }
                    Spacer()
                    Text("SETTINGS")
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(3)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }

                toggle("Sound", isOn: Bindable(model.progress).soundEnabled)
                toggle("Haptics", isOn: Bindable(model.progress).hapticsEnabled)
                toggle("Replay last seconds on collision", isOn: Bindable(model.progress).autoReplayEnabled)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text("ECHO")
                        .font(.system(size: 22, weight: .ultraLight))
                        .tracking(6)
                    Text("Puzzle today. A brighter tomorrow.")
                        .foregroundStyle(EchoTheme.muted)
                        .font(.system(size: 13))
                    Text("Simple mechanics. Infinite possibilities.")
                        .foregroundStyle(EchoTheme.muted)
                        .font(.system(size: 13))
                }
            }
            .padding(22)
        }
        .onChange(of: model.progress.soundEnabled) {
            model.audio.enabled = model.progress.soundEnabled
            model.progress.persistSettings()
        }
        .onChange(of: model.progress.hapticsEnabled) {
            model.audio.setHapticsEnabled(model.progress.hapticsEnabled)
            model.progress.persistSettings()
        }
        .onChange(of: model.progress.autoReplayEnabled) {
            model.progress.persistSettings()
        }
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .tint(EchoTheme.primaryBlue)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
    }
}
