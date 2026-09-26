import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    var onBack: (() -> Void)? = nil
    @State var showingResetConfirmation: Bool
    @State var legalDocument: LegalDocument?

    init(
        onBack: (() -> Void)? = nil,
        showingResetConfirmation: Bool = false,
        legalDocument: LegalDocument? = nil
    ) {
        self.onBack = onBack
        _showingResetConfirmation = State(initialValue: showingResetConfirmation)
        _legalDocument = State(initialValue: legalDocument)
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 12) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionLabel(Copy.text("settings.prefs"))
                        preferencesCard

                        sectionLabel(Copy.text("settings.progression"))
                        difficultyCard

                        sectionLabel(Copy.text("settings.echo"))
                        legalCard

                        resetButton
                        footer
                    }
                    .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .onChange(of: model.progress.soundEnabled) {
            let soundOn = model.progress.soundEnabled
            if !soundOn { model.audio.play(.tap) }
            model.audio.enabled = soundOn
            if soundOn { model.audio.play(.confirm) }
            model.progress.persistSettings()
        }
        .onChange(of: model.progress.soundVolume) {
            model.audio.setMasterVolume(model.progress.soundVolume)
            model.progress.persistSettings()
        }
        .onChange(of: model.progress.hapticsEnabled) {
            model.audio.setHapticsEnabled(model.progress.hapticsEnabled)
            model.audio.play(.select)
            if model.progress.hapticsEnabled { model.audio.haptic(.medium) }
            model.progress.persistSettings()
        }
        .onChange(of: model.progress.autoReplayEnabled) {
            model.audio.play(.select)
            model.progress.persistSettings()
        }
        .fullScreenCover(item: $legalDocument) { document in
            LegalPageView(document: document, onBack: { legalDocument = nil })
        }
        .alert(Copy.text("settings.reset.title"), isPresented: $showingResetConfirmation) {
            Button(Copy.text("settings.reset.cancel"), role: .cancel) {}
            Button(Copy.text("settings.reset.confirm"), role: .destructive) {
                model.progress.resetProgress()
                model.goHome()
            }
        } message: {
            Text(Copy.text("settings.reset.message"))
        }
    }

    private func goBack() {
        model.audio.play(.tap)
        if let onBack {
            onBack()
        } else {
            model.goHome()
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") { goBack() }

            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.text("settings.title"))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.5)
                Text(Copy.text("settings.subtitle"))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer()

            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(EchoTheme.cyan)
                .frame(width: 38, height: 38)
                .background(EchoTheme.cyan.opacity(0.10), in: Circle())
                .overlay(Circle().stroke(EchoTheme.cyan.opacity(0.18), lineWidth: 1))
        }
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            settingsToggle(
                Copy.text("settings.sound"),
                detail: Copy.text("settings.sound.detail"),
                systemImage: "speaker.wave.2.fill",
                tint: EchoTheme.cyan,
                isOn: Bindable(model.progress).soundEnabled
            )
            volumeControl
            preferenceDivider
            settingsToggle(
                Copy.text("settings.haptics"),
                detail: Copy.text("settings.haptics.detail"),
                systemImage: "hand.tap.fill",
                tint: EchoTheme.violet,
                isOn: Bindable(model.progress).hapticsEnabled
            )
            preferenceDivider
            settingsToggle(
                Copy.text("settings.replay"),
                detail: Copy.text("settings.replay.detail"),
                systemImage: "backward.end.alt.fill",
                tint: EchoTheme.magenta,
                isOn: Bindable(model.progress).autoReplayEnabled
            )
            preferenceDivider
            LanguageRow()
        }
        .background(EchoTheme.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(EchoTheme.panelStroke, lineWidth: 1))
    }

    private var preferenceDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.065))
            .frame(height: 1)
            .padding(.leading, 61)
    }

    private var volumeControl: some View {
        HStack(spacing: 10) {
            Image(systemName: model.progress.soundVolume < 0.08 ? "speaker.slash.fill" : "speaker.wave.1.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(EchoTheme.cyan.opacity(model.progress.soundEnabled ? 0.9 : 0.35))
                .frame(width: 24)

            Slider(value: Bindable(model.progress).soundVolume, in: 0...1)
                .tint(EchoTheme.cyan)
                .disabled(!model.progress.soundEnabled)
                .accessibilityLabel(Copy.text("settings.volume"))
                .accessibilityValue(Copy.format("settings.volume.value", Int((model.progress.soundVolume * 100).rounded())))

            Text("\(Int((model.progress.soundVolume * 100).rounded()))%")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white.opacity(model.progress.soundEnabled ? 0.62 : 0.28))
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.leading, 58)
        .padding(.trailing, 16)
        .frame(height: 40)
        .opacity(model.progress.soundEnabled ? 1 : 0.55)
    }

    private var difficultyCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 11) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(EchoTheme.magenta)
                    .frame(width: 44, height: 44)
                    .background(EchoTheme.magenta.opacity(0.13), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.format("settings.difficulty", model.progress.difficulty.number))
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(EchoTheme.magenta)
                    Text(model.progress.difficulty.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                }

                Spacer()

                Text(Copy.format("settings.mapsRegions", LevelCatalog.playable.count, Act.allCases.count))
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(EchoTheme.gold)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(EchoTheme.gold.opacity(0.09), in: Capsule())
            }

            Text(model.progress.difficulty.detail)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
            Text(Copy.text("settings.passNote"))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(EchoTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .background(
            LinearGradient(
                colors: [EchoTheme.magenta.opacity(0.11), EchoTheme.panel.opacity(0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(EchoTheme.magenta.opacity(0.22), lineWidth: 1))
    }

    private var legalCard: some View {
        VStack(spacing: 0) {
            ForEach(LegalDocument.allCases) { document in
                Button {
                    model.audio.play(.select)
                    legalDocument = document
                } label: {
                    HStack(spacing: 11) {
                        Image(systemName: document == .about ? "info.circle.fill" : (document == .terms ? "doc.text.fill" : "hand.raised.fill"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(EchoTheme.cyan)
                            .frame(width: 36, height: 36)
                            .background(EchoTheme.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        Text(document.title.uppercased())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 58)
                }
                .buttonStyle(PressStyle())
                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 61)
            }
            BugReportRow()
        }
        .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            showingResetConfirmation = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(Copy.text("settings.resetAll"))
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .tracking(0.9)
                    Text(Copy.text("settings.resetAll.detail"))
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.48))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .frame(height: 60)
            .background(EchoTheme.danger.opacity(0.09), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(EchoTheme.danger.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }

    private var footer: some View {
        HStack(spacing: 13) {
            Text("ECHO")
                .font(.system(size: 20, weight: .ultraLight))
                .tracking(5)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.text("settings.footer"))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(0.8)
                Text(Copy.format("settings.version", LegalDocument.shortVersion, LegalDocument.buildNumber))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .tracking(1.5)
            .foregroundStyle(EchoTheme.muted)
            .padding(.leading, 3)
    }

    private func settingsToggle(
        _ title: String,
        detail: String,
        systemImage: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 11) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(detail)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
            }
        }
            .tint(EchoTheme.primaryBlue)
            .padding(.horizontal, 14)
            .frame(height: 64)
    }
}
