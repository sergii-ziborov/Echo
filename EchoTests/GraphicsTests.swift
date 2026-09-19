import CoreGraphics
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
