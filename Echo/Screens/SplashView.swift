import SwiftUI

struct SplashView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stage = 0
    @State private var leaving = false

    var body: some View {
        ZStack {
            ScreenBackground()

            SplashStarfield(reduceMotion: reduceMotion)
                .opacity(stage >= 1 ? 1 : 0)
                .allowsHitTesting(false)

            SplashScan(stage: stage, reduceMotion: reduceMotion)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                Text("A TEMPORAL SIGNAL")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(3.2)
                    .foregroundStyle(EchoTheme.cyan.opacity(0.72))
                    .opacity(stage >= 2 ? 1 : 0)
                    .offset(y: stage >= 2 ? 0 : 8)

                SplashGlyph(stage: stage, reduceMotion: reduceMotion)
                    .frame(width: 286, height: 286)
                    .padding(.top, 3)

                VStack(spacing: 12) {
                    Wordmark(titleSize: 58, subtitleSize: 10)

                    HStack(spacing: 7) {
                        Circle()
                            .fill(stage >= 3 ? Color.green : EchoTheme.gold)
                            .frame(width: 5, height: 5)
                            .shadow(color: stage >= 3 ? Color.green.opacity(0.8) : EchoTheme.gold.opacity(0.8), radius: 5)
                        Text(stage >= 3 ? "TIMELINE LINK STABLE" : "SYNCHRONIZING TIMELINE")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.5)
                    }
                    .foregroundStyle(stage >= 3 ? EchoTheme.cyan : EchoTheme.gold)
                    .padding(.horizontal, 12)
                    .frame(height: 27)
                    .background(Color.white.opacity(0.05), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.09), lineWidth: 1))
                }
                .opacity(stage >= 2 ? 1 : 0)
                .offset(y: stage >= 2 ? 0 : 18)
                .blur(radius: stage >= 2 ? 0 : 7)

                Spacer()

                SplashEnterPrompt(visible: stage >= 3, reduceMotion: reduceMotion)
                    .padding(.bottom, 34)
            }
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture { enter() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(stage >= 3 ? "Timeline ready. Tap to begin" : "Intro playing. Tap to skip")
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving && !reduceMotion ? 1.035 : 1)
        .blur(radius: leaving && !reduceMotion ? 5 : 0)
        .task { await playIntro() }
    }

    @MainActor
    private func playIntro() async {
        stage = 0
        await Task.yield()

        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.72, dampingFraction: 0.76)) {
            stage = 1
        }

        guard !reduceMotion else {
            stage = 3
            return
        }

        try? await Task.sleep(for: .milliseconds(430))
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.64)) {
            stage = 2
        }

        try? await Task.sleep(for: .milliseconds(680))
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 0.48, dampingFraction: 0.78)) {
            stage = 3
        }
    }

    private func enter() {
        guard !leaving else { return }
        withAnimation(.easeInOut(duration: reduceMotion ? 0.12 : 0.30)) {
            leaving = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 280))
            model.tapSplash()
        }
    }
}

