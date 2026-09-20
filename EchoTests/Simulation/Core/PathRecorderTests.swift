import XCTest
@testable import Echo

final class PathRecorderTests: XCTestCase {
    func testInterpolatesBetweenSamples() {
        var recorder = PathRecorder()
        recorder.record(time: 0, position: Vec2(x: 0, y: 0))
        recorder.record(time: 1, position: Vec2(x: 10, y: 0))
        let mid = recorder.position(at: 0.5)
        XCTAssertEqual(mid?.x ?? -1, 5, accuracy: 0.001)
        XCTAssertEqual(mid?.y ?? -1, 0, accuracy: 0.001)
    }

    func testClampsOutsideRange() {
        var recorder = PathRecorder()
        recorder.record(time: 1, position: Vec2(x: 4, y: 4))
        recorder.record(time: 2, position: Vec2(x: 8, y: 4))
        XCTAssertEqual(recorder.position(at: 0)?.x, 4)
        XCTAssertEqual(recorder.position(at: 9)?.x, 8)
    }

    func testPolylineAndTruncate() {
        var recorder = PathRecorder()
        recorder.record(time: 0, position: Vec2(x: 0, y: 0))
        recorder.record(time: 1, position: Vec2(x: 10, y: 0))
        XCTAssertTrue(recorder.polyline(from: 0, duration: 0).isEmpty)
        XCTAssertTrue(recorder.polyline(from: 0, duration: 1, stride: 0).isEmpty)
        XCTAssertFalse(recorder.polyline(from: 0, duration: 1, stride: 0.25).isEmpty)
        recorder.record(time: 0.5, position: Vec2(x: 1, y: 1))
        recorder.truncate(after: 1)
        XCTAssertEqual(recorder.position(at: 2)?.x, 10)
        _ = recorder.slice(from: 0, to: 1)
    }
}
