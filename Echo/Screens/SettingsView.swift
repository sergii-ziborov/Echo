import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    var onBack: (() -> Void)? = nil
    @State private var showingResetConfirmation = false

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    IconCircle(system: "chevron.left") { goBack() }
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

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Label("DIFFICULTY \(model.progress.difficulty.number)", systemImage: "gauge.with.dots.needle.67percent")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .tracking(1.1)
                            .foregroundStyle(EchoTheme.magenta)
                        Spacer()
                        Text(model.progress.difficulty.title)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text(model.progress.difficulty.detail)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                    Text("Clear all 77 epochs to raise difficulty. Every cycle keeps its own seals and records.")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.48))
                }
                .padding(16)
                .background(EchoTheme.magenta.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(EchoTheme.magenta.opacity(0.18), lineWidth: 1))

                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset all progress", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(EchoTheme.danger.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(EchoTheme.danger.opacity(0.22), lineWidth: 1))
                }
                .buttonStyle(PressStyle())

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
        .alert("Reset the timeline?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset progress", role: .destructive) {
                model.progress.resetProgress()
                model.goHome()
            }
        } message: {
            Text("Maps, difficulty, records, shards, inventory and research will be erased. Sound and haptic settings stay unchanged.")
        }
    }

    private func goBack() {
        if let onBack {
            onBack()
        } else {
            model.goHome()
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