private struct SplashGlyph: View {
    let stage: Int
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion || stage == 0)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RadialGradient(
                    colors: [EchoTheme.cyan.opacity(0.18), EchoTheme.violet.opacity(0.08), .clear],
                    center: .center,
                    startRadius: 8,
                    endRadius: 126
                )
                .scaleEffect(stage >= 1 ? 1 : 0.35)

                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .trim(from: CGFloat(index) * 0.08, to: 0.72 + CGFloat(index) * 0.07)
                        .stroke(
                            index.isMultiple(of: 2) ? EchoTheme.cyan.opacity(0.24) : EchoTheme.magenta.opacity(0.22),
                            style: StrokeStyle(lineWidth: index == 0 ? 1.3 : 0.8, lineCap: .round, dash: [3, 8 + CGFloat(index) * 2])
                        )
                        .frame(width: 205 + CGFloat(index) * 28, height: 205 + CGFloat(index) * 28)
                        .rotationEffect(.degrees(
                            Double(index * 37) + (reduceMotion ? 0 : time * (index.isMultiple(of: 2) ? 7 : -5))
                        ))
                        .scaleEffect(stage >= 1 ? 1 : 0.52)
                        .opacity(stage >= 1 ? 1 : 0)
                }

                ForEach(0..<4, id: \.self) { index in
                    let angle = time * (0.34 + Double(index) * 0.035) + Double(index) * .pi / 2
                    let radius = 112.0 + Double(index % 2) * 18
                    Circle()
                        .fill(index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta)
                        .frame(width: index == 0 ? 6 : 3.5, height: index == 0 ? 6 : 3.5)
                        .shadow(color: index.isMultiple(of: 2) ? EchoTheme.cyan : EchoTheme.magenta, radius: 5)
                        .offset(x: CGFloat(cos(angle) * radius), y: CGFloat(sin(angle) * radius))
                        .opacity(stage >= 1 ? 0.82 : 0)
                }

                EchoMark(size: 218, spinning: !reduceMotion && stage >= 1)
                    .scaleEffect(stage >= 1 ? 1 : 0.22)
                    .opacity(stage >= 1 ? 1 : 0)
                    .blur(radius: stage >= 1 ? 0 : 16)

                Circle()
                    .stroke(EchoTheme.cyan.opacity(stage >= 3 ? 0.0 : 0.48), lineWidth: 1)
                    .frame(width: 88, height: 88)
                    .scaleEffect(stage >= 3 ? 2.55 : 0.4)
                    .opacity(stage >= 3 ? 0 : 1)
            }
            .animation(.easeOut(duration: 0.82), value: stage)
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

private struct SplashScan: View {
    let stage: Int
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation(minimumInterval: 1 / 24, paused: reduceMotion || stage < 2)) { timeline in
                let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                let progress = reduceMotion ? 0.5 : time.truncatingRemainder(dividingBy: 3.4) / 3.4

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, EchoTheme.cyan.opacity(0.16), Color.white.opacity(0.28), EchoTheme.cyan.opacity(0.16), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .shadow(color: EchoTheme.cyan.opacity(0.45), radius: 5)
                    .offset(y: geometry.size.height * (0.18 + progress * 0.64))
                    .opacity(stage >= 2 ? 1 : 0)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SplashEnterPrompt: View {
    let visible: Bool
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion || !visible)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: 10) {
                Image(systemName: "chevron.right.2")
                    .font(.system(size: 10, weight: .black))
                    .offset(x: reduceMotion ? 0 : CGFloat(sin(time * 2.4) * 2))
                Text("TAP TO ENTER")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2.3)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 42)
            .background(Color.white.opacity(0.065), in: Capsule())
            .overlay(Capsule().stroke(EchoTheme.cyan.opacity(0.20), lineWidth: 1))
            .shadow(color: EchoTheme.cyan.opacity(0.10), radius: 12)
            .opacity(visible ? (reduceMotion ? 1 : 0.82 + 0.18 * sin(time * 1.8)) : 0)
            .offset(y: visible ? 0 : 12)
            .animation(.easeOut(duration: 0.4), value: visible)
        }
    }
}

private struct SplashStarfield: View {
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }

                for index in 0..<36 {
                    let xSeed = Double((index * 61 + 17) % 109) / 109
                    let ySeed = Double((index * 43 + 31) % 107) / 107
                    let drift = reduceMotion ? 0 : time * (1.5 + Double(index % 4) * 0.45)
                    let y = CGFloat((ySeed * Double(size.height) + drift).truncatingRemainder(dividingBy: Double(size.height)))
                    let x = CGFloat(xSeed * Double(size.width) + sin(time * 0.15 + Double(index)) * 2.5)
                    let diameter = CGFloat(index.isMultiple(of: 9) ? 2.2 : 1.0)
                    let tint = index.isMultiple(of: 3) ? EchoTheme.cyan : EchoTheme.magenta
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                        with: .color(tint.opacity(index.isMultiple(of: 9) ? 0.38 : 0.17))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}
