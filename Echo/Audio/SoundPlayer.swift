import AVFoundation
import UIKit

enum EchoSound: CaseIterable {
    case tap
    case select
    case confirm
    case denied
    case collect
    case crystal
    case resonance
    case timerExpired
    case warn
    case spawn
    case dash
    case laserCharge
    case laserFire
    case asteroidImpact
    case asteroidShatter
    case riftOpen
    case riftEnter
    case exitOpen
    case shieldBreak
    case timeCollision
    case abilityPickup
    case shield
    case freeze
    case surge
    case pulse
    case magnet
    case phase
    case chrono
    case anchor
    case repulse
    case prism
    case blink
    case rewind
    case death
    case win

    var duration: TimeInterval {
        switch self {
        case .tap: 0.08
        case .select: 0.14
        case .confirm: 0.34
        case .denied: 0.22
        case .collect: 0.18
        case .crystal: 0.46
        case .resonance: 0.32
        case .timerExpired: 0.30
        case .warn: 0.34
        case .spawn: 0.58
        case .dash: 0.20
        case .laserCharge: 0.58
        case .laserFire: 0.34
        case .asteroidImpact: 0.22
        case .asteroidShatter: 0.46
        case .riftOpen: 0.70
        case .riftEnter: 0.56
        case .exitOpen: 0.72
        case .shieldBreak: 0.38
        case .timeCollision: 0.44
        case .abilityPickup: 0.30
        case .shield: 0.46
        case .freeze: 0.58
        case .surge: 0.44
        case .pulse: 0.48
        case .magnet: 0.50
        case .phase: 0.52
        case .chrono: 0.62
        case .anchor: 0.62
        case .repulse: 0.58
        case .prism: 0.62
        case .blink: 0.36
        case .rewind: 0.62
        case .death: 0.58
        case .win: 0.86
        }
    }

    var volume: Float {
        switch self {
        case .tap, .select: 0.34
        case .collect, .resonance: 0.46
        case .warn, .laserCharge: 0.42
        case .asteroidImpact: 0.48
        case .laserFire, .asteroidShatter, .repulse, .death: 0.58
        case .win: 0.54
        default: 0.50
        }
    }

    var hasVariants: Bool {
        switch self {
        case .tap, .select, .collect, .resonance, .asteroidImpact, .asteroidShatter:
            true
        default:
            false
        }
    }

    var minimumInterval: TimeInterval {
        switch self {
        case .tap, .select, .collect: 0.025
        case .asteroidImpact, .asteroidShatter: 0.055
        case .laserCharge, .warn: 0.09
        default: 0.015
        }
    }

    var clearsMix: Bool {
        self == .death || self == .win
    }
}

@MainActor
final class SoundPlayer {
    var enabled = true
    private(set) var masterVolume: Float = 0.82

    private let engine = AVAudioEngine()
    private var voices: [AVAudioPlayerNode] = []
    private var buffers: [EchoSound: [AVAudioPCMBuffer]] = [:]
    private var playCounts: [EchoSound: Int] = [:]
    private var lastPlayedAt: [EchoSound: TimeInterval] = [:]
    private var nextVoice = 0
    private var hapticsEnabled = true
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let rigidHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let softHaptic = UIImpactFeedbackGenerator(style: .soft)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        for _ in 0..<12 {
            let voice = AVAudioPlayerNode()
            engine.attach(voice)
            engine.connect(voice, to: engine.mainMixerNode, format: format)
            voices.append(voice)
        }

        for sound in EchoSound.allCases {
            let pitches = sound.hasVariants ? [0.965, 1.0, 1.04] : [1.0]
            buffers[sound] = pitches.compactMap { synthesize(sound, pitch: $0, format: format) }
        }

