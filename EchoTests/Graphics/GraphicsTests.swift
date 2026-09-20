import CoreGraphics
import SpriteKit
import XCTest
@testable import Echo

@MainActor
final class GraphicsTests: XCTestCase {
    func testGlowMaskIsBrightInTheCenterAndClearAtTheEdge() {
        let image = GlowTextures.glowMask.cgImage()
        let width = image.width
        let height = image.height
        XCTAssertGreaterThan(width, 16)
        let center = alpha(of: image, x: width / 2, y: height / 2)
        let edge = alpha(of: image, x: 1, y: 1)
        XCTAssertGreaterThan(center, 0.4)
        XCTAssertLessThan(edge, 0.02)
    }

    func testRibbonNeedsRealMotion() {
        let parked = [
            VisualTrailPoint(position: .zero, time: 0.10),
            VisualTrailPoint(position: .zero, time: 0.20),
        ]
        XCTAssertTrue(
            TrailRenderer.ribbon(samples: parked, now: 0.25, lifetime: 0.85, headWidth: 10).isEmpty
        )

        let moving = [
            VisualTrailPoint(position: .zero, time: 0.10),
            VisualTrailPoint(position: CGPoint(x: 18, y: 0), time: 0.20),
            VisualTrailPoint(position: CGPoint(x: 36, y: 3), time: 0.30),
        ]
        XCTAssertFalse(
            TrailRenderer.ribbon(samples: moving, now: 0.35, lifetime: 0.85, headWidth: 10).isEmpty
        )
    }

    func testRibbonDoesNotBridgeATeleport() {
        let samples = [
            VisualTrailPoint(position: .zero, time: 0.10),
            VisualTrailPoint(position: CGPoint(x: 12, y: 0), time: 0.16),
            VisualTrailPoint(position: CGPoint(x: 220, y: 180), time: 0.22, breakBefore: true),
            VisualTrailPoint(position: CGPoint(x: 232, y: 180), time: 0.28),
        ]
        let path = TrailRenderer.ribbon(samples: samples, now: 0.30, lifetime: 0.85, headWidth: 10)
        var contours = 0
        path.applyWithBlock { element in
            if element.pointee.type == .moveToPoint { contours += 1 }
        }
        XCTAssertEqual(contours, 2, "A teleport must start a second ribbon, not one long strip")
    }

    func testEveryBonusPlateIsItsOwnTexture() {
        for left in BonusKind.allCases {
            for right in BonusKind.allCases where left != right {
                XCTAssertFalse(
                    GlowTextures.bonus(left) === GlowTextures.bonus(right),
                    "\(left) and \(right) share a plate"
                )
            }
        }
    }

    func testPlayableCatalogStillHasSeventySevenMaps() {
        XCTAssertEqual(LevelCatalog.playable.count, 77)
    }

    func testShortJumpStaysConnectedWithoutAnEvent() {
        let samples = [
            VisualTrailPoint(position: .zero, time: 0.10),
            VisualTrailPoint(position: CGPoint(x: 20, y: 0), time: 0.16),
            VisualTrailPoint(position: CGPoint(x: 91.25, y: 0), time: 0.22),
            VisualTrailPoint(position: CGPoint(x: 104, y: 0), time: 0.28),
        ]
        XCTAssertEqual(contourCount(TrailRenderer.ribbon(samples: samples, now: 0.30, lifetime: 0.85, headWidth: 10)), 1)
    }

    func testShortBlinkBreaksWhenTeleportIsSignaled() {
        let samples = [
            VisualTrailPoint(position: .zero, time: 0.10),
            VisualTrailPoint(position: CGPoint(x: 20, y: 0), time: 0.16),
            VisualTrailPoint(position: CGPoint(x: 91.25, y: 0), time: 0.22, breakBefore: true),
            VisualTrailPoint(position: CGPoint(x: 104, y: 0), time: 0.28),
        ]
        XCTAssertEqual(contourCount(TrailRenderer.ribbon(samples: samples, now: 0.30, lifetime: 0.85, headWidth: 10)), 2)
    }

    func testTrailRecordsDisplacementEvenWhenMarkedStationary() {
        let parent = SKNode()
        parent.zPosition = VisualLayer.trails
        let trails = TrailRenderer(parent: parent)
        trails.sample(id: "player", position: .zero, time: 0, color: .white, headWidth: 10, moving: false)
        trails.sample(id: "player", position: CGPoint(x: 16, y: 0), time: 0.12, color: .white, headWidth: 10, moving: false)
        XCTAssertFalse(trails.ribbonPath(id: "player")?.isEmpty ?? true)
    }

