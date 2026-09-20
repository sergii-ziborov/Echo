import UIKit
import XCTest
@testable import Echo

@MainActor
final class AudioCoverageTests: XCTestCase {
    func testCatalogAndPlayback() {
        SoundPlayer.testSilent = false
        let player = SoundPlayer()
        player.enabled = true
        player.setMasterVolume(0.5)
        player.setHapticsEnabled(true)
        for sound in EchoSound.allCases {
            _ = sound.duration
            _ = sound.volume
            _ = sound.hasVariants
            _ = sound.minimumInterval
            _ = sound.clearsMix
            player.play(sound, volume: 0.4, pan: 0.2)
            player.play(sound, volume: 0.4, pan: -0.2)
        }
        for kind in BonusKind.allCases {
            player.playAbility(kind)
        }
        player.haptic(.light)
        player.haptic(.medium)
        player.haptic(.heavy)
        player.haptic(.rigid)
        player.haptic(.soft)
        player.notify(.success)
        player.notify(.error)
        player.notify(.warning)
        player.enabled = false
        player.play(.tap)
        player.setHapticsEnabled(false)
        player.haptic(.light)
        player.notify(.success)
        XCTAssertFalse(EchoSound.allCases.isEmpty)
    }
}