        engine.prepare()
        try? engine.start()
        prepareHaptics()
    }

    func setHapticsEnabled(_ on: Bool) {
        hapticsEnabled = on
        if on { prepareHaptics() }
    }

    func setMasterVolume(_ value: Double) {
        masterVolume = Float(min(1, max(0, value)))
    }

    func play(_ sound: EchoSound, volume: Float = 1, pan: Float = 0) {
        guard enabled, let options = buffers[sound], !options.isEmpty, !voices.isEmpty else { return }
        if !engine.isRunning { try? engine.start() }

        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPlayedAt[sound, default: -.infinity] >= sound.minimumInterval else { return }
        lastPlayedAt[sound] = now
        if sound.clearsMix { voices.forEach { $0.stop() } }

        let count = playCounts[sound, default: 0]
        playCounts[sound] = count + 1
        let buffer = options[count % options.count]
        let voice = voices[nextVoice % voices.count]
        nextVoice = (nextVoice + 1) % voices.count
        voice.stop()
        voice.volume = min(1, max(0, sound.volume * volume * masterVolume))
        voice.pan = min(0.82, max(-0.82, pan))
        voice.scheduleBuffer(buffer, at: nil)
        voice.play()
    }

    func playAbility(_ kind: BonusKind) {
        switch kind {
        case .shield: play(.shield)
        case .ward: play(.abilityPickup)
        case .freeze: play(.freeze)
        case .surge: play(.surge)
        case .pulse: play(.pulse)
        case .magnet: play(.magnet)
        case .phase: play(.phase)
        case .chrono: play(.chrono)
        case .anchor: play(.anchor)
        case .repulse: play(.repulse)
        case .prism: play(.prism)
        case .blink: play(.blink)
        }
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        switch style {
        case .light: lightHaptic.impactOccurred()
        case .medium: mediumHaptic.impactOccurred()
        case .heavy, .rigid: rigidHaptic.impactOccurred()
        case .soft: softHaptic.impactOccurred()
        @unknown default: mediumHaptic.impactOccurred()
        }
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        notificationHaptic.notificationOccurred(type)
    }

    private func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        rigidHaptic.prepare()
        softHaptic.prepare()
        notificationHaptic.prepare()
    }

    private func synthesize(_ sound: EchoSound, pitch: Double, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sound.duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let value = sample(sound, t: t, duration: sound.duration, pitch: pitch, frame: frame)
            channel[frame] = Float(tanh(value * 1.28) * 0.82)
        }
        return buffer
    }

    private func sample(
        _ sound: EchoSound,
        t: Double,
        duration: TimeInterval,
        pitch: Double,
        frame: Int
    ) -> Double {
        let tau = Double.pi * 2
        let attack = min(1, t / 0.006)
        let release = pow(max(0, 1 - t / duration), 1.7)
        let envelope = attack * release

        func osc(_ frequency: Double, phase: Double = 0) -> Double {
            sin(tau * frequency * pitch * t + phase)
        }
        func sweep(_ start: Double, _ end: Double) -> Double {
            let rate = (end - start) / duration
            return sin(tau * pitch * (start * t + rate * t * t / 2))
        }
        func hit(_ start: Double, frequency: Double, decay: Double) -> Double {
            guard t >= start else { return 0 }
            let local = t - start
            return sin(tau * frequency * pitch * local) * exp(-local * decay)
        }
        func chirp(_ start: Double, _ length: Double, _ low: Double, _ high: Double, _ decay: Double) -> Double {
            guard t >= start, t <= start + length else { return 0 }
            let local = t - start
            let rate = (high - low) / length
            return sin(tau * pitch * (low * local + rate * local * local / 2)) * exp(-local * decay)
        }
        let noise = deterministicNoise(frame: frame)

        let raw: Double = switch sound {
        case .tap:
            (0.30 * sweep(980, 1_320) + 0.08 * osc(1_960)) * exp(-t * 38)
        case .select:
            (0.24 * sweep(520, 920) + 0.08 * osc(1_380)) * exp(-t * 21)
        case .confirm:
            0.28 * hit(0, frequency: 523, decay: 13)
                + 0.25 * hit(0.065, frequency: 659, decay: 13)
                + 0.23 * hit(0.13, frequency: 988, decay: 10)
        case .denied:
            (0.24 * sweep(270, 125) + 0.12 * osc(91)) * (0.72 + 0.28 * sin(tau * 18 * t))
        case .collect:
            0.28 * hit(0, frequency: 880, decay: 23)
                + 0.24 * hit(0.045, frequency: 1_320, decay: 20)
        case .crystal:
            0.22 * hit(0, frequency: 1_120, decay: 8)
                + 0.19 * hit(0.075, frequency: 1_680, decay: 8)
                + 0.17 * hit(0.15, frequency: 2_240, decay: 7)
        case .resonance:
            0.22 * hit(0, frequency: 660, decay: 12)
                + 0.24 * hit(0.055, frequency: 990, decay: 10)
                + 0.18 * hit(0.11, frequency: 1_320, decay: 8)
        case .timerExpired:
            0.25 * chirp(0, 0.15, 760, 370, 5)
                + 0.19 * chirp(0.12, 0.16, 490, 180, 6)
        case .warn:
            0.22 * hit(0, frequency: 260, decay: 9)
                + 0.23 * hit(0.14, frequency: 260, decay: 9)
                + 0.08 * osc(520)
        case .spawn:
            (0.19 * sweep(90, 1_080) + 0.10 * osc(180) + 0.06 * noise) * sin(.pi * t / duration)
        case .dash:
            (0.24 * sweep(180, 1_900) + 0.07 * noise) * exp(-t * 8)
        case .laserCharge:
            (0.18 * sweep(150, 1_260) + 0.08 * osc(74)) * (0.55 + 0.45 * sin(tau * 13 * t))
        case .laserFire:
            (0.30 * sweep(2_600, 240) + 0.15 * osc(92) + 0.08 * noise) * exp(-t * 7)
        case .asteroidImpact:
            (0.34 * sweep(135, 48) + 0.17 * osc(72) + 0.10 * noise) * exp(-t * 18)
        case .asteroidShatter:
            (0.16 * osc(740) + 0.14 * osc(1_017) + 0.12 * osc(1_433) + 0.20 * noise) * exp(-t * 8)
        case .riftOpen:
            (0.17 * sweep(85, 920) + 0.10 * sweep(170, 1_520) + 0.05 * noise) * sin(.pi * t / duration)
        case .riftEnter:
            (0.19 * sweep(1_150, 130) + 0.14 * sweep(180, 980) + 0.05 * noise) * sin(.pi * t / duration)
        case .exitOpen:
            0.20 * hit(0, frequency: 392, decay: 5)
                + 0.20 * hit(0.10, frequency: 523, decay: 5)
                + 0.20 * hit(0.20, frequency: 784, decay: 4)
                + 0.12 * hit(0.32, frequency: 1_047, decay: 3)
        case .shieldBreak:
            (0.18 * osc(1_180) + 0.15 * osc(1_657) + 0.13 * osc(2_113) + 0.12 * noise) * exp(-t * 9)
        case .timeCollision:
            (0.18 * osc(232) + 0.18 * osc(247) + 0.13 * sweep(1_200, 95) + 0.08 * noise) * exp(-t * 6)
        case .abilityPickup:
            0.22 * chirp(0, 0.16, 520, 1_040, 4)
                + 0.19 * chirp(0.09, 0.18, 780, 1_560, 5)
        case .shield:
            (0.20 * sweep(240, 680) + 0.13 * osc(920) + 0.09 * osc(1_380)) * (0.7 + 0.3 * sin(tau * 5 * t))
        case .freeze:
            (0.15 * sweep(2_500, 1_100) + 0.13 * osc(1_420) + 0.10 * osc(2_130)) * (0.62 + 0.38 * sin(tau * 7 * t))
        case .surge:
            (0.20 * sweep(120, 1_850) + 0.11 * osc(180) + 0.08 * noise) * exp(-t * 4.5)
        case .pulse:
            (0.30 * sweep(170, 54) + 0.13 * sweep(620, 120)) * sin(.pi * min(1, t / 0.32)) * exp(-t * 3)
        case .magnet:
            (0.18 * sweep(95, 260) + 0.14 * osc(190) + 0.08 * osc(380)) * (0.56 + 0.44 * sin(tau * 14 * t))
        case .phase:
            (0.17 * osc(410) + 0.16 * osc(466) + 0.10 * sweep(900, 1_500)) * (0.52 + 0.48 * sin(tau * 11 * t))
        case .chrono:
            0.18 * hit(0, frequency: 920, decay: 18)
                + 0.18 * hit(0.12, frequency: 920, decay: 18)
                + 0.18 * hit(0.24, frequency: 920, decay: 18)
                + 0.20 * hit(0.33, frequency: 1_380, decay: 5)
        case .anchor:
            (0.25 * sweep(210, 58) + 0.14 * osc(105)) * (0.75 + 0.25 * sin(tau * 4 * t))
        case .repulse:
            (0.32 * sweep(160, 42) + 0.16 * sweep(1_100, 180) + 0.12 * noise) * exp(-t * 5)
        case .prism:
            0.17 * hit(0, frequency: 932, decay: 6)
                + 0.16 * hit(0.07, frequency: 1_398, decay: 6)
                + 0.15 * hit(0.14, frequency: 1_864, decay: 5)
                + 0.10 * osc(2_330)
        case .blink:
            0.23 * chirp(0, 0.17, 1_440, 220, 5)
                + 0.27 * chirp(0.17, 0.13, 680, 1_900, 9)
        case .rewind:
            (0.18 * sweep(1_450, 110) + 0.12 * sweep(900, 1_800)) * (0.55 + 0.45 * sin(tau * 9 * t))
        case .death:
            (0.27 * sweep(520, 48) + 0.15 * osc(79) + 0.06 * noise) * exp(-t * 3.8)
        case .win:
            0.20 * hit(0, frequency: 523, decay: 4)
                + 0.19 * hit(0.11, frequency: 659, decay: 4)
                + 0.19 * hit(0.22, frequency: 784, decay: 3.5)
                + 0.17 * hit(0.36, frequency: 1_047, decay: 2.8)
                + 0.09 * hit(0.36, frequency: 1_568, decay: 2.5)
        }

        return raw * envelope
    }

    private func deterministicNoise(frame: Int) -> Double {
        var value = UInt32(truncatingIfNeeded: frame &* 1_664_525 &+ 1_013_904_223)
        value ^= value << 13
        value ^= value >> 17
        value ^= value << 5
        return Double(Int32(bitPattern: value)) / Double(Int32.max)
    }
}