    func testTrailRibbonLayersStayLocalAndUnderHazards() {
        let parent = SKNode()
        parent.zPosition = VisualLayer.trails
        let trails = TrailRenderer(parent: parent)
        trails.sample(id: "player", position: .zero, time: 0, color: .white, headWidth: 10, moving: true)
        trails.sample(id: "player", position: CGPoint(x: 12, y: 0), time: 0.08, color: .white, headWidth: 10, moving: true)
        let layers = trails.layerZPositions(id: "player")
        XCTAssertEqual(layers.count, 3)
        XCTAssertEqual(layers[0], VisualStyle.trailBloomZ, accuracy: 0.0001)
        XCTAssertEqual(layers[1], VisualStyle.trailBandZ, accuracy: 0.0001)
        XCTAssertEqual(layers[2], VisualStyle.trailCoreZ, accuracy: 0.0001)
        XCTAssertLessThan(VisualLayer.trails + VisualStyle.trailCoreZ, VisualLayer.pickups)
        XCTAssertLessThan(VisualLayer.trails + VisualStyle.trailCoreZ, VisualLayer.hazards)
    }

    func testReplayCursorIsFrameRateIndependent() {
        let times = (0...180).map { TimeInterval($0) / 60.0 }
        var elapsed60: TimeInterval = 0
        var index60 = 0
        for _ in 0..<60 {
            elapsed60 += (1.0 / 60.0) * ReplayTiming.rate
            index60 = ReplayTiming.index(times: times, elapsed: elapsed60)
        }
        var elapsed120: TimeInterval = 0
        var index120 = 0
        for _ in 0..<120 {
            elapsed120 += (1.0 / 120.0) * ReplayTiming.rate
            index120 = ReplayTiming.index(times: times, elapsed: elapsed120)
        }
        XCTAssertEqual(index60, index120)
        XCTAssertEqual(index60, ReplayTiming.index(times: times, elapsed: 0.45))
    }

    func testBonusPlatesDifferInPixels() {
        let shield = pixelDigest(GlowTextures.bonus(.shield))
        let blink = pixelDigest(GlowTextures.bonus(.blink))
        XCTAssertNotEqual(shield, blink)
    }

    func testAsteroidHintDescribesCracksInsteadOfARing() {
        let detail = EncounterHint.asteroid.detail.lowercased()
        XCTAssertTrue(detail.contains("crack"))
        XCTAssertFalse(detail.contains("ring"))
    }

    func testCompositeWallsHaveOneExposedBevel() throws {
        let level = try XCTUnwrap(LevelCatalog.playable.first { $0.number == 40 })
        XCTAssertGreaterThan(level.walls.count, 1)
        let session = GameSession(level: level, daily: false)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let scene = GameScene(session: session, size: view.bounds.size)
        view.presentScene(scene)
        XCTAssertEqual(scene.children.filter { $0.name == "wallBevel" }.count, 1)
        XCTAssertNotNil(scene.childNode(withName: "wallMaterial"))
        XCTAssertEqual(scene.children.filter { $0.name == "material" }.count, 0)
    }

    func testSolidAsteroidDiameterMatchesCollisionRadius() throws {
        let level = try XCTUnwrap(LevelCatalog.playable.first { $0.number == 38 })
        let mover = try XCTUnwrap(level.movers.first)
        let session = GameSession(level: level, daily: false)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let scene = GameScene(session: session, size: view.bounds.size)
        view.presentScene(scene)
        let node = try XCTUnwrap(scene.childNode(withName: "asteroid-\(mover.id)"))
        let diameter = (node.userData?["diameter"] as? NSNumber)?.doubleValue ?? -1
        let expected = mover.radius * 2 * (375 / max(level.worldWidth, 1))
        XCTAssertEqual(diameter, expected, accuracy: 0.6)
    }

    private func contourCount(_ path: CGPath) -> Int {
        var contours = 0
        path.applyWithBlock { element in
            if element.pointee.type == .moveToPoint { contours += 1 }
        }
        return contours
    }

    private func pixelDigest(_ texture: SKTexture) -> [UInt8] {
        let image = texture.cgImage()
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixels,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: image.width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return pixels
    }

    private func alpha(of image: CGImage, x: Int, y: Int) -> CGFloat {
        var pixel = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        context?.draw(image, in: CGRect(x: -x, y: -y, width: image.width, height: image.height))
        return CGFloat(pixel[3]) / 255
    }
}
