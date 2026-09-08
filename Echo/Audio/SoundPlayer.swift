import AVFoundation
import UIKit

enum EchoSound: String, CaseIterable {
    case tap
    case collect
    case warn
    case spawn
    case death
    case win
}

@MainActor
final class SoundPlayer {
    var enabled = true
    private var players: [EchoSound: AVAudioPlayer] = [:]
    private var hapticsEnabled = true

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        for sound in EchoSound.allCases {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
               let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players[sound] = player
            }
        }
    }

    func setHapticsEnabled(_ on: Bool) {
        hapticsEnabled = on
    }

    func play(_ sound: EchoSound) {
        guard enabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }

    func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
